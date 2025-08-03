import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/location_provider.dart';
import '../widgets/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Add dummy location updates every 5 seconds for demo purposes
    _startDummyLocationUpdates();
  }

  void _startDummyLocationUpdates() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        final provider = Provider.of<LocationProvider>(context, listen: false);
        if (provider.isTracking) {
          provider.addDummyLocation();
        }
        _startDummyLocationUpdates(); // Schedule next update
      }
    });
  }

  void _toggleTracking() {
    final provider = Provider.of<LocationProvider>(context, listen: false);
    if (provider.isTracking) {
      provider.stopTracking();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tracking stopped',
            style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.redAccent.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      provider.startTracking();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tracking started',
            style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.greenAccent.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            'LOCTRACK',
            style: GoogleFonts.pressStart2p(color: Colors.white, fontSize: 16),
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, _) {
          final currentLocation = locationProvider.currentLocation;

          return Stack(
            children: [
              // Full screen map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: currentLocation,
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.loctrack',
                  ),
                  // Current location marker
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 60.0,
                        height: 60.0,
                        point: currentLocation,
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
                  // Path layer if tracking
                  if (locationProvider.isTracking &&
                      locationProvider.currentSession != null &&
                      locationProvider.currentSession!.locations.length > 1)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: locationProvider.currentSession!.locations
                              .map((loc) => loc.position)
                              .toList(),
                          color: const Color(0xFF9C27B0),
                          strokeWidth: 4.0,
                          isDotted: true,
                        ),
                      ],
                    ),
                ],
              ),
              // Status panel
              Positioned(
                top: 100,
                left: 16,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: GoogleFonts.spaceMono(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: locationProvider.isTracking
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            locationProvider.isTracking
                                ? 'Tracking Active'
                                : 'Tracking Inactive',
                            style: GoogleFonts.spaceMono(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      if (locationProvider.isTracking &&
                          locationProvider.currentSession != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Points: ${locationProvider.currentSession!.locations.length}',
                            style: GoogleFonts.spaceMono(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Control buttons
              Positioned(
                right: 16,
                bottom: 100,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Center button
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: FloatingActionButton(
                        onPressed: () {
                          _mapController.move(currentLocation, 15.0);
                        },
                        heroTag: 'centerButton',
                        backgroundColor: Colors.white.withOpacity(0.8),
                        foregroundColor: Colors.blueAccent,
                        elevation: 0,
                        mini: true,
                        child: const Icon(Icons.my_location),
                      ),
                    ),
                    // Tracking button
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: locationProvider.isTracking
                              ? [Colors.redAccent, Colors.orangeAccent]
                              : [Colors.greenAccent, Colors.tealAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: FloatingActionButton(
                        onPressed: _toggleTracking,
                        heroTag: 'trackingButton',
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        child: Icon(
                          locationProvider.isTracking
                              ? Icons.stop
                              : Icons.play_arrow,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}
