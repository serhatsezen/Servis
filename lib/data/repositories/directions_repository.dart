import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/servis_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/api_keys.dart';

class DirectionsResult {
  final List<KonumModel> optimizedWaypoints;
  final int totalDurationMinutes;
  final String encodedPolyline;
  final List<int> waypointOrder;

  const DirectionsResult({
    required this.optimizedWaypoints,
    required this.totalDurationMinutes,
    required this.encodedPolyline,
    required this.waypointOrder,
  });
}

class DirectionsRepository {
  final http.Client _client;

  DirectionsRepository({http.Client? client})
      : _client = client ?? http.Client();

  /// Google Directions API ile optimize edilmiş rota hesapla
  Future<DirectionsResult> rotaHesapla({
    required KonumModel baslangic,
    required List<KonumModel> duraklar,
  }) async {
    if (duraklar.isEmpty) {
      throw Exception('En az bir durak noktası gerekli.');
    }

    // Durakları waypoints formatına çevir
    final waypoints = duraklar
        .map((d) => '${d.lat},${d.lng}')
        .join('|');

    // Son durak = bitiş noktası
    final bitis = duraklar.last;

    final url = Uri.parse(
      '${AppConstants.directionsBaseUrl}'
      '?origin=${baslangic.lat},${baslangic.lng}'
      '&destination=${bitis.lat},${bitis.lng}'
      '&waypoints=optimize:true|$waypoints'
      '&key=${ApiKeys.googleMapsApiKey}'
      '&language=tr',
    );

    final response = await _client.get(url);

    if (response.statusCode != 200) {
      throw Exception('Directions API hatası: ${response.statusCode}');
    }

    final data = json.decode(response.body);

    if (data['status'] != 'OK') {
      throw Exception('Directions API hatası: ${data['status']}');
    }

    final route = data['routes'][0];
    final legs = route['legs'] as List;

    // Toplam süre hesapla
    int totalDuration = 0;
    for (final leg in legs) {
      totalDuration += (leg['duration']['value'] as int);
    }

    // Waypoint sıralama
    final waypointOrder =
        List<int>.from(route['waypoint_order'] ?? []);

    // Optimize edilmiş durakları sırala
    final optimizedWaypoints = <KonumModel>[];
    for (final index in waypointOrder) {
      if (index < duraklar.length) {
        optimizedWaypoints.add(duraklar[index]);
      }
    }

    return DirectionsResult(
      optimizedWaypoints: optimizedWaypoints,
      totalDurationMinutes: (totalDuration / 60).ceil(),
      encodedPolyline: route['overview_polyline']['points'] ?? '',
      waypointOrder: waypointOrder,
    );
  }

  /// İki nokta arası tahmini süre hesapla
  Future<int> sureTahmini({
    required KonumModel baslangic,
    required KonumModel bitis,
  }) async {
    final url = Uri.parse(
      '${AppConstants.directionsBaseUrl}'
      '?origin=${baslangic.lat},${baslangic.lng}'
      '&destination=${bitis.lat},${bitis.lng}'
      '&key=${ApiKeys.googleMapsApiKey}'
      '&language=tr',
    );

    final response = await _client.get(url);

    if (response.statusCode != 200) {
      throw Exception('Directions API hatası: ${response.statusCode}');
    }

    final data = json.decode(response.body);

    if (data['status'] != 'OK') {
      throw Exception('Directions API hatası: ${data['status']}');
    }

    final durationSeconds =
        data['routes'][0]['legs'][0]['duration']['value'] as int;
    return (durationSeconds / 60).ceil();
  }

  void dispose() {
    _client.close();
  }
}
