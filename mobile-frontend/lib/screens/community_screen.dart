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
  final String _backendUrl = "http://10.0.2.2:5001/api/reports"; // Backend endpoint

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    _fetchMarkersFromBackend();
    _getUserLocation(); // Fetch initial user location
    _trackUserLocation(); // Start tracking user movement
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
 if (_customMarker == null) {
   await _loadCustomMarker(); // Ensure custom marker is loaded first
 }
 
 try {
   final response = await http.get(Uri.parse(_backendUrl));
 
   if (response.statusCode == 200) {
     final Map<String, dynamic> decoded = json.decode(response.body);
     final List<dynamic> data = decoded["reports"];
 
     setState(() {
       _markers.clear();
       for (var marker in data) {
         _markers.add(Marker(
           markerId: MarkerId(marker['id'].toString()),
           position: LatLng(marker['latitude'], marker['longitude']),
           icon: _customMarker ?? BitmapDescriptor.defaultMarker, // Always use custom marker
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

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      return;
    }

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

    catch (e) {
      print("Error getting user location: $e");
    }
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
 
     if (responseData.containsKey('report') && responseData['report'].isNotEmpty) {
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
       _fetchMarkersFromBackend(); // Refresh markers after adding
     } else {
       print("Unexpected response format: $responseData");
     }
   } else {
     print("Failed to save marker");
   }
 } catch (e) {
   print("Error sending marker: $e");
 }
}


  /// Removes a marker when tapped
  void _removeMarker(String markerId) async {
    try {
      final response = await http.delete(
        Uri.parse("$_backendUrl/$markerId"),
      );

      if (response.statusCode == 200) {
        setState(() {
          _markers.removeWhere((marker) => marker.markerId.value == markerId);
        });

        print("Marker deleted successfully");
        _fetchMarkersFromBackend(); // Refresh markers after deletion
      } else {
        print("Failed to delete marker");
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
            child: Image.asset(
              'assets/ele_marker.png',
            ),
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
        onPressed: _fetchMarkersFromBackend, // Reload markers from backend
      ),
    );
  }

  /// Adds a marker when the user taps on the map and sends to backend
  void _addMarker(LatLng position) {
    _sendMarkerToBackend(position);
  }
}
