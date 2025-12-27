import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/ble_provider.dart';

class BleScanScreen extends ConsumerWidget {
  const BleScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(bleScanControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () {
              ref.read(bleScanControllerProvider.notifier).startScan();
            },
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: () {
              ref.read(bleScanControllerProvider.notifier).stopScan();
            },
          ),
        ],
      ),
      body: scanState.when(
        loading: () =>
        const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(err.toString(), textAlign: TextAlign.center),
        ),
        data: (devices) {
          if (devices.isEmpty) {
            return const Center(
              child: Text('No PetTracker devices found.'),
            );
          }

          return ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return ListTile(
                title: Text(device.name),
                subtitle:
                Text('ID: ${device.deviceId}  RSSI: ${device.rssi}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ref
                      .read(bleScanControllerProvider.notifier)
                      .stopScan();
                  context.go('/ble/${device.deviceId}');
                },
              );
            },
          );
        },
      ),
    );
  }
}
