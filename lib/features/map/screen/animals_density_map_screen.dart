import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart'
    hide Cluster, ClusterManager;

import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart'
as cm;

import '../models/animal.dart';
import '../models/osm_poi.dart';
import '../services/overpass_service.dart';
import '../utils/bubble_marker.dart';

class AnimalsDensityMapScreen extends StatefulWidget {
  const AnimalsDensityMapScreen({super.key});

  @override
  State<AnimalsDensityMapScreen> createState() =>
      _AnimalsDensityMapScreenState();
}

class _AnimalsDensityMapScreenState
    extends State<AnimalsDensityMapScreen> {
  GoogleMapController? _mapController;

  /// Kamera state (⚠️ getCameraPosition YOK → burası şart)
  CameraPosition? _lastCameraPosition;

  /// Density (animals)
  late final cm.ClusterManager<Animal> _clusterManager;
  Set<Marker> _densityMarkers = {};

  /// POI
  Set<Marker> _poiMarkers = {};
  bool _showVets = false;
  bool _showPetShops = false;
  bool _showShelters = false;

  bool get _poiFiltersOn =>
      _showVets || _showPetShops || _showShelters;

  final OverpassService _overpass = OverpassService();

  /// Performans kontrolleri
  Timer? _poiDebounce;
  bool _poiLoading = false;
  DateTime _lastPoiFetch =
  DateTime.fromMillisecondsSinceEpoch(0);
  final Set<String> _poiCacheKeys = {};

  static const LatLng _fallbackLocation =
  LatLng(41.015, 28.979);

  // ---------------------------------------------------------------------------
  // INIT
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _clusterManager = cm.ClusterManager<Animal>(
      <Animal>[],
          (markers) => setState(() => _densityMarkers = markers),
      markerBuilder: _densityMarkerBuilder,
    );

    _loadAnimals();
  }

  // ---------------------------------------------------------------------------
  // FIRESTORE – ANIMALS
  // ---------------------------------------------------------------------------

  Future<void> _loadAnimals() async {
    final snap =
    await FirebaseFirestore.instance.collection('animals').get();

    final animals = snap.docs.map((doc) {
      final gp = doc['location'] as GeoPoint;
      return Animal(
        id: doc.id,
        position: LatLng(gp.latitude, gp.longitude),
      );
    }).toList();

    _clusterManager.setItems(animals);
  }

  Future<Marker> _densityMarkerBuilder(
      cm.Cluster<Animal> cluster) async {
    final count = cluster.count;

    final int size = count < 5 ? 52 : count < 15 ? 86 : 125;
    final Color color =
    count < 5 ? Colors.orange : count < 15 ? Colors.deepOrange : Colors.red;

    final icon = await BubbleMarker.build(
      size: size,
      color: color,
      text: '$count',
    );

    return Marker(
      markerId: MarkerId('density_${cluster.getId()}'),
      position: cluster.location,
      icon: icon,
      onTap: () {
        if (cluster.isMultiple && _mapController != null) {
          _mapController!.animateCamera(CameraUpdate.zoomIn());
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // LOCATION
  // ---------------------------------------------------------------------------

  Future<void> _moveToUserLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(pos.latitude, pos.longitude),
        14,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CAMERA + POI LOGIC
  // ---------------------------------------------------------------------------

  void _onCameraMove(CameraPosition position) {
    _lastCameraPosition = position;
    _clusterManager.onCameraMove(position);
  }

  void _onCameraIdle() {
    _clusterManager.updateMap();

    _poiDebounce?.cancel();
    _poiDebounce =
        Timer(const Duration(milliseconds: 350), _refreshPois);
  }

  Future<void> _refreshPois() async {
    if (_mapController == null ||
        !_poiFiltersOn ||
        _poiLoading ||
        _lastCameraPosition == null) return;

    final now = DateTime.now();
    if (now.difference(_lastPoiFetch) <
        const Duration(milliseconds: 700)) return;

    final zoom = _lastCameraPosition!.zoom;
    final center = _lastCameraPosition!.target;

    final int radiusMeters = zoom >= 15
        ? 7000
        : zoom >= 13
        ? 5000
        : 3000;

    final cacheKey =
        'r$radiusMeters-${center.latitude.toStringAsFixed(3)},'
        '${center.longitude.toStringAsFixed(3)}-'
        'v$_showVets-p$_showPetShops-s$_showShelters';

    if (_poiCacheKeys.contains(cacheKey)) return;

    _poiLoading = true;
    _lastPoiFetch = now;

    try {
      final pois = await _overpass.fetchPoisByCenterRadius(
        center: center,
        radiusMeters: radiusMeters,
        vets: _showVets,
        petShops: _showPetShops,
        shelters: _showShelters,
      );

      final markers = <Marker>{};
      for (final p in pois) {
        markers.add(
          Marker(
            markerId: MarkerId('poi_${p.id}'),
            position: p.position,
            icon: _poiIcon(p.type),
            onTap: () => _openPoiActions(p),
          ),
        );
      }

      setState(() => _poiMarkers = markers);
      _poiCacheKeys.add(cacheKey);
    } finally {
      _poiLoading = false;
    }
  }

  // ---------------------------------------------------------------------------
  // POI UI
  // ---------------------------------------------------------------------------

  BitmapDescriptor _poiIcon(PoiType type) {
    switch (type) {
      case PoiType.vet:
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure);
      case PoiType.petShop:
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet);
      case PoiType.shelter:
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen);
    }
  }

  void _openPoiActions(OsmPoi p) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              p.name,
              style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Google Maps’te Aç'),
              onTap: () {
                Navigator.pop(context);
                launchUrl(
                  Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=${p.position.latitude},${p.position.longitude}'),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions),
              title: const Text('Yol Tarifi Al'),
              onTap: () {
                Navigator.pop(context);
                launchUrl(
                  Uri.parse(
                      'https://www.google.com/maps/dir/?api=1&destination=${p.position.latitude},${p.position.longitude}'),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FILTER UI
  // ---------------------------------------------------------------------------

  void _openFilter() {
    bool v = _showVets, p = _showPetShops, s = _showShelters;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Veterinerler (Mavi)'),
                value: v,
                onChanged: (x) => setM(() => v = x),
              ),
              SwitchListTile(
                title: const Text('Pet Mağazaları (Mor)'),
                value: p,
                onChanged: (x) => setM(() => p = x),
              ),
              SwitchListTile(
                title: const Text('Barınaklar (Yeşil)'),
                value: s,
                onChanged: (x) => setM(() => s = x),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _showVets = v;
                    _showPetShops = p;
                    _showShelters = s;
                  });
                  _poiCacheKeys.clear();
                  _refreshPois();
                },
                child: const Text('Uygula'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harita'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _openFilter,
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: _fallbackLocation,
          zoom: 11,
        ),
        markers: {..._densityMarkers, ..._poiMarkers},
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
        onMapCreated: (c) async {
          _mapController = c;
          _clusterManager.setMapId(c.mapId);
          await _moveToUserLocation();
        },
        onCameraMove: _onCameraMove,
        onCameraIdle: _onCameraIdle,
      ),
    );
  }
}
