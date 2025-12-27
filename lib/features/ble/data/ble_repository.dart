import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet_tracker_model.dart';

class BleRepository {
  BleRepository(this._firestore);

  final FirebaseFirestore _firestore;

  /// Firestore: ble/{deviceId}
  Future<PetTrackerModel?> getPetDetails(String deviceId) async {
    final doc = await _firestore.collection('ble').doc(deviceId).get();

    if (!doc.exists) return null;

    return PetTrackerModel.fromDocument(doc);
  }
}
