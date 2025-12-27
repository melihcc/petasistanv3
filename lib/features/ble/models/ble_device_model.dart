import 'package:equatable/equatable.dart';

class BleDeviceModel extends Equatable {
  final String name;
  final String deviceId;
  final int rssi;
  final String macAddress;

  const BleDeviceModel({
    required this.name,
    required this.deviceId,
    required this.rssi,
    required this.macAddress,
  });

  @override
  List<Object?> get props => [name, deviceId, rssi, macAddress];
}
