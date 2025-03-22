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
  BitmapDescriptor? _customMarker;
  GoogleMapController? _mapController;
  final String _backendUrl = "http://34.28.6.57:5001/api/reports"; // Backend URL

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  /// Initialize loading marker and fetching data
  Future<void> _initialize() async {
    await _loadCustomMarker();
    await _fetchMarkersFromBackend();
    _getUserLocation();
    _trackUserLocation();
  }

  /// Load custom marker image
  Future<void> _loadCustomMarker() async {
    try {
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
    } catch (e) {
      print("Error loading custom marker: $e");
    }
  }

  /// Fetch markers from the backend
  Future<void> _fetchMarkersFromBackend() async {
    try {
      final response = await http.get(Uri.parse(_backendUrl));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey("reports")) {
          final List<dynamic> data = decoded["reports"];

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
          print("Unexpected response format: $decoded");
        }
      } else {
        print("Failed to load markers: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error fetching markers: $e");
    }
  }

  /// Fetch user's initial location and update the camera
  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
     

      LocationPermission permission = await Geolocator.checkPermission();
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
    } catch (e) {
      print("Error getting user location: $e");
    }
  }

  /// Track user's real-time movement and update the camera
  void _trackUserLocation() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
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
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData.containsKey('report') &&
            responseData['report'] is List &&
            responseData['report'].isNotEmpty) {
          final newMarkerId = responseData['report'][0]['id'];

          setState(() {
            _markers.add(Marker(
              markerId: MarkerId(newMarkerId.toString()),
              position: position,
              icon: _customMarker ?? BitmapDescriptor.defaultMarker,
              onTap: () => _removeMarker(newMarkerId.toString()),
            ));
          });

          print("Marker saved successfully with ID: $newMarkerId");
          _fetchMarkersFromBackend();
        } else {
          print("Unexpected response format: $responseData");
        }
      } else {
        print("Failed to save marker: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error sending marker: $e");
    }
  }

  /// Removes a marker when tapped
  void _removeMarker(String markerId) async {
    try {
      final response = await http.delete(Uri.parse("$_backendUrl/$markerId"));

      if (response.statusCode == 200) {
        setState(() {
          _markers.removeWhere((marker) => marker.markerId.value == markerId);
        });

        print("Marker deleted successfully");
        _fetchMarkersFromBackend();
      } else {
        print("Failed to delete marker: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error deleting marker: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "See a elephant? Tap where you saw it",
          style: TextStyle(fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/ele_marker.png'),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition:
            CameraPosition(target: _cameraPosition, zoom: 14.0),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        onTap: _addMarker,
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: _fetchMarkersFromBackend,
      ),
    );
  }

  /// Adds a marker when the user taps on the map and sends it to the backend
  void _addMarker(LatLng position) {
    _sendMarkerToBackend(position);
  }
}
