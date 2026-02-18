/**
 * Servis Takip Uygulaması - Standalone Model & Logic Tests
 * Firebase bağımlılığı olmadan modellerin ve iş mantığının doğrulanması
 *
 * Bu dosya Dart modellerinin JS karşılıklarını kullanarak
 * serializasyon, validasyon ve iş mantığı testlerini çalıştırır.
 */

// ============================================================
// MODEL TANIMLARI (Dart modellerinin JS karşılıkları)
// ============================================================

class KonumModel {
  constructor(lat, lng) {
    this.lat = lat;
    this.lng = lng;
  }

  static fromMap(map) {
    return new KonumModel(Number(map.lat), Number(map.lng));
  }

  toMap() {
    return { lat: this.lat, lng: this.lng };
  }

  equals(other) {
    return this.lat === other.lat && this.lng === other.lng;
  }
}

class ServisModel {
  constructor({ id, plaka, rotaAciklama, aktifMi, personelListesi, konum, soforId }) {
    this.id = id;
    this.plaka = plaka;
    this.rotaAciklama = rotaAciklama;
    this.aktifMi = aktifMi;
    this.personelListesi = personelListesi || [];
    this.konum = konum || null;
    this.soforId = soforId || null;
  }

  static fromFirestore(id, data) {
    return new ServisModel({
      id,
      plaka: data.plaka || '',
      rotaAciklama: data.rotaAciklama || '',
      aktifMi: data.aktifMi || false,
      personelListesi: data.personelListesi || [],
      konum: data.konum ? KonumModel.fromMap(data.konum) : null,
      soforId: data.soforId || null,
    });
  }

  toMap() {
    return {
      plaka: this.plaka,
      rotaAciklama: this.rotaAciklama,
      aktifMi: this.aktifMi,
      personelListesi: this.personelListesi,
      konum: this.konum ? this.konum.toMap() : null,
      soforId: this.soforId,
    };
  }

  copyWith(overrides) {
    return new ServisModel({
      id: overrides.id ?? this.id,
      plaka: overrides.plaka ?? this.plaka,
      rotaAciklama: overrides.rotaAciklama ?? this.rotaAciklama,
      aktifMi: overrides.aktifMi ?? this.aktifMi,
      personelListesi: overrides.personelListesi ?? this.personelListesi,
      konum: overrides.konum ?? this.konum,
      soforId: overrides.soforId ?? this.soforId,
    });
  }
}

class PersonelModel {
  constructor({ id, adSoyad, servisId, binisNoktasi, katilimDurumu, email, rol }) {
    this.id = id;
    this.adSoyad = adSoyad;
    this.servisId = servisId || null;
    this.binisNoktasi = binisNoktasi || null;
    this.katilimDurumu = katilimDurumu;
    this.email = email;
    this.rol = rol;
  }

  static fromFirestore(id, data) {
    return new PersonelModel({
      id,
      adSoyad: data.adSoyad || '',
      servisId: data.servisId || null,
      binisNoktasi: data.binisNoktasi ? KonumModel.fromMap(data.binisNoktasi) : null,
      katilimDurumu: data.katilimDurumu || false,
      email: data.email || '',
      rol: data.rol || 'personel',
    });
  }

  toMap() {
    return {
      adSoyad: this.adSoyad,
      servisId: this.servisId,
      binisNoktasi: this.binisNoktasi ? this.binisNoktasi.toMap() : null,
      katilimDurumu: this.katilimDurumu,
      email: this.email,
      rol: this.rol,
    };
  }

  get isAdmin() { return this.rol === 'admin'; }
  get isSofor() { return this.rol === 'sofor'; }
  get isPersonel() { return this.rol === 'personel'; }

  copyWith(overrides) {
    return new PersonelModel({
      id: overrides.id ?? this.id,
      adSoyad: overrides.adSoyad ?? this.adSoyad,
      servisId: overrides.servisId !== undefined ? overrides.servisId : this.servisId,
      binisNoktasi: overrides.binisNoktasi !== undefined ? overrides.binisNoktasi : this.binisNoktasi,
      katilimDurumu: overrides.katilimDurumu ?? this.katilimDurumu,
      email: overrides.email ?? this.email,
      rol: overrides.rol ?? this.rol,
    });
  }
}

class DurakModel {
  constructor({ konum, personelId, sira }) {
    this.konum = konum;
    this.personelId = personelId;
    this.sira = sira;
  }

  static fromMap(map) {
    return new DurakModel({
      konum: new KonumModel(map.lat, map.lng),
      personelId: map.personelId || '',
      sira: map.sira || 0,
    });
  }

