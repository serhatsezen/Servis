class AppConstants {
  AppConstants._();

  // Firebase Collections
  static const String servislerCollection = 'servisler';
  static const String personellerCollection = 'personeller';
  static const String rotalarCollection = 'rotalar';

  // Realtime Database Paths
  static const String konumlarPath = 'konumlar';

  // Roller
  static const String rolAdmin = 'admin';
  static const String rolSofor = 'sofor';
  static const String rolPersonel = 'personel';

  // Google Directions API
  static const String directionsBaseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  // Map defaults (Istanbul)
  static const double defaultLat = 41.0082;
  static const double defaultLng = 28.9784;
  static const double defaultZoom = 12.0;

  // Location update interval (milliseconds)
  static const int konumGuncellemeAraligi = 5000;

  // Distance filter (meters)
  static const double mesafeFiltresi = 10.0;
}
