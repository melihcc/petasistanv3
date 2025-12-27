import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class PetTrackerModel extends Equatable {
  final String deviceId;
  final String petName;
  final String petType;
  final String ownerUid;
  final String notes;
  final DateTime? updatedAt;

  const PetTrackerModel({
    required this.deviceId,
    required this.petName,
    required this.petType,
    required this.ownerUid,
    required this.notes,
    this.updatedAt,
  });

  factory PetTrackerModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Document data is null');

    return PetTrackerModel(
      deviceId: doc.id, // ✅ ble/{deviceId} için doğru eşleşme
      petName: data['petName'] ?? '',
      petType: data['petType'] ?? '',
      ownerUid: data['ownerUid'] ?? '',
      notes: data['notes'] ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  List<Object?> get props => [deviceId, petName, petType, ownerUid, notes, updatedAt];
}