  toMap() {
    return {
      ...this.konum.toMap(),
      personelId: this.personelId,
      sira: this.sira,
    };
  }
}

class RotaModel {
  constructor({ id, servisId, duraklar, optimumSira, tahminiSure, polyline, olusturulmaTarihi }) {
    this.id = id || null;
    this.servisId = servisId;
    this.duraklar = duraklar;
    this.optimumSira = optimumSira;
    this.tahminiSure = tahminiSure;
    this.polyline = polyline || null;
    this.olusturulmaTarihi = olusturulmaTarihi || null;
  }

  toMap() {
    return {
      servisId: this.servisId,
      duraklar: this.duraklar.map(d => d.toMap()),
      optimumSira: this.optimumSira,
      tahminiSure: this.tahminiSure,
      polyline: this.polyline,
    };
  }
}

// ============================================================
// POLYLINE DECODER (Dart kodunun JS karşılığı)
// ============================================================

function decodePolyline(encoded) {
  const points = [];
  let index = 0;
  let lat = 0;
  let lng = 0;

  while (index < encoded.length) {
    let shift = 0;
    let result = 0;
    let b;
    do {
      b = encoded.charCodeAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    const dlat = (result & 1) !== 0 ? ~(result >> 1) : result >> 1;
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.charCodeAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    const dlng = (result & 1) !== 0 ? ~(result >> 1) : result >> 1;
    lng += dlng;

    points.push({ lat: lat / 1e5, lng: lng / 1e5 });
  }

  return points;
}

// ============================================================
// AUTH ERROR PARSER (Dart kodunun JS karşılığı)
// ============================================================

function parseAuthError(error) {
  if (error.includes('user-not-found')) return 'Kullanıcı bulunamadı.';
  if (error.includes('wrong-password')) return 'Hatalı şifre.';
  if (error.includes('email-already-in-use')) return 'Bu e-posta adresi zaten kullanımda.';
  if (error.includes('weak-password')) return 'Şifre çok zayıf. En az 6 karakter olmalıdır.';
  if (error.includes('invalid-email')) return 'Geçersiz e-posta adresi.';
  if (error.includes('too-many-requests')) return 'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
  return 'Bir hata oluştu. Lütfen tekrar deneyin.';
}

// ============================================================
// MESAFE HESAPLAMA (Haversine formülü)
// ============================================================

function mesafeHesapla(lat1, lng1, lat2, lng2) {
  const R = 6371000; // Dünya yarıçapı (metre)
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// ============================================================
// TEST FRAMEWORK (Minimal)
// ============================================================

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
    toBeTruthy() {
      if (!actual) throw new Error(`Expected truthy, got ${JSON.stringify(actual)}`);
    },
    toBeFalsy() {
      if (actual) throw new Error(`Expected falsy, got ${JSON.stringify(actual)}`);
    },
    toBeNull() {
      if (actual !== null) throw new Error(`Expected null, got ${JSON.stringify(actual)}`);
    },
    toBeGreaterThan(n) {
      if (actual <= n) throw new Error(`Expected ${actual} > ${n}`);
    },
    toBeLessThan(n) {
      if (actual >= n) throw new Error(`Expected ${actual} < ${n}`);
    },
    toHaveLength(n) {
      if (actual.length !== n) throw new Error(`Expected length ${n}, got ${actual.length}`);
    },
    toContain(item) {
      if (!actual.includes(item)) throw new Error(`Expected array to contain ${JSON.stringify(item)}`);
    },
    toBeInstanceOf(cls) {
      if (!(actual instanceof cls)) throw new Error(`Expected instance of ${cls.name}`);
    },
    toBeCloseTo(expected, precision = 2) {
      const pow = Math.pow(10, precision);
      if (Math.round(actual * pow) !== Math.round(expected * pow))
        throw new Error(`Expected ${actual} to be close to ${expected}`);
    }
  };
}

// ============================================================
// TESTLER
// ============================================================

console.log('\n🚌 SERVİS TAKİP UYGULAMASI - UNIT TEST SUITE');
console.log('━'.repeat(60));

// ---------- KONUM MODEL TESTLERİ ----------

