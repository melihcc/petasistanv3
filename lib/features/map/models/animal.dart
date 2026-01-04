import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart' as cm;

class Animal with cm.ClusterItem {
  final String id;
  final LatLng position;

  Animal({required this.id, required this.position});

  @override
  LatLng get location => position;
}
