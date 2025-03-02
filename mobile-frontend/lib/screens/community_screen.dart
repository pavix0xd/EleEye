import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:geolocator/geolocator.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  LatLng _cameraPosition = const LatLng(6.8868, 79.9187);

  final Set<Marker> _markers = {};
  List<LatLng> _routePoints = [];
  BitmapDescriptor? _customMarker;
  GoogleMapController? _mapController;
  final String _backendUrl = "http://localhost:5001/api/reports"; // Backend endpoint

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    _fetchMarkersFromBackend();
    _getUserLocation(); // Fetch initial user location
  }

  /// Load custom marker image
  Future<void> _loadCustomMarker() async {
    final ByteData byteData = await rootBundle.load('assets/ele_marker.png');
    final Uint8List imageData = byteData.buffer.asUint8List();

    final ui.Codec codec =
        await ui.instantiateImageCodec(imageData, targetWidth: 100);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? byteDataConverted =
        await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);

    if (byteDataConverted != null) {
      setState(() {
        _customMarker =
            BitmapDescriptor.fromBytes(byteDataConverted.buffer.asUint8List());
      });
    }
  }

  /// Fetch markers from the backend
  Future<void> _fetchMarkersFromBackend() async {
    try {
      final response = await http.get(Uri.parse(_backendUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _markers.clear();
          for (var marker in data) {
            _markers.add(Marker(
              markerId: MarkerId(marker['id'].toString()),
              position: LatLng(marker['latitude'], marker['longitude']),
              icon: _customMarker ?? BitmapDescriptor.defaultMarker,
              onTap: () => _removeMarker(marker['id'].toString()),
            ));
          }
        });
      } else {
        print("Failed to load markers");
      }
    } catch (e) {
      print("Error fetching markers: $e");
    }
  }

  /// Fetch user's initial location and update the camera
  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      return;
    }

    // Request location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location permissions are denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Location permissions are permanently denied.");
      return;
    }

    // Get the current location
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    LatLng userLatLng = LatLng(position.latitude, position.longitude);

    setState(() {
      _cameraPosition = userLatLng;
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: userLatLng, zoom: 15.0),
      ),
    );
  }

  /// Track user's real-time movement and update the camera
  void _trackUserLocation() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update when user moves 10 meters
      ),
    ).listen((Position position) {
      LatLng newLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _cameraPosition = newLocation;
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newLocation, zoom: 15.0),
        ),
      );
    });
  }

  /// Send new marker to backend
  Future<void> _sendMarkerToBackend(LatLng position) async {
    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "latitude": position.latitude,
          "longitude": position.longitude,
        }),
      );

      if (response.statusCode == 201) {
        print("Marker saved successfully!");
      } else {
        print("Failed to save marker");
      }
    } catch (e) {
      print("Error sending marker: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
          return Scaffold(
            appBar: AppBar(
        title: const Text(
          "See a Big guy?  Tap where you saw it",
          style: TextStyle(
            fontSize: 20
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/ele_marker.png',
            ),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition:
            CameraPosition(target: _cameraPosition, zoom: 15.0),
        markers: _markers,
        polylines: {
          if (_routePoints.isNotEmpty)
            Polyline(
              polylineId: const PolylineId("route"),
              color: Colors.blue,
              width: 5,
              points: _routePoints,
            ),
        },
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
          _getUserLocation(); // Fetch initial location
          _trackUserLocation(); // Start tracking movement
        },
        onCameraMove: (CameraPosition position) {
          _cameraPosition = position.target;
        },
        onTap: _addMarker,
        myLocationEnabled: true, // Enable user's real-time location (blue dot)
        myLocationButtonEnabled: true, // Show location button
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: _fetchMarkersFromBackend, // Reload markers from backend
      ),
    );
  }

  /// Adds a marker when the user taps on the map and sends to backend
  void _addMarker(LatLng position) {
    final String markerId = position.toString();

    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(markerId),
          position: position,
          icon: _customMarker ?? BitmapDescriptor.defaultMarker,
          onTap: () {
            _removeMarker(markerId);
          },
        ),
      );
    });

    _sendMarkerToBackend(position); // Send marker to backend
  }

  /// Removes a marker when tapped
  void _removeMarker(String markerId) {
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == markerId);
      _routePoints.clear();
    });
  }
}