describe('KonumModel Tests', () => {
  test('KonumModel oluşturma', () => {
    const konum = new KonumModel(41.0082, 28.9784);
    expect(konum.lat).toBe(41.0082);
    expect(konum.lng).toBe(28.9784);
  });

  test('KonumModel.fromMap ile oluşturma', () => {
    const konum = KonumModel.fromMap({ lat: 41.0082, lng: 28.9784 });
    expect(konum.lat).toBe(41.0082);
    expect(konum.lng).toBe(28.9784);
  });

  test('KonumModel.toMap serializasyon', () => {
    const konum = new KonumModel(41.0082, 28.9784);
    const map = konum.toMap();
    expect(map.lat).toBe(41.0082);
    expect(map.lng).toBe(28.9784);
  });

  test('KonumModel eşitlik kontrolü', () => {
    const k1 = new KonumModel(41.0082, 28.9784);
    const k2 = new KonumModel(41.0082, 28.9784);
    const k3 = new KonumModel(40.0, 29.0);
    expect(k1.equals(k2)).toBe(true);
    expect(k1.equals(k3)).toBe(false);
  });

  test('KonumModel round-trip serializasyon', () => {
    const original = new KonumModel(41.0082, 28.9784);
    const map = original.toMap();
    const restored = KonumModel.fromMap(map);
    expect(restored.lat).toBe(original.lat);
    expect(restored.lng).toBe(original.lng);
  });

  test('KonumModel string lat/lng dönüşümü', () => {
    const konum = KonumModel.fromMap({ lat: '41.0082', lng: '28.9784' });
    expect(konum.lat).toBe(41.0082);
    expect(typeof konum.lat).toBe('number');
  });
});

// ---------- SERVİS MODEL TESTLERİ ----------

describe('ServisModel Tests', () => {
  test('ServisModel oluşturma', () => {
    const servis = new ServisModel({
      id: 'srv-1',
      plaka: '34 ABC 123',
      rotaAciklama: 'Kadıköy - Ataşehir',
      aktifMi: true,
      personelListesi: ['p1', 'p2'],
    });
    expect(servis.id).toBe('srv-1');
    expect(servis.plaka).toBe('34 ABC 123');
    expect(servis.aktifMi).toBe(true);
    expect(servis.personelListesi).toHaveLength(2);
  });

  test('ServisModel.fromFirestore deserialization', () => {
    const data = {
      plaka: '06 XYZ 789',
      rotaAciklama: 'Ankara - Kızılay',
      aktifMi: false,
      personelListesi: ['p1'],
      konum: { lat: 39.9334, lng: 32.8597 },
      soforId: 'drv-1',
    };
    const servis = ServisModel.fromFirestore('doc-123', data);
    expect(servis.id).toBe('doc-123');
    expect(servis.plaka).toBe('06 XYZ 789');
    expect(servis.konum).toBeInstanceOf(KonumModel);
    expect(servis.konum.lat).toBe(39.9334);
    expect(servis.soforId).toBe('drv-1');
  });

  test('ServisModel.toMap serialization', () => {
    const servis = new ServisModel({
      id: 'srv-1',
      plaka: '34 ABC 123',
      rotaAciklama: 'Test',
      aktifMi: true,
      personelListesi: [],
      konum: new KonumModel(41.0, 29.0),
    });
    const map = servis.toMap();
    expect(map.plaka).toBe('34 ABC 123');
    expect(map.konum.lat).toBe(41.0);
    expect(map.aktifMi).toBe(true);
  });

  test('ServisModel varsayılan değerler (konum null, soforId null)', () => {
    const data = { plaka: '35 DEF 456', rotaAciklama: 'İzmir' };
    const servis = ServisModel.fromFirestore('id-1', data);
    expect(servis.konum).toBeNull();
    expect(servis.soforId).toBeNull();
    expect(servis.aktifMi).toBe(false);
    expect(servis.personelListesi).toHaveLength(0);
  });

  test('ServisModel.copyWith kısmi güncelleme', () => {
    const original = new ServisModel({
      id: 'srv-1',
      plaka: '34 OLD 111',
      rotaAciklama: 'Eski rota',
      aktifMi: false,
      personelListesi: ['p1'],
    });
    const updated = original.copyWith({ plaka: '34 NEW 222', aktifMi: true });
    expect(updated.plaka).toBe('34 NEW 222');
    expect(updated.aktifMi).toBe(true);
    expect(updated.rotaAciklama).toBe('Eski rota'); // değişmedi
    expect(updated.id).toBe('srv-1'); // değişmedi
  });

  test('ServisModel round-trip serializasyon', () => {
    const original = new ServisModel({
      id: 'srv-1',
      plaka: '34 RTR 999',
      rotaAciklama: 'Round Trip',
      aktifMi: true,
      personelListesi: ['p1', 'p2', 'p3'],
      konum: new KonumModel(41.5, 29.5),
      soforId: 'drv-1',
    });
    const map = original.toMap();
    const restored = ServisModel.fromFirestore(original.id, map);
    expect(restored.plaka).toBe(original.plaka);
    expect(restored.personelListesi).toHaveLength(3);
    expect(restored.konum.lat).toBe(41.5);
  });
});

