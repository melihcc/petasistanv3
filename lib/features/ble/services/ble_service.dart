import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/ble_device_model.dart';

class BleService {
  final Map<String, BleDeviceModel> _deviceCache = {};

  Stream<List<BleDeviceModel>> get scanResults =>
      FlutterBluePlus.scanResults.map((results) {
        for (final r in results) {
          // Güvenli device name alma
          final name = r.advertisementData.advName.isNotEmpty
              ? r.advertisementData.advName
              : r.device.platformName;

          if (!name.startsWith('PetTracker')) continue;

          // Güvenli deviceId extraction
          final parts = name.split(RegExp(r'[-_]'));
          if (parts.length < 2) continue;

          final deviceId = parts.last;

          _deviceCache[deviceId] = BleDeviceModel(
            name: name,
            deviceId: deviceId,
            rssi: r.rssi,
            macAddress: r.device.remoteId.toString(),
          );
        }

        return _deviceCache.values.toList();
      });

  Future<void> startScan() async {
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      throw Exception('Bluetooth is turned off');
    }

    _deviceCache.clear();

    await FlutterBluePlus.stopScan();
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
    );
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }
}
