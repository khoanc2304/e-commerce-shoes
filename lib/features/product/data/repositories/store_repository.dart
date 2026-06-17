import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store_model.dart';

class StoreRepository {
  final FirebaseFirestore _firestore;

  StoreRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<StoreModel>> getStoresStream() {
    return _firestore.collection('stores').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => StoreModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> addStore(StoreModel store) async {
    final docRef = _firestore.collection('stores').doc();
    final newStore = StoreModel(
      id: docRef.id,
      name: store.name,
      address: store.address,
      latitude: store.latitude,
      longitude: store.longitude,
      phone: store.phone,
    );
    await docRef.set(newStore.toMap());
  }

  Future<void> updateStore(StoreModel store) async {
    await _firestore.collection('stores').doc(store.id).update(store.toMap());
  }

  Future<void> deleteStore(String id) async {
    await _firestore.collection('stores').doc(id).delete();
  }
}