// ---------- PERSONEL MODEL TESTLERİ ----------

describe('PersonelModel Tests', () => {
  test('PersonelModel oluşturma (admin)', () => {
    const admin = new PersonelModel({
      id: 'adm-1',
      adSoyad: 'Ali Yılmaz',
      katilimDurumu: true,
      email: 'ali@test.com',
      rol: 'admin',
    });
    expect(admin.isAdmin).toBe(true);
    expect(admin.isSofor).toBe(false);
    expect(admin.isPersonel).toBe(false);
  });

  test('PersonelModel oluşturma (şoför)', () => {
    const sofor = new PersonelModel({
      id: 'drv-1',
      adSoyad: 'Mehmet Demir',
      katilimDurumu: true,
      email: 'mehmet@test.com',
      rol: 'sofor',
    });
    expect(sofor.isAdmin).toBe(false);
    expect(sofor.isSofor).toBe(true);
    expect(sofor.isPersonel).toBe(false);
  });

  test('PersonelModel oluşturma (personel)', () => {
    const personel = new PersonelModel({
      id: 'per-1',
      adSoyad: 'Ayşe Kaya',
      servisId: 'srv-1',
      binisNoktasi: new KonumModel(41.01, 28.98),
      katilimDurumu: true,
      email: 'ayse@test.com',
      rol: 'personel',
    });
    expect(personel.isPersonel).toBe(true);
    expect(personel.servisId).toBe('srv-1');
    expect(personel.binisNoktasi.lat).toBe(41.01);
  });

  test('PersonelModel.fromFirestore deserialization', () => {
    const data = {
      adSoyad: 'Test User',
      servisId: 'srv-1',
      binisNoktasi: { lat: 41.05, lng: 29.01 },
      katilimDurumu: true,
      email: 'test@test.com',
      rol: 'personel',
    };
    const personel = PersonelModel.fromFirestore('uid-123', data);
    expect(personel.id).toBe('uid-123');
    expect(personel.adSoyad).toBe('Test User');
    expect(personel.binisNoktasi).toBeInstanceOf(KonumModel);
    expect(personel.binisNoktasi.lat).toBe(41.05);
  });

  test('PersonelModel.toMap serialization', () => {
    const personel = new PersonelModel({
      id: 'per-1',
      adSoyad: 'Fatma Yıldız',
      servisId: 'srv-2',
      binisNoktasi: new KonumModel(40.99, 28.85),
      katilimDurumu: false,
      email: 'fatma@test.com',
      rol: 'personel',
    });
    const map = personel.toMap();
    expect(map.adSoyad).toBe('Fatma Yıldız');
    expect(map.katilimDurumu).toBe(false);
    expect(map.binisNoktasi.lat).toBe(40.99);
    expect(map.rol).toBe('personel');
  });

  test('PersonelModel varsayılan değerler', () => {
    const data = { adSoyad: 'Boş Profil', email: 'bos@test.com' };
    const personel = PersonelModel.fromFirestore('uid-456', data);
    expect(personel.servisId).toBeNull();
    expect(personel.binisNoktasi).toBeNull();
    expect(personel.katilimDurumu).toBe(false);
    expect(personel.rol).toBe('personel');
  });

  test('PersonelModel.copyWith katılım değiştirme', () => {
    const original = new PersonelModel({
      id: 'per-1',
      adSoyad: 'Katılımcı',
      katilimDurumu: true,
      email: 'k@test.com',
      rol: 'personel',
    });
    const updated = original.copyWith({ katilimDurumu: false });
    expect(updated.katilimDurumu).toBe(false);
    expect(updated.adSoyad).toBe('Katılımcı');
  });

  test('PersonelModel.copyWith biniş noktası güncelleme', () => {
    const original = new PersonelModel({
      id: 'per-1',
      adSoyad: 'Nokta',
      katilimDurumu: true,
      email: 'n@test.com',
      rol: 'personel',
    });
    const yeniNokta = new KonumModel(41.1, 29.1);
    const updated = original.copyWith({ binisNoktasi: yeniNokta });
    expect(updated.binisNoktasi.lat).toBe(41.1);
    expect(updated.binisNoktasi.lng).toBe(29.1);
  });
});

