import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:unosfa/pages/services/api_service.dart';
import 'package:unosfa/pages/services/secret_key.dart';

class NavigationService {
  static Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    final apiKey = await openrouteApiKey();
    final url =
        'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}';

    final response = await ApiService.getWithsingleHeaders(url);
    if (response != null) {
      if (response.statusCode == 200) {
        final data = jsonDecode(response.data.body);
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
