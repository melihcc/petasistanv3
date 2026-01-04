import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/osm_poi.dart';

class OverpassService {
  static const String _endpoint = 'https://overpass-api.de/api/interpreter';

  Future<List<OsmPoi>> fetchPoisByCenterRadius({
    required LatLng center,
    required int radiusMeters,
    required bool vets,
    required bool petShops,
    required bool shelters,
  }) async {
    if (!vets && !petShops && !shelters) return [];

    final lat = center.latitude;
    final lng = center.longitude;

    final parts = <String>[];

    if (vets) {
      parts.add('node["amenity"="veterinary"](around:$radiusMeters,$lat,$lng);');
      parts.add('way["amenity"="veterinary"](around:$radiusMeters,$lat,$lng);');
      parts.add('relation["amenity"="veterinary"](around:$radiusMeters,$lat,$lng);');
    }
    if (petShops) {
      parts.add('node["shop"="pet"](around:$radiusMeters,$lat,$lng);');
      parts.add('way["shop"="pet"](around:$radiusMeters,$lat,$lng);');
      parts.add('relation["shop"="pet"](around:$radiusMeters,$lat,$lng);');
    }
    if (shelters) {
      parts.add('node["amenity"="animal_shelter"](around:$radiusMeters,$lat,$lng);');
      parts.add('way["amenity"="animal_shelter"](around:$radiusMeters,$lat,$lng);');
      parts.add('relation["amenity"="animal_shelter"](around:$radiusMeters,$lat,$lng);');
    }

    final query = '''
[out:json][timeout:20];
(
  ${parts.join('\n')}
);
out center tags;
''';

    final resp = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
      },
      body: {'data': query},
    );

    if (resp.statusCode != 200) {
      throw Exception('Overpass HTTP ${resp.statusCode}');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final elements = (body['elements'] as List).cast<Map<String, dynamic>>();

    final pois = <OsmPoi>[];

    for (final el in elements) {
      final tags = (el['tags'] as Map?)?.cast<String, dynamic>() ?? {};

      PoiType? type;
      if (tags['amenity'] == 'veterinary') type = PoiType.vet;
      if (tags['shop'] == 'pet') type = PoiType.petShop;
      if (tags['amenity'] == 'animal_shelter') type = PoiType.shelter;
      if (type == null) continue;

      double? lat = (el['lat'] as num?)?.toDouble();
      double? lon = (el['lon'] as num?)?.toDouble();
      if (lat == null || lon == null) {
        final center = el['center'] as Map<String, dynamic>?;
        lat = (center?['lat'] as num?)?.toDouble();
        lon = (center?['lon'] as num?)?.toDouble();
      }
      if (lat == null || lon == null) continue;

      final nameRaw = (tags['name'] as String?)?.trim();
      final name = (nameRaw == null || nameRaw.isEmpty) ? '(İsimsiz)' : nameRaw;

      pois.add(
        OsmPoi(
          id: '${el['type']}:${el['id']}',
          type: type,
          name: name,
          position: LatLng(lat, lon),
        ),
      );
    }

    return pois;
  }
}