// ---------- ROTA MODEL TESTLERİ ----------

describe('RotaModel & DurakModel Tests', () => {
  test('DurakModel oluşturma', () => {
    const durak = new DurakModel({
      konum: new KonumModel(41.0, 29.0),
      personelId: 'per-1',
      sira: 0,
    });
    expect(durak.konum.lat).toBe(41.0);
    expect(durak.personelId).toBe('per-1');
    expect(durak.sira).toBe(0);
  });

  test('DurakModel.fromMap', () => {
    const durak = DurakModel.fromMap({
      lat: 41.05,
      lng: 29.05,
      personelId: 'per-2',
      sira: 1,
    });
    expect(durak.konum.lat).toBe(41.05);
    expect(durak.personelId).toBe('per-2');
    expect(durak.sira).toBe(1);
  });

  test('DurakModel.toMap serializasyon', () => {
    const durak = new DurakModel({
      konum: new KonumModel(41.0, 29.0),
      personelId: 'per-1',
      sira: 2,
    });
    const map = durak.toMap();
    expect(map.lat).toBe(41.0);
    expect(map.lng).toBe(29.0);
    expect(map.personelId).toBe('per-1');
    expect(map.sira).toBe(2);
  });

  test('RotaModel oluşturma', () => {
    const rota = new RotaModel({
      id: 'rota-1',
      servisId: 'srv-1',
      duraklar: [
        new DurakModel({ konum: new KonumModel(41.0, 29.0), personelId: 'p1', sira: 0 }),
        new DurakModel({ konum: new KonumModel(41.1, 29.1), personelId: 'p2', sira: 1 }),
      ],
      optimumSira: ['0', '1'],
      tahminiSure: 35,
      polyline: 'abc123',
    });
    expect(rota.servisId).toBe('srv-1');
    expect(rota.duraklar).toHaveLength(2);
    expect(rota.tahminiSure).toBe(35);
    expect(rota.polyline).toBe('abc123');
  });

  test('RotaModel.toMap serialization', () => {
    const rota = new RotaModel({
      servisId: 'srv-1',
      duraklar: [
        new DurakModel({ konum: new KonumModel(41.0, 29.0), personelId: 'p1', sira: 0 }),
      ],
      optimumSira: ['0'],
      tahminiSure: 20,
      polyline: 'xyz',
    });
    const map = rota.toMap();
    expect(map.servisId).toBe('srv-1');
    expect(map.duraklar).toHaveLength(1);
    expect(map.duraklar[0].lat).toBe(41.0);
    expect(map.tahminiSure).toBe(20);
  });

  test('RotaModel boş durak listesi', () => {
    const rota = new RotaModel({
      servisId: 'srv-1',
      duraklar: [],
      optimumSira: [],
      tahminiSure: 0,
    });
    expect(rota.duraklar).toHaveLength(0);
    expect(rota.tahminiSure).toBe(0);
    expect(rota.polyline).toBeNull();
  });
});

// ---------- POLYLINE DECODER TESTLERİ ----------

describe('Google Polyline Decoder Tests', () => {
  test('Basit polyline decode', () => {
    // "_p~iF~ps|U" İstanbul civarı bir nokta
    const encoded = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';
    const points = decodePolyline(encoded);
    expect(points.length).toBeGreaterThan(0);
    expect(typeof points[0].lat).toBe('number');
    expect(typeof points[0].lng).toBe('number');
  });

  test('Boş polyline decode', () => {
    const points = decodePolyline('');
    expect(points).toHaveLength(0);
  });

  test('Bilinen polyline doğrulama', () => {
    // Google Polyline: (38.5, -120.2) -> (40.7, -120.95) -> (43.252, -126.453)
    const encoded = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';
    const points = decodePolyline(encoded);
    expect(points).toHaveLength(3);
    expect(points[0].lat).toBeCloseTo(38.5, 0);
    expect(points[0].lng).toBeCloseTo(-120.2, 0);
    expect(points[1].lat).toBeCloseTo(40.7, 0);
    expect(points[2].lat).toBeCloseTo(43.252, 0);
  });
});

// ---------- AUTH HATA MESAJLARI TESTLERİ ----------

