import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import '../models/servis_model.dart';
import '../../core/constants/app_constants.dart';

class KonumRepository {
  final FirebaseDatabase _database;

  KonumRepository({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;

  DatabaseReference _konumRef(String servisId) =>
      _database.ref('${AppConstants.konumlarPath}/$servisId');

  /// Servis konumunu Realtime Database'e yaz (düşük gecikmeli)
  Future<void> konumGuncelle(
      String servisId, double lat, double lng) async {
    await _konumRef(servisId).set({
      'lat': lat,
      'lng': lng,
      'timestamp': ServerValue.timestamp,
    });
  }

  /// Servis konum stream (gerçek zamanlı takip)
  Stream<KonumModel?> konumStream(String servisId) {
    return _konumRef(servisId).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return null;
      final map = Map<String, dynamic>.from(data as Map);
      return KonumModel(
        lat: (map['lat'] as num).toDouble(),
        lng: (map['lng'] as num).toDouble(),
      );
    });
  }

  /// Konum paylaşımını durdur
  Future<void> konumSil(String servisId) async {
    await _konumRef(servisId).remove();
  }

  /// Cihaz konum izni kontrol
  Future<bool> konumIzniKontrol() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Anlık konum al
  Future<Position> anlıkKonumAl() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Konum değişikliklerini takip et
  Stream<Position> konumTakibi() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  /// İki nokta arası mesafe hesapla (metre)
  double mesafeHesapla(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }
}
