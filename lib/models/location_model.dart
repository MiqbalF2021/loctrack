import 'package:latlong2/latlong.dart';

class LocationModel {
  final LatLng position;
  final DateTime timestamp;

  LocationModel({
    required this.position,
    required this.timestamp,
  });

  // Convert to Map for storage
  Map<String, dynamic> toJson() {
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  // Create from Map for retrieval
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      position: LatLng(
        json['latitude'] as double,
        json['longitude'] as double,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    );
  }
}

class TrackingSession {
  final String id;
  final DateTime date;
  final List<LocationModel> locations;

  TrackingSession({
    required this.id,
    required this.date,
    required this.locations,
  });

  // Convert to Map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'locations': locations.map((location) => location.toJson()).toList(),
    };
  }

  // Create from Map for retrieval
  factory TrackingSession.fromJson(Map<String, dynamic> json) {
    return TrackingSession(
      id: json['id'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      locations: (json['locations'] as List)
          .map((locationJson) => LocationModel.fromJson(locationJson as Map<String, dynamic>))
          .toList(),
    );
  }
}