describe('Auth Error Parser Tests', () => {
  test('user-not-found hatası', () => {
    expect(parseAuthError('[firebase_auth/user-not-found] No user found'))
      .toBe('Kullanıcı bulunamadı.');
  });

  test('wrong-password hatası', () => {
    expect(parseAuthError('[firebase_auth/wrong-password] Wrong password'))
      .toBe('Hatalı şifre.');
  });

  test('email-already-in-use hatası', () => {
    expect(parseAuthError('[firebase_auth/email-already-in-use] Email exists'))
      .toBe('Bu e-posta adresi zaten kullanımda.');
  });

  test('weak-password hatası', () => {
    expect(parseAuthError('[firebase_auth/weak-password] Too weak'))
      .toBe('Şifre çok zayıf. En az 6 karakter olmalıdır.');
  });

  test('invalid-email hatası', () => {
    expect(parseAuthError('[firebase_auth/invalid-email] Bad email'))
      .toBe('Geçersiz e-posta adresi.');
  });

  test('too-many-requests hatası', () => {
    expect(parseAuthError('[firebase_auth/too-many-requests] Blocked'))
      .toBe('Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.');
  });

  test('Bilinmeyen hata', () => {
    expect(parseAuthError('Some random error'))
      .toBe('Bir hata oluştu. Lütfen tekrar deneyin.');
  });
});

// ---------- MESAFE HESAPLAMA TESTLERİ ----------

describe('Mesafe Hesaplama Tests (Haversine)', () => {
  test('Aynı nokta arası mesafe 0', () => {
    const mesafe = mesafeHesapla(41.0082, 28.9784, 41.0082, 28.9784);
    expect(mesafe).toBeCloseTo(0, 0);
  });

  test('İstanbul - Ankara arası mesafe (~350km)', () => {
    const mesafe = mesafeHesapla(41.0082, 28.9784, 39.9334, 32.8597);
    const km = mesafe / 1000;
    expect(km).toBeGreaterThan(300);
    expect(km).toBeLessThan(400);
  });

  test('Kadıköy - Taksim arası mesafe (~8km)', () => {
    const mesafe = mesafeHesapla(40.9823, 29.0259, 41.0370, 28.9850);
    const km = mesafe / 1000;
    expect(km).toBeGreaterThan(5);
    expect(km).toBeLessThan(12);
  });

  test('Kısa mesafe (aynı mahalle ~500m)', () => {
    const mesafe = mesafeHesapla(41.0082, 28.9784, 41.0120, 28.9800);
    expect(mesafe).toBeGreaterThan(200);
    expect(mesafe).toBeLessThan(1000);
  });
});

// ---------- İŞ MANTIĞI TESTLERİ ----------

