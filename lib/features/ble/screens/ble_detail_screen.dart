import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ble_provider.dart';

class BleDetailScreen extends ConsumerWidget {
  final String deviceId;

  const BleDetailScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petDetailsAsync = ref.watch(bleDeviceDetailsProvider(deviceId));

    return Scaffold(
      appBar: AppBar(title: Text('Device: $deviceId')),
      body: petDetailsAsync.when(
        data: (pet) {
          if (pet == null) {
            return const Center(child: Text('Device not found in Firestore.'));
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  'Pet Name',
                  pet.petName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Pet Type', pet.petType),
                const Divider(),
                _buildDetailRow('Owner ID', pet.ownerUid),
                const SizedBox(height: 16),
                _buildDetailRow('Notes', pet.notes),
                if (pet.updatedAt != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Last Updated: ${pet.updatedAt}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error loading details: $err')),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {TextStyle? style}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        Text(value, style: style ?? const TextStyle(fontSize: 18)),
      ],
    );
  }
}
