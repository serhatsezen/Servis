/// API anahtarları - Production'da environment variables kullanılmalı
class ApiKeys {
  ApiKeys._();

  // Google Maps API Key - Bu değeri kendi API anahtarınızla değiştirin
  // Production'da bu değer environment variable'dan okunmalıdır
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
}