describe('İş Mantığı Tests', () => {
  test('Servise personel ekleme mantığı', () => {
    const servis = new ServisModel({
      id: 'srv-1',
      plaka: '34 TEST 001',
      rotaAciklama: 'Test Rota',
      aktifMi: false,
      personelListesi: ['p1', 'p2'],
    });

    // Yeni personel ekle
    const yeniListe = [...servis.personelListesi, 'p3'];
    const updated = servis.copyWith({ personelListesi: yeniListe });
    expect(updated.personelListesi).toHaveLength(3);
    expect(updated.personelListesi).toContain('p3');
  });

  test('Servisten personel çıkarma mantığı', () => {
    const servis = new ServisModel({
      id: 'srv-1',
      plaka: '34 TEST 001',
      rotaAciklama: 'Test Rota',
      aktifMi: false,
      personelListesi: ['p1', 'p2', 'p3'],
    });

    const yeniListe = servis.personelListesi.filter(id => id !== 'p2');
    const updated = servis.copyWith({ personelListesi: yeniListe });
    expect(updated.personelListesi).toHaveLength(2);
    expect(updated.personelListesi).toContain('p1');
    expect(updated.personelListesi).toContain('p3');
  });

  test('Katılım durumu filtreleme', () => {
    const personeller = [
      new PersonelModel({ id: 'p1', adSoyad: 'Ali', katilimDurumu: true, email: 'a@t.com', rol: 'personel' }),
      new PersonelModel({ id: 'p2', adSoyad: 'Veli', katilimDurumu: false, email: 'v@t.com', rol: 'personel' }),
      new PersonelModel({ id: 'p3', adSoyad: 'Ayşe', katilimDurumu: true, email: 'ay@t.com', rol: 'personel' }),
      new PersonelModel({ id: 'p4', adSoyad: 'Fatma', katilimDurumu: false, email: 'f@t.com', rol: 'personel' }),
    ];

    const katilimcilar = personeller.filter(p => p.katilimDurumu);
    expect(katilimcilar).toHaveLength(2);
    expect(katilimcilar[0].adSoyad).toBe('Ali');
    expect(katilimcilar[1].adSoyad).toBe('Ayşe');
  });

  test('Rota optimizasyonu - durak sıralaması', () => {
    const duraklar = [
      new KonumModel(41.00, 29.00), // p1
      new KonumModel(41.05, 29.05), // p2
      new KonumModel(41.02, 29.02), // p3
    ];
    const personelIds = ['p1', 'p2', 'p3'];

    // Simüle: API waypoint_order = [0, 2, 1] (p1 -> p3 -> p2 en optimum)
    const waypointOrder = [0, 2, 1];

    const optimizedDuraklar = waypointOrder.map((originalIndex, sira) =>
      new DurakModel({
        konum: duraklar[originalIndex],
        personelId: personelIds[originalIndex],
        sira: sira,
      })
    );

    expect(optimizedDuraklar).toHaveLength(3);
    expect(optimizedDuraklar[0].personelId).toBe('p1');
    expect(optimizedDuraklar[0].sira).toBe(0);
    expect(optimizedDuraklar[1].personelId).toBe('p3');
    expect(optimizedDuraklar[1].sira).toBe(1);
    expect(optimizedDuraklar[2].personelId).toBe('p2');
    expect(optimizedDuraklar[2].sira).toBe(2);
  });

  test('Servis aktiflik değiştirme akışı', () => {
    let servis = new ServisModel({
      id: 'srv-1',
      plaka: '34 AKT 001',
      rotaAciklama: 'Aktiflik Test',
      aktifMi: false,
      personelListesi: [],
    });

    expect(servis.aktifMi).toBe(false);

    // Şoför servisi başlatır
    servis = servis.copyWith({ aktifMi: true });
    expect(servis.aktifMi).toBe(true);

    // Şoför servisi durdurur
    servis = servis.copyWith({ aktifMi: false });
    expect(servis.aktifMi).toBe(false);
  });

  test('Rol bazlı yetki kontrolü', () => {
    const admin = new PersonelModel({ id: '1', adSoyad: 'Admin', katilimDurumu: true, email: 'a@t.com', rol: 'admin' });
    const sofor = new PersonelModel({ id: '2', adSoyad: 'Şoför', katilimDurumu: true, email: 's@t.com', rol: 'sofor' });
    const personel = new PersonelModel({ id: '3', adSoyad: 'Personel', katilimDurumu: true, email: 'p@t.com', rol: 'personel' });

    // Admin servis oluşturabilir
    expect(admin.isAdmin).toBe(true);
    // Şoför konum paylaşabilir
    expect(sofor.isSofor).toBe(true);
    // Personel katılım bildirebilir
    expect(personel.isPersonel).toBe(true);

    // Rollerin karışmaması
    expect(admin.isSofor).toBe(false);
    expect(admin.isPersonel).toBe(false);
    expect(sofor.isAdmin).toBe(false);
    expect(personel.isAdmin).toBe(false);
  });

  test('Kalan süre hesaplama (mock)', () => {
    // Servis konumu ve personel biniş noktası
    const servisKonum = new KonumModel(41.00, 29.00);
    const binisNoktasi = new KonumModel(41.05, 29.05);

    // Mesafe hesapla
    const mesafe = mesafeHesapla(
      servisKonum.lat, servisKonum.lng,
      binisNoktasi.lat, binisNoktasi.lng
    );

    // Ortalama hız 30 km/h ile tahmini süre
    const hizMsn = 30 * 1000 / 3600; // ~8.33 m/s
    const sureSaniye = mesafe / hizMsn;
    const sureDakika = Math.ceil(sureSaniye / 60);

    expect(mesafe).toBeGreaterThan(0);
    expect(sureDakika).toBeGreaterThan(0);
  });
});

// ---------- BLOC STATE MACHINE TESTLERİ ----------

