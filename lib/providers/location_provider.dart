import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';

class LocationProvider with ChangeNotifier {
  List<TrackingSession> _sessions = [];
  TrackingSession? _currentSession;
  bool _isTracking = false;
  List<LocationModel> _apiLocations = [];

  // Dummy location for Indonesia (Jakarta)
  final LatLng _defaultLocation = LatLng(-6.2088, 106.8456);
  
  // Getter for current location
  LatLng get currentLocation {
    if (_currentSession != null && _currentSession!.locations.isNotEmpty) {
      return _currentSession!.locations.last.position;
    }
    return _defaultLocation;
  }

  // Getters
  List<TrackingSession> get sessions => _sessions;
  TrackingSession? get currentSession => _currentSession;
  bool get isTracking => _isTracking;
  List<LocationModel> get apiLocations => _apiLocations;

  // Initialize provider and load saved sessions
  Future<void> initialize() async {
    await loadSessions();
  }

  // Start a new tracking session
  void startTracking() {
    if (!_isTracking) {
      _currentSession = TrackingSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        locations: [],
      );
      _isTracking = true;
      notifyListeners();
    }
  }

  // Add a location to the current session
  void addLocation(LatLng position) {
    if (_isTracking && _currentSession != null) {
      final location = LocationModel(
        position: position,
        timestamp: DateTime.now(),
      );
      _currentSession!.locations.add(location);
      notifyListeners();
    }
  }

  // Stop tracking and save the session
  Future<void> stopTracking() async {
    if (_isTracking && _currentSession != null) {
      if (_currentSession!.locations.isNotEmpty) {
        _sessions.add(_currentSession!);
        await saveSessions();
      }
      _currentSession = null;
      _isTracking = false;
      notifyListeners();
    }
  }

  // Save sessions to SharedPreferences
  Future<void> saveSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = _sessions.map((session) => session.toJson()).toList();
      await prefs.setString('tracking_sessions', jsonEncode(sessionsJson));
    } catch (e) {
      debugPrint('Error saving sessions: $e');
    }
  }

  // Load sessions from SharedPreferences
  Future<void> loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsString = prefs.getString('tracking_sessions');
      if (sessionsString != null) {
        final sessionsJson = jsonDecode(sessionsString) as List;
        _sessions = sessionsJson
            .map((sessionJson) => TrackingSession.fromJson(sessionJson as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading sessions: $e');
    }
  }

  // Add dummy location data for testing
  void addDummyLocation() {
    // Simulate movement by slightly changing coordinates
    final currentPos = currentLocation;
    final newLat = currentPos.latitude + (Random().nextDouble() - 0.5) * 0.001;
    final newLng = currentPos.longitude + (Random().nextDouble() - 0.5) * 0.001;
    addLocation(LatLng(newLat, newLng));
  }

  // Get sessions for a specific date
  List<TrackingSession> getSessionsByDate(DateTime date) {
    return _sessions.where((session) {
      return session.date.year == date.year &&
          session.date.month == date.month &&
          session.date.day == date.day;
    }).toList();
  }
  
  // Fetch location data from API
  Future<List<LocationModel>> fetchLocationsFromApi(String date) async {
    try {
      final response = await http.get(
        Uri.parse('http://103.250.11.233/locations/history?date=$date'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _apiLocations = data.map((item) => LocationModel(
          position: LatLng(
            double.parse(item['latitude']),
            double.parse(item['longitude']),
          ),
          timestamp: DateTime.parse(item['timestamp']),
        )).toList();
        notifyListeners();
        return _apiLocations;
      } else {
        debugPrint('Failed to load locations: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching locations: $e');
      return [];
    }
  }
}