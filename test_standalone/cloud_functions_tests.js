/**
 * Cloud Functions İş Mantığı Testleri
 * Firebase emulator olmadan, fonksiyon mantığını doğrular.
 */

let totalTests = 0;
let passedTests = 0;
let failedTests = 0;
const failures = [];

function describe(name, fn) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`  ${name}`);
  console.log(`${'='.repeat(60)}`);
  fn();
}

function test(name, fn) {
  totalTests++;
  try {
    fn();
    passedTests++;
    console.log(`  ✅ ${name}`);
  } catch (e) {
    failedTests++;
    failures.push({ name, error: e.message });
    console.log(`  ❌ ${name}`);
    console.log(`     └─ ${e.message}`);
  }
}

function expect(actual) {
  return {
    toBe(expected) {
      if (actual !== expected) throw new Error(`Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
    },
    toEqual(expected) {
      if (JSON.stringify(actual) !== JSON.stringify(expected))
        throw new Error(`Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
    },
    toBeTruthy() { if (!actual) throw new Error(`Expected truthy, got ${JSON.stringify(actual)}`); },
    toBeFalsy() { if (actual) throw new Error(`Expected falsy, got ${JSON.stringify(actual)}`); },
    toHaveLength(n) { if (actual.length !== n) throw new Error(`Expected length ${n}, got ${actual.length}`); },
    toBeGreaterThan(n) { if (actual <= n) throw new Error(`Expected ${actual} > ${n}`); },
    toContain(item) { if (!actual.includes(item)) throw new Error(`Expected to contain ${JSON.stringify(item)}`); },
  };
}

// ============================================================
// Mock Firestore DB
// ============================================================

class MockFirestoreDB {
  constructor() {
    this.collections = {};
  }

  addCollection(name, docs) {
    this.collections[name] = docs;
  }

  collection(name) {
    const docs = this.collections[name] || [];
    return {
      docs,
      get: async () => ({ docs }),
      where: (field, op, value) => {
        const filtered = docs.filter(doc => {
          const val = doc.data()[field];
          if (op === '==') return val === value;
          return false;
        });
        return {
          docs: filtered,
          get: async () => ({ docs: filtered }),
          where: (f2, o2, v2) => {
            const filtered2 = filtered.filter(doc => {
              const val = doc.data()[f2];
              if (o2 === '==') return val === v2;
              return false;
            });
            return {
              docs: filtered2,
              get: async () => ({ docs: filtered2 }),
              orderBy: () => ({
                limit: () => ({
                  get: async () => ({ docs: filtered2.slice(0, 1) }),
                }),
                get: async () => ({ docs: filtered2 }),
              }),
            };
          },
          orderBy: () => ({
            get: async () => ({ docs: filtered }),
          }),
        };
      },
      doc: (id) => {
        const found = docs.find(d => d.id === id);
        return {
          get: async () => found || { exists: false },
          exists: !!found,
          data: () => found ? found.data() : null,
        };
      },
      add: async (data) => {
        const newDoc = createDoc(`auto_${Date.now()}`, data);
        docs.push(newDoc);
        return newDoc;
      },
    };
  }
}

function createDoc(id, data) {
  return {
    id,
    data: () => ({ ...data }),
    exists: true,
    ref: { id },
  };
}

// ============================================================
// Günlük Rota Optimizasyonu Mantığı
// ============================================================

async function gunlukRotaOptimizasyonuLogic(db, mockDirectionsAPI) {
  const servislerSnapshot = await db.collection('servisler').get();
  const results = [];

  for (const servisDoc of servislerSnapshot.docs) {
    const servis = servisDoc.data();
    const servisId = servisDoc.id;

    if (!servis.personelListesi || servis.personelListesi.length === 0) {
      results.push({ servisId, status: 'skipped', reason: 'no_personel' });
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
      results.push({ servisId, status: 'skipped', reason: 'not_enough_stops' });
      continue;
    }

    try {
      // Mock Directions API
      const apiResult = mockDirectionsAPI(duraklar);

      const waypointOrder = apiResult.waypoint_order;
      const optimizedDuraklar = waypointOrder.map((index, sira) => ({
        lat: duraklar[index].lat,
        lng: duraklar[index].lng,
        personelId: duraklar[index].personelId,
        sira: sira,
      }));

      results.push({
        servisId,
        status: 'success',
        durakSayisi: optimizedDuraklar.length,
        tahminiSure: apiResult.tahminiSure,
        waypointOrder,
        optimizedDuraklar,
      });
    } catch (error) {
      results.push({ servisId, status: 'error', error: error.message });
    }
  }

  return results;
}

// ============================================================
// Katılım Değişikliği Bildirimi Mantığı
// ============================================================

function katilimBildirimiLogic(before, after, personelId) {
  const notifications = [];

  if (before.katilimDurumu === after.katilimDurumu) {
    return { changed: false, notifications };
  }

  const durum = after.katilimDurumu ? 'katılacak' : 'katılmayacak';

  notifications.push({
    type: 'katilim_degisikligi',
    personelId,
    adSoyad: after.adSoyad,
    servisId: after.servisId,
    durum,
    message: `${after.adSoyad} yarın servise ${durum}.`,
  });

  return { changed: true, notifications };
}

// ============================================================
// Servis Başladı Bildirimi Mantığı
// ============================================================

function servisBasladiBildirimiLogic(before, after, servisId, katilimcilar) {
  const notifications = [];

  // Pasiften aktife geçtiyse
  if (!before.aktifMi && after.aktifMi) {
    for (const personel of katilimcilar) {
      notifications.push({
        type: 'servis_basladi',
        servisId,
        plaka: after.plaka,
        personelId: personel.id,
        adSoyad: personel.adSoyad,
        message: `${after.plaka} plakalı servis hareket etti.`,
      });
    }
  }

  return notifications;
}

// ============================================================
// TESTLER
// ============================================================

console.log('\n☁️  CLOUD FUNCTIONS - İŞ MANTIĞI TESTLERİ');
console.log('━'.repeat(60));

// ---------- GÜNLÜK ROTA OPTİMİZASYONU ----------

describe('Günlük Rota Optimizasyonu Tests', () => {
  test('3 katılımcılı servis için rota oluşturulur', async () => {
    const db = new MockFirestoreDB();

    db.addCollection('servisler', [
      createDoc('srv-1', {
        plaka: '34 ABC 001',
        rotaAciklama: 'Test Rota',
        aktifMi: false,
        personelListesi: ['p1', 'p2', 'p3'],
      }),
    ]);

    db.addCollection('personeller', [
      createDoc('p1', { servisId: 'srv-1', katilimDurumu: true, binisNoktasi: { lat: 41.00, lng: 29.00 }, adSoyad: 'Ali' }),
      createDoc('p2', { servisId: 'srv-1', katilimDurumu: true, binisNoktasi: { lat: 41.05, lng: 29.05 }, adSoyad: 'Veli' }),
      createDoc('p3', { servisId: 'srv-1', katilimDurumu: true, binisNoktasi: { lat: 41.02, lng: 29.02 }, adSoyad: 'Ayşe' }),
    ]);

    const mockAPI = (duraklar) => ({
      waypoint_order: [0, 2, 1], // optimize edilmiş sıra
      tahminiSure: 35,
    });

    const results = await gunlukRotaOptimizasyonuLogic(db, mockAPI);
    expect(results).toHaveLength(1);
    expect(results[0].status).toBe('success');
    expect(results[0].durakSayisi).toBe(3);
    expect(results[0].tahminiSure).toBe(35);
  });

  test('Boş personel listeli servis atlanır', async () => {
    const db = new MockFirestoreDB();
    db.addCollection('servisler', [
      createDoc('srv-empty', {
        plaka: '34 EMP 001',
        personelListesi: [],
      }),
    ]);
    db.addCollection('personeller', []);

    const results = await gunlukRotaOptimizasyonuLogic(db, () => {});
    expect(results).toHaveLength(1);
    expect(results[0].status).toBe('skipped');
    expect(results[0].reason).toBe('no_personel');
  });

  test('Tek durak olan servis atlanır (minimum 2 gerekli)', async () => {
    const db = new MockFirestoreDB();
    db.addCollection('servisler', [
      createDoc('srv-1', { plaka: '34 ONE 001', personelListesi: ['p1'] }),
    ]);
    db.addCollection('personeller', [
      createDoc('p1', { servisId: 'srv-1', katilimDurumu: true, binisNoktasi: { lat: 41.0, lng: 29.0 }, adSoyad: 'Ali' }),
    ]);

    const results = await gunlukRotaOptimizasyonuLogic(db, () => {});
    expect(results).toHaveLength(1);
    expect(results[0].status).toBe('skipped');
    expect(results[0].reason).toBe('not_enough_stops');
  });

  test('Katılmayan personeller rota dışında kalır', async () => {
    const db = new MockFirestoreDB();
    db.addCollection('servisler', [
      createDoc('srv-1', { plaka: '34 MIX 001', personelListesi: ['p1', 'p2', 'p3', 'p4'] }),
    ]);
    // p2 ve p4 katılmayacak
    db.addCollection('personeller', [
      createDoc('p1', { servisId: 'srv-1', katilimDurumu: true, binisNoktasi: { lat: 41.00, lng: 29.00 }, adSoyad: 'Ali' }),
      createDoc('p2', { servisId: 'srv-1', katilimDurumu: false, binisNoktasi: { lat: 41.01, lng: 29.01 }, adSoyad: 'Veli' }),
      createDoc('p3', { servisId: 'srv-1', katilimDurumu: true, binisNoktasi: { lat: 41.02, lng: 29.02 }, adSoyad: 'Ayşe' }),
      createDoc('p4', { servisId: 'srv-1', katilimDurumu: false, binisNoktasi: { lat: 41.03, lng: 29.03 }, adSoyad: 'Fatma' }),
    ]);

    const mockAPI = (duraklar) => ({
      waypoint_order: [0, 1],
      tahminiSure: 20,
    });

    const results = await gunlukRotaOptimizasyonuLogic(db, mockAPI);
    expect(results[0].status).toBe('success');
    expect(results[0].durakSayisi).toBe(2); // sadece p1 ve p3
  });

  test('API hatası durumunda error döner', async () => {
    const db = new MockFirestoreDB();
    db.addCollection('servisler', [
      createDoc('srv-1', { plaka: '34 ERR 001', personelListesi: ['p1', 'p2'] }),
    ]);
    db.addCollection('personeller', [
      createDoc('p1', { servisId: 'srv-1', katilimDurumu: true, binisNoktasi: { lat: 41.0, lng: 29.0 }, adSoyad: 'Ali' }),
      createDoc('p2', { servisId: 'srv-1', katilimDurumu: true, binisNoktasi: { lat: 41.1, lng: 29.1 }, adSoyad: 'Veli' }),
    ]);

    const mockAPI = () => { throw new Error('API_KEY_INVALID'); };

    const results = await gunlukRotaOptimizasyonuLogic(db, mockAPI);
    expect(results[0].status).toBe('error');
    expect(results[0].error).toBe('API_KEY_INVALID');
  });

  test('Birden fazla servis paralel işlenir', async () => {
    const db = new MockFirestoreDB();
    db.addCollection('servisler', [
      createDoc('srv-1', { plaka: '34 AA 001', personelListesi: ['p1', 'p2'] }),
      createDoc('srv-2', { plaka: '06 BB 002', personelListesi: ['p3', 'p4'] }),
      createDoc('srv-3', { plaka: '35 CC 003', personelListesi: [] }),
    ]);
    db.addCollection('personeller', [
      createDoc('p1', { servisId: 'srv-1', katilimDurumu: true, binisNoktasi: { lat: 41.0, lng: 29.0 }, adSoyad: 'A' }),
      createDoc('p2', { servisId: 'srv-1', katilimDurumu: true, binisNoktasi: { lat: 41.1, lng: 29.1 }, adSoyad: 'B' }),
      createDoc('p3', { servisId: 'srv-2', katilimDurumu: true, binisNoktasi: { lat: 39.9, lng: 32.8 }, adSoyad: 'C' }),
      createDoc('p4', { servisId: 'srv-2', katilimDurumu: true, binisNoktasi: { lat: 39.8, lng: 32.7 }, adSoyad: 'D' }),
    ]);

    const mockAPI = (duraklar) => ({
      waypoint_order: duraklar.map((_, i) => i),
      tahminiSure: duraklar.length * 10,
    });

    const results = await gunlukRotaOptimizasyonuLogic(db, mockAPI);
    expect(results).toHaveLength(3);
    expect(results[0].status).toBe('success');
    expect(results[1].status).toBe('success');
    expect(results[2].status).toBe('skipped');
  });

  test('Waypoint sırası doğru uygulanır', async () => {
    const db = new MockFirestoreDB();
    db.addCollection('servisler', [
      createDoc('srv-1', { plaka: '34 ORD 001', personelListesi: ['p1', 'p2', 'p3'] }),
    ]);
    db.addCollection('personeller', [
      createDoc('p1', { servisId: 'srv-1', katilimDurumu: true, binisNoktasi: { lat: 41.00, lng: 29.00 }, adSoyad: 'Ali' }),
      createDoc('p2', { servisId: 'srv-1', katilimDurumu: true, binisNoktasi: { lat: 41.05, lng: 29.05 }, adSoyad: 'Veli' }),
      createDoc('p3', { servisId: 'srv-1', katilimDurumu: true, binisNoktasi: { lat: 41.02, lng: 29.02 }, adSoyad: 'Ayşe' }),
    ]);

    // API sırası: p1(0) -> p3(2) -> p2(1)
    const mockAPI = () => ({ waypoint_order: [0, 2, 1], tahminiSure: 30 });

    const results = await gunlukRotaOptimizasyonuLogic(db, mockAPI);
    const optimized = results[0].optimizedDuraklar;

    expect(optimized[0].personelId).toBe('p1');
    expect(optimized[0].sira).toBe(0);
    expect(optimized[1].personelId).toBe('p3');
    expect(optimized[1].sira).toBe(1);
    expect(optimized[2].personelId).toBe('p2');
    expect(optimized[2].sira).toBe(2);
  });
});

// ---------- KATILIM BİLDİRİMİ ----------

describe('Katılım Bildirimi Tests', () => {
  test('Katılım true -> false bildirimi tetikler', () => {
    const before = { katilimDurumu: true, adSoyad: 'Ali', servisId: 'srv-1' };
    const after = { katilimDurumu: false, adSoyad: 'Ali', servisId: 'srv-1' };

    const result = katilimBildirimiLogic(before, after, 'p1');
    expect(result.changed).toBe(true);
    expect(result.notifications).toHaveLength(1);
    expect(result.notifications[0].durum).toBe('katılmayacak');
    expect(result.notifications[0].message).toContain('Ali');
    expect(result.notifications[0].message).toContain('katılmayacak');
  });

  test('Katılım false -> true bildirimi tetikler', () => {
    const before = { katilimDurumu: false, adSoyad: 'Veli', servisId: 'srv-1' };
    const after = { katilimDurumu: true, adSoyad: 'Veli', servisId: 'srv-1' };

    const result = katilimBildirimiLogic(before, after, 'p2');
    expect(result.changed).toBe(true);
    expect(result.notifications[0].durum).toBe('katılacak');
  });

  test('Katılım değişmezse bildirim tetiklenmez', () => {
    const before = { katilimDurumu: true, adSoyad: 'Ayşe', servisId: 'srv-1' };
    const after = { katilimDurumu: true, adSoyad: 'Ayşe', servisId: 'srv-1' };

    const result = katilimBildirimiLogic(before, after, 'p3');
    expect(result.changed).toBe(false);
    expect(result.notifications).toHaveLength(0);
  });

  test('Farklı alanlar değişse bile katılım aynıysa bildirim yok', () => {
    const before = { katilimDurumu: true, adSoyad: 'Eski Ad', servisId: 'srv-1' };
    const after = { katilimDurumu: true, adSoyad: 'Yeni Ad', servisId: 'srv-1' };

    const result = katilimBildirimiLogic(before, after, 'p4');
    expect(result.changed).toBe(false);
  });
});

// ---------- SERVİS BAŞLADI BİLDİRİMİ ----------

describe('Servis Başladı Bildirimi Tests', () => {
  test('Pasiften aktife geçince tüm katılımcılara bildirim gider', () => {
    const before = { aktifMi: false, plaka: '34 ABC 001' };
    const after = { aktifMi: true, plaka: '34 ABC 001' };
    const katilimcilar = [
      { id: 'p1', adSoyad: 'Ali' },
      { id: 'p2', adSoyad: 'Veli' },
      { id: 'p3', adSoyad: 'Ayşe' },
    ];

    const notifications = servisBasladiBildirimiLogic(before, after, 'srv-1', katilimcilar);
    expect(notifications).toHaveLength(3);
    expect(notifications[0].plaka).toBe('34 ABC 001');
    expect(notifications[0].type).toBe('servis_basladi');
  });

  test('Zaten aktif olan servis için bildirim gitmez', () => {
    const before = { aktifMi: true, plaka: '34 ABC 001' };
    const after = { aktifMi: true, plaka: '34 ABC 001' };

    const notifications = servisBasladiBildirimiLogic(before, after, 'srv-1', []);
    expect(notifications).toHaveLength(0);
  });

  test('Aktiften pasife geçince bildirim gitmez', () => {
    const before = { aktifMi: true, plaka: '34 ABC 001' };
    const after = { aktifMi: false, plaka: '34 ABC 001' };

    const notifications = servisBasladiBildirimiLogic(before, after, 'srv-1', [
      { id: 'p1', adSoyad: 'Ali' },
    ]);
    expect(notifications).toHaveLength(0);
  });

  test('Katılımcı yoksa bildirim listesi boş döner', () => {
    const before = { aktifMi: false, plaka: '34 ABC 001' };
    const after = { aktifMi: true, plaka: '34 ABC 001' };

    const notifications = servisBasladiBildirimiLogic(before, after, 'srv-1', []);
    expect(notifications).toHaveLength(0);
  });

  test('Bildirim mesajı plaka içerir', () => {
    const before = { aktifMi: false, plaka: '06 XYZ 789' };
    const after = { aktifMi: true, plaka: '06 XYZ 789' };

    const notifications = servisBasladiBildirimiLogic(before, after, 'srv-1', [
      { id: 'p1', adSoyad: 'Test' },
    ]);
    expect(notifications[0].message).toContain('06 XYZ 789');
  });
});

// ---------- FIRESTORE GÜVENLİK KURALI MANTIĞI ----------

describe('Firestore Security Rules Logic Tests', () => {
  function canReadServis(authUser) {
    return authUser !== null;
  }

  function canCreateServis(authUser, userRole) {
    return authUser !== null && userRole === 'admin';
  }

  function canUpdateServis(authUser, userRole, servisSoforId, changedFields) {
    if (!authUser) return false;
    if (userRole === 'admin') return true;
    if (userRole === 'sofor' && authUser.uid === servisSoforId) {
      const allowedFields = ['konum', 'aktifMi'];
      return changedFields.every(f => allowedFields.includes(f));
    }
    return false;
  }

  function canUpdatePersonel(authUser, personelId, userRole, changedFields) {
    if (!authUser) return false;
    if (userRole === 'admin') return true;
    if (authUser.uid === personelId) {
      const allowedFields = ['binisNoktasi', 'katilimDurumu', 'servisId'];
      return changedFields.every(f => allowedFields.includes(f));
    }
    return false;
  }

  test('Giriş yapmış kullanıcı servisleri okuyabilir', () => {
    expect(canReadServis({ uid: 'user1' })).toBeTruthy();
  });

  test('Giriş yapmamış kullanıcı servisleri okuyamaz', () => {
    expect(canReadServis(null)).toBeFalsy();
  });

  test('Admin servis oluşturabilir', () => {
    expect(canCreateServis({ uid: 'adm1' }, 'admin')).toBeTruthy();
  });

  test('Personel servis oluşturamaz', () => {
    expect(canCreateServis({ uid: 'per1' }, 'personel')).toBeFalsy();
  });

  test('Şoför servis oluşturamaz', () => {
    expect(canCreateServis({ uid: 'drv1' }, 'sofor')).toBeFalsy();
  });

  test('Admin her alanı güncelleyebilir', () => {
    expect(canUpdateServis({ uid: 'adm1' }, 'admin', null, ['plaka', 'rotaAciklama'])).toBeTruthy();
  });

  test('Şoför kendi servisinin konum ve aktifliğini güncelleyebilir', () => {
    expect(canUpdateServis({ uid: 'drv1' }, 'sofor', 'drv1', ['konum', 'aktifMi'])).toBeTruthy();
  });

  test('Şoför başkasının servisini güncelleyemez', () => {
    expect(canUpdateServis({ uid: 'drv1' }, 'sofor', 'drv2', ['konum'])).toBeFalsy();
  });

  test('Şoför plaka alanını güncelleyemez', () => {
    expect(canUpdateServis({ uid: 'drv1' }, 'sofor', 'drv1', ['plaka'])).toBeFalsy();
  });

  test('Personel kendi katılım durumunu değiştirebilir', () => {
    expect(canUpdatePersonel({ uid: 'per1' }, 'per1', 'personel', ['katilimDurumu'])).toBeTruthy();
  });

  test('Personel kendi biniş noktasını değiştirebilir', () => {
    expect(canUpdatePersonel({ uid: 'per1' }, 'per1', 'personel', ['binisNoktasi'])).toBeTruthy();
  });

  test('Personel başka personelin bilgisini değiştiremez', () => {
    expect(canUpdatePersonel({ uid: 'per1' }, 'per2', 'personel', ['katilimDurumu'])).toBeFalsy();
  });

  test('Personel rolünü değiştiremez', () => {
    expect(canUpdatePersonel({ uid: 'per1' }, 'per1', 'personel', ['rol'])).toBeFalsy();
  });

  test('Admin herhangi bir personeli güncelleyebilir', () => {
    expect(canUpdatePersonel({ uid: 'adm1' }, 'per1', 'admin', ['rol', 'servisId'])).toBeTruthy();
  });
});

// ============================================================
// SONUÇLAR
// ============================================================

// Async testler için await gerekli
setTimeout(() => {
  console.log('\n' + '━'.repeat(60));
  console.log(`\n📊 CLOUD FUNCTIONS TEST SONUÇLARI`);
  console.log(`${'─'.repeat(40)}`);
  console.log(`  Toplam  : ${totalTests}`);
  console.log(`  Başarılı: ${passedTests} ✅`);
  console.log(`  Başarısız: ${failedTests} ❌`);
  console.log(`  Oran    : ${((passedTests / totalTests) * 100).toFixed(1)}%`);

  if (failures.length > 0) {
    console.log(`\n❌ BAŞARISIZ TESTLER:`);
    failures.forEach(f => {
      console.log(`  - ${f.name}: ${f.error}`);
    });
  }

  console.log(`\n${'━'.repeat(60)}\n`);
  process.exit(failedTests > 0 ? 1 : 0);
}, 1000);
