import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Position?> currentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return null;
    return Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
  }

  Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    );
  }

  Future<void> updateRiderLocation(String riderId, double lat, double lng) =>
      _db.collection('rider_locations').doc(riderId).set({
        'lat': lat, 'lng': lng, 'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchRiderLocation(String riderId) =>
      _db.collection('rider_locations').doc(riderId).snapshots();
}
