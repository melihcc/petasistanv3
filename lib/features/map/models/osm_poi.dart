import 'package:google_maps_flutter/google_maps_flutter.dart';

enum PoiType { vet, petShop, shelter }

class OsmPoi {
  final String id; // node:123 / way:456 ...
  final PoiType type;
  final String name;
  final LatLng position;

  const OsmPoi({
    required this.id,
    required this.type,
    required this.name,
    required this.position,
  });
}
