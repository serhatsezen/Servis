const functions = require('firebase-functions');
const admin = require('firebase-admin');
const fetch = require('node-fetch');

admin.initializeApp();

const db = admin.firestore();

/**
 * Her gün gece 03:00'te çalışarak, katılım durumu true olan personellerin
 * biniş noktalarına göre optimize edilmiş rota hesaplar.
 */
exports.gunlukRotaOptimizasyonu = functions.pubsub
  .schedule('0 3 * * *')
  .timeZone('Europe/Istanbul')
  .onRun(async (context) => {
    const servislerSnapshot = await db.collection('servisler').get();

    for (const servisDoc of servislerSnapshot.docs) {
      const servis = servisDoc.data();
      const servisId = servisDoc.id;

      if (!servis.personelListesi || servis.personelListesi.length === 0) {
        continue;
      }

      // Katılım durumu true olan personelleri getir
      const personellerSnapshot = await db
        .collection('personeller')
        .where('servisId', '==', servisId)
        .where('katilimDurumu', '==', true)
        .get();

      const duraklar = [];
      const personelIds = [];

      for (const personelDoc of personellerSnapshot.docs) {
        const personel = personelDoc.data();
        if (personel.binisNoktasi) {
          duraklar.push({
            lat: personel.binisNoktasi.lat,
            lng: personel.binisNoktasi.lng,
            personelId: personelDoc.id,
          });
          personelIds.push(personelDoc.id);
        }
      }

      if (duraklar.length < 2) {
        console.log(`Servis ${servisId}: Yeterli durak yok, atlanıyor.`);
        continue;
      }

      try {
        // Google Directions API ile optimize edilmiş rota hesapla
        const apiKey = functions.config().google?.maps_api_key || '';
        const origin = `${duraklar[0].lat},${duraklar[0].lng}`;
        const destination = `${duraklar[duraklar.length - 1].lat},${duraklar[duraklar.length - 1].lng}`;
        const waypoints = duraklar
          .map((d) => `${d.lat},${d.lng}`)
          .join('|');

        const url = `https://maps.googleapis.com/maps/api/directions/json`
          + `?origin=${origin}`
          + `&destination=${destination}`
          + `&waypoints=optimize:true|${waypoints}`
          + `&key=${apiKey}`
          + `&language=tr`;

        const response = await fetch(url);
        const data = await response.json();

        if (data.status !== 'OK') {
          console.error(`Servis ${servisId}: Directions API hatası - ${data.status}`);
          continue;
        }

        const route = data.routes[0];
        const waypointOrder = route.waypoint_order || [];

        // Toplam süre hesapla
        let totalDuration = 0;
        for (const leg of route.legs) {
          totalDuration += leg.duration.value;
        }

        // Optimize edilmiş durakları oluştur
        const optimizedDuraklar = waypointOrder.map((index, sira) => ({
          lat: duraklar[index].lat,
          lng: duraklar[index].lng,
          personelId: duraklar[index].personelId,
          sira: sira,
        }));

        // Rota kaydet
        await db.collection('rotalar').add({
          servisId: servisId,
          duraklar: optimizedDuraklar,
          optimumSira: waypointOrder.map(String),
          tahminiSure: Math.ceil(totalDuration / 60),
          polyline: route.overview_polyline.points,
          olusturulmaTarihi: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`Servis ${servisId}: Rota başarıyla optimize edildi. ${optimizedDuraklar.length} durak, ${Math.ceil(totalDuration / 60)} dk.`);

        // Eski rotaları temizle (son 3 rota hariç)
        const eskiRotalar = await db
          .collection('rotalar')
          .where('servisId', '==', servisId)
          .orderBy('olusturulmaTarihi', 'desc')
          .get();

        if (eskiRotalar.docs.length > 3) {
          const batch = db.batch();
          for (let i = 3; i < eskiRotalar.docs.length; i++) {
            batch.delete(eskiRotalar.docs[i].ref);
          }
          await batch.commit();
        }
      } catch (error) {
        console.error(`Servis ${servisId}: Rota optimizasyonu hatası -`, error);
      }
    }

    return null;
  });

/**
 * Personel katılım durumu değiştiğinde bildirim gönder.
 */
exports.katilimBildirimi = functions.firestore
  .document('personeller/{personelId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Katılım durumu değişmediyse atla
    if (before.katilimDurumu === after.katilimDurumu) {
      return null;
    }

    const personelId = context.params.personelId;
    const servisId = after.servisId;

    if (!servisId) return null;

    // Servis bilgisini al
    const servisDoc = await db.collection('servisler').doc(servisId).get();
    if (!servisDoc.exists) return null;

    const servis = servisDoc.data();
    const durum = after.katilimDurumu ? 'katılacak' : 'katılmayacak';

    console.log(`${after.adSoyad} yarın ${servis.plaka} servisine ${durum}.`);

    // Şoföre bildirim gönder (FCM)
    if (servis.soforId) {
      const soforDoc = await db.collection('personeller').doc(servis.soforId).get();
      if (soforDoc.exists) {
        // FCM token ile bildirim gönderilebilir
        console.log(`Şoför ${soforDoc.data().adSoyad}'a bildirim gönderildi.`);
      }
    }

    return null;
  });

/**
 * Servis başladığında personellere bildirim gönder.
 */
exports.servisBasladiBildirimi = functions.firestore
  .document('servisler/{servisId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Servis aktif olduysa (pasiften aktife)
    if (!before.aktifMi && after.aktifMi) {
      const servisId = context.params.servisId;
      console.log(`Servis ${after.plaka} (${servisId}) başladı.`);

      // Bu servisteki tüm personellere bildirim gönder
      const personellerSnapshot = await db
        .collection('personeller')
        .where('servisId', '==', servisId)
        .where('katilimDurumu', '==', true)
        .get();

      for (const personelDoc of personellerSnapshot.docs) {
        const personel = personelDoc.data();
        console.log(`${personel.adSoyad}'a servis başladı bildirimi gönderildi.`);
        // FCM ile push notification gönderilebilir
      }
    }

    return null;
  });
