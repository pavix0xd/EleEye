import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'dart:ui' as ui;

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  static const LatLng _center = LatLng(7.9333296, 81.0);
  LatLng _cameraPosition = _center;

  final Set<Marker> _markers = {};
  List<LatLng> _routePoints = [];
  BitmapDescriptor? _customMarker;

  GoogleMapController? _mapController;
  final String _backendUrl = "http://localhost:5001/api/reports"; // backend endpoint

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    _fetchMarkersFromBackend(); // Fetch existing markers on startup
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
        },
        onCameraMove: (CameraPosition position) {
          _cameraPosition = position.target;
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
