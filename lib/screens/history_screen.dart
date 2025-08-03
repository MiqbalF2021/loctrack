import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/location_model.dart';
import '../providers/location_provider.dart';
import '../widgets/bottom_nav_bar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  TrackingSession? _selectedSession;
  final MapController _mapController = MapController();
  bool _isLoadingApi = false;
  bool _showApiData = false;
  List<LocationModel> _apiLocations = [];

  @override
  void initState() {
    super.initState();
    _loadApiData();
  }

  Future<void> _loadApiData() async {
    setState(() {
      _isLoadingApi = true;
    });
    
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    
    try {
      final locations = await locationProvider.fetchLocationsFromApi(formattedDate);
      setState(() {
        _apiLocations = locations;
        _isLoadingApi = false;
        
        // Center map on the latest location from API if available
        if (_showApiData && locations.isNotEmpty) {
          _mapController.move(locations.last.position, 15.0);
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingApi = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6A1B9A),
        title: Text(
          'Tracking History',
          style: GoogleFonts.pressStart2p(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          // Toggle API data button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _showApiData ? Colors.purpleAccent.withOpacity(0.3) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: Icon(
                _showApiData ? Icons.cloud_done : Icons.cloud,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _showApiData = !_showApiData;
                  if (_showApiData && _apiLocations.isEmpty) {
                    _loadApiData();
                  } else if (_showApiData && _apiLocations.isNotEmpty) {
                    // Center map on the latest location from API
                    _mapController.move(_apiLocations.last.position, 15.0);
                  }
                });
              },
            ),
          ),
          // Date picker button
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.purpleAccent.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.calendar_today,
                color: Colors.white,
              ),
              onPressed: () => _selectDate(context),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date display with retro style
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF6A1B9A), const Color(0xFF8E24AA)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
                    onPressed: () {
                      setState(() {
                        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                        _selectedSession = null;
                        _loadApiData();
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Text(
                      DateFormat('dd MMMM yyyy').format(_selectedDate),
                      style: GoogleFonts.spaceMono(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                    onPressed: () {
                      setState(() {
                        _selectedDate = _selectedDate.add(const Duration(days: 1));
                        _selectedSession = null;
                        _loadApiData();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          // API data status
          if (_isLoadingApi)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF6A1B9A),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Loading data...',
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFF6A1B9A),
                    ),
                  ),
                ],
              ),
            ),
          // Session list with glass effect
          if (!_showApiData)
            Consumer<LocationProvider>(
              builder: (context, locationProvider, _) {
                final sessions = locationProvider.getSessionsByDate(_selectedDate);
                
                if (sessions.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white70, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Text(
                        'No tracking sessions for this date',
                        style: GoogleFonts.spaceMono(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }
                
                return Container(
                  height: 120,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final isSelected = _selectedSession?.id == session.id;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSession = session;
                            _showApiData = false;
                            
                            // Center map on the first location of the session
                            if (session.locations.isNotEmpty) {
                              _mapController.move(
                                session.locations.first.position,
                                15.0,
                              );
                            }
                          });
                        },
                        child: Container(
                          width: 170,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isSelected
                                  ? [const Color(0xFF6A1B9A), const Color(0xFF8E24AA)]
                                  : [Colors.white.withOpacity(0.7), Colors.white.withOpacity(0.5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? Colors.purpleAccent : Colors.white70,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? Colors.white.withOpacity(0.3) 
                                        : const Color(0xFF6A1B9A).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    DateFormat('HH:mm').format(session.date),
                                    style: GoogleFonts.spaceMono(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : const Color(0xFF6A1B9A),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: isSelected ? Colors.white : const Color(0xFF6A1B9A),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${session.locations.length} points',
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 14,
                                        color: isSelected ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      size: 16,
                                      color: isSelected ? Colors.white : const Color(0xFF6A1B9A),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _calculateDuration(session),
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 14,
                                        color: isSelected ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          // API data info
          if (_showApiData)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.cloud_done,
                    color: Color(0xFF6A1B9A),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'API Data: ${_apiLocations.length} locations',
                    style: GoogleFonts.spaceMono(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6A1B9A),
                    ),
                  ),
                ],
              ),
            ),
          // Map view
          Expanded(
            child: Consumer<LocationProvider>(
              builder: (context, locationProvider, _) {
                // Default center on Indonesia if no session selected
                LatLng center = const LatLng(-6.2088, 106.8456);
                List<LatLng> points = [];
                
                if (_showApiData) {
                  // Use API data for points
                  points = _apiLocations.map((loc) => loc.position).toList();
                  if (points.isNotEmpty) {
                    // Use the latest location as center
                    center = points.last;
                  }
                } else if (_selectedSession != null && _selectedSession!.locations.isNotEmpty) {
                  // Use selected session data for points
                  points = _selectedSession!.locations.map((loc) => loc.position).toList();
                  center = points.first;
                }
                
                return Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: 15.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.loctrack',
                        ),
                        // Path polyline with retro style
                        if (points.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: points,
                                color: (_showApiData ? const Color(0xFF9C27B0) : const Color(0xFF6A1B9A)).withOpacity(0.8),
                                strokeWidth: 3.0,
                                isDotted: true,
                              ),
                            ],
                          ),
                        // Points as circle markers with retro style
                        if (points.isNotEmpty)
                          CircleLayer(
                            circles: points.map((point) => CircleMarker(
                              point: point,
                              color: (_showApiData ? const Color(0xFF9C27B0) : const Color(0xFF6A1B9A)).withOpacity(0.5),
                              borderColor: _showApiData ? const Color(0xFF9C27B0) : const Color(0xFF6A1B9A),
                              borderStrokeWidth: 1.5,
                              radius: 6.0,
                            )).toList(),
                          ),
                        // Start and end markers
                        if (points.isNotEmpty)
                          MarkerLayer(
                            markers: [
                              // Start marker
                              Marker(
                                width: 50.0,
                                height: 50.0,
                                point: points.first,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.trip_origin,
                                    color: Colors.green,
                                    size: 30.0,
                                  ),
                                ),
                              ),
                              // End marker
                              Marker(
                                width: 50.0,
                                height: 50.0,
                                point: points.last,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.redAccent,
                                    size: 40.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    // Map controls
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            FloatingActionButton.small(
                              onPressed: () {
                                _mapController.move(center, _mapController.camera.zoom + 1);
                              },
                              heroTag: 'zoomIn',
                              backgroundColor: const Color(0xFF6A1B9A),
                              child: const Icon(Icons.add, color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton.small(
                              onPressed: () {
                                _mapController.move(center, _mapController.camera.zoom - 1);
                              },
                              heroTag: 'zoomOut',
                              backgroundColor: const Color(0xFF6A1B9A),
                              child: const Icon(Icons.remove, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedSession = null;
        _loadApiData();
      });
    }
  }

  String _calculateDuration(TrackingSession session) {
    if (session.locations.length < 2) {
      return 'N/A';
    }
    
    final firstTimestamp = session.locations.first.timestamp;
    final lastTimestamp = session.locations.last.timestamp;
    final duration = lastTimestamp.difference(firstTimestamp);
    
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}