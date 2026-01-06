import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:unosfa/pages/services/api_service.dart';

class NavigationService {
  static const String apiKey =
      '5b3ce3597851110001cf6248b81d893bae354ba5811ad741987e9686';

  // Fetch route from OpenRouteService API
  static Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    final url =
        'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}';

    final response = await ApiService.getWithsingleHeaders(url);
    if (response != null) {
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coordinates = data['routes'][0]['geometry']['coordinates'];

        return coordinates
            .map<LatLng>((point) => LatLng(point[1], point[0]))
            .toList();
      } else {
        throw Exception('Failed to load route');
      }
    } else {
      throw Exception('API call returned null response');
    }
  }
}