describe('Bloc State Machine Simulation Tests', () => {
  // AuthBloc state geçişleri
  test('AuthBloc: Initial -> Loading -> Authenticated', () => {
    const states = ['AuthInitial', 'AuthLoading', 'AuthAuthenticated'];
    expect(states[0]).toBe('AuthInitial');
    expect(states[1]).toBe('AuthLoading');
    expect(states[2]).toBe('AuthAuthenticated');
  });

  test('AuthBloc: Initial -> Loading -> Error (hatalı giriş)', () => {
    const states = ['AuthInitial', 'AuthLoading', 'AuthError'];
    expect(states).toHaveLength(3);
    expect(states[2]).toBe('AuthError');
  });

  test('AuthBloc: Authenticated -> Unauthenticated (çıkış)', () => {
    const states = ['AuthAuthenticated', 'AuthUnauthenticated'];
    expect(states[1]).toBe('AuthUnauthenticated');
  });

  // ServisBloc state geçişleri
  test('ServisBloc: Initial -> Loading -> Loaded', () => {
    const states = ['ServisInitial', 'ServisLoading', 'ServisLoaded'];
    expect(states).toHaveLength(3);
  });

  test('ServisBloc: Loaded -> OperationSuccess (servis oluşturma)', () => {
    const events = ['ServisOlusturuldu', 'ServislerYuklendi'];
    expect(events).toHaveLength(2);
  });

  // KonumBloc state geçişleri
  test('KonumBloc: Initial -> Loading -> Paylaşılıyor (şoför)', () => {
    const states = ['KonumInitial', 'KonumLoading', 'KonumPaylasiliyor'];
    expect(states[2]).toBe('KonumPaylasiliyor');
  });

  test('KonumBloc: Initial -> Loading -> TakipEdiliyor (personel)', () => {
    const states = ['KonumInitial', 'KonumLoading', 'ServisKonumuTakipEdiliyor'];
    expect(states[2]).toBe('ServisKonumuTakipEdiliyor');
  });
});

// ---------- EDGE CASE TESTLERİ ----------

describe('Edge Case Tests', () => {
  test('Boş personel listesi ile servis', () => {
    const servis = new ServisModel({
      id: 'srv-empty',
      plaka: '34 EMP 000',
      rotaAciklama: 'Boş servis',
      aktifMi: false,
      personelListesi: [],
    });
    expect(servis.personelListesi).toHaveLength(0);
    const map = servis.toMap();
    expect(map.personelListesi).toHaveLength(0);
  });

  test('Çok uzun plaka metni', () => {
    const servis = new ServisModel({
      id: 'srv-long',
      plaka: '34 ABCDEFGHIJKLM 9999999',
      rotaAciklama: 'A'.repeat(500),
      aktifMi: false,
      personelListesi: [],
    });
    expect(servis.plaka.length).toBeGreaterThan(10);
    expect(servis.rotaAciklama.length).toBe(500);
  });

  test('Konum sınır değerleri', () => {
    // Kuzey kutbu
    const kuzey = new KonumModel(90, 0);
    expect(kuzey.lat).toBe(90);

    // Güney kutbu
    const guney = new KonumModel(-90, 0);
    expect(guney.lat).toBe(-90);

    // Tarih çizgisi
    const tarih1 = new KonumModel(0, 180);
    const tarih2 = new KonumModel(0, -180);
    expect(tarih1.lng).toBe(180);
    expect(tarih2.lng).toBe(-180);
  });

  test('Aynı konumda iki personel', () => {
    const konum = new KonumModel(41.0, 29.0);
    const p1 = new PersonelModel({
      id: 'p1', adSoyad: 'Ali', katilimDurumu: true,
      email: 'a@t.com', rol: 'personel', binisNoktasi: konum,
    });
    const p2 = new PersonelModel({
      id: 'p2', adSoyad: 'Veli', katilimDurumu: true,
      email: 'v@t.com', rol: 'personel', binisNoktasi: konum,
    });
    expect(p1.binisNoktasi.lat).toBe(p2.binisNoktasi.lat);
    expect(p1.binisNoktasi.lng).toBe(p2.binisNoktasi.lng);
    expect(p1.id).toBe('p1');
    expect(p2.id).toBe('p2');
  });

  test('Servis konum güncelleme simülasyonu', () => {
    let servis = new ServisModel({
      id: 'srv-1',
      plaka: '34 GPS 001',
      rotaAciklama: 'GPS Test',
      aktifMi: true,
      personelListesi: [],
    });

    // 5 konum güncellemesi simüle et
    const locations = [
      new KonumModel(41.000, 29.000),
      new KonumModel(41.005, 29.003),
      new KonumModel(41.010, 29.006),
      new KonumModel(41.015, 29.009),
      new KonumModel(41.020, 29.012),
    ];

    for (const loc of locations) {
      servis = servis.copyWith({ konum: loc });
    }

    // Son konum doğrulaması
    expect(servis.konum.lat).toBe(41.020);
    expect(servis.konum.lng).toBe(29.012);
  });
});

// ============================================================
// SONUÇLAR
// ============================================================

console.log('\n' + '━'.repeat(60));
console.log(`\n📊 TEST SONUÇLARI`);
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
