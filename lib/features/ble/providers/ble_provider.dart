import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/ble_repository.dart';
import '../models/ble_device_model.dart';
import '../models/pet_tracker_model.dart';
import '../services/ble_service.dart';

/// --------------------
/// Service Providers
/// --------------------

final bleServiceProvider = Provider<BleService>((ref) {
  return BleService();
});

final bleRepositoryProvider = Provider<BleRepository>((ref) {
  return BleRepository(FirebaseFirestore.instance);
});

/// --------------------
/// Firestore Device Detail Provider
/// --------------------

final bleDeviceDetailsProvider =
FutureProvider.family<PetTrackerModel?, String>((ref, deviceId) async {
  final repo = ref.read(bleRepositoryProvider);
  return repo.getPetDetails(deviceId);
});

/// --------------------
/// BLE Scan Controller
/// --------------------

class BleScanController extends AsyncNotifier<List<BleDeviceModel>> {
  StreamSubscription<List<BleDeviceModel>>? _scanSubscription;
  bool _isScanning = false;

  @override
  Future<List<BleDeviceModel>> build() async {
    ref.onDispose(() async {
      await _scanSubscription?.cancel();
      _isScanning = false;
    });

    return const [];
  }

  Future<void> startScan() async {
    // 🔴 ANDROID RATE LIMIT KORUMASI
    if (_isScanning) return;

    _isScanning = true;

    try {
      final scanPermission = await Permission.bluetoothScan.request();
      final connectPermission =
      await Permission.bluetoothConnect.request();

      if (!scanPermission.isGranted || !connectPermission.isGranted) {
        _isScanning = false;
        state = AsyncError(
          'Bluetooth permissions are required.',
          StackTrace.current,
        );
        return;
      }

      final bleService = ref.read(bleServiceProvider);

      await bleService.startScan();
      state = const AsyncLoading();

      _scanSubscription = bleService.scanResults.listen(
            (devices) {
          state = AsyncData(devices);
        },
        onError: (e, st) {
          _isScanning = false;
          state = AsyncError(e, st);
        },
        onDone: () {
          // Scan timeout bittiğinde
          _isScanning = false;
        },
      );
    } catch (e, st) {
      _isScanning = false;
      state = AsyncError(e, st);
    }
  }

  Future<void> stopScan() async {
    if (!_isScanning) return;

    _isScanning = false;
    await _scanSubscription?.cancel();
    _scanSubscription = null;

    await ref.read(bleServiceProvider).stopScan();
  }
}

final bleScanControllerProvider =
AsyncNotifierProvider<BleScanController, List<BleDeviceModel>>(
  BleScanController.new,
);
