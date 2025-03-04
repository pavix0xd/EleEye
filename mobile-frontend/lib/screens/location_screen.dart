import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:web_socket_channel/io.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationScreen extends StatefulWidget {
  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  late GoogleMapController mapController;
  final LatLng _initialPosition = LatLng(7.8731, 80.7718); // Sri Lanka
  final Set<Marker> _markers = {}; // Store elephant locations dynamically
  late IOWebSocketChannel _channel;

  @override
  void initState() {
    super.initState();
    _initWebSocket();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  // Initialize WebSocket to get real-time elephant locations
  void _initWebSocket() {
    _channel = IOWebSocketChannel.connect("ws://your-backend-server/ws");
    _channel.stream.listen((message) {
      final data = jsonDecode(message);
      final double lat = data['latitude'];
      final double lng = data['longitude'];
      final LatLng location = LatLng(lat, lng);

      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId(location.toString()),
            position: location,
            infoWindow: InfoWindow(
              title: "Elephant Detected",
              snippet: "${lat}, ${lng}",
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      });
    });
  }

  // Open Google Maps with the user's location
  void _openGoogleMaps() async {
    String googleUrl =
        "https://www.google.com/maps/search/?api=1&query=${_initialPosition.latitude},${_initialPosition.longitude}";
    if (await canLaunch(googleUrl)) {
      await launch(googleUrl);
    } else {
      throw 'Could not open Google Maps';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 7.8,
            ),
            markers: _markers,
          ),
          Positioned(
            bottom: 35.0,
            left: MediaQuery.of(context).size.width * 0.25, // Centering the button
            child: ElevatedButton.icon(
              onPressed: _openGoogleMaps,
              icon: Icon(Icons.map),
              label: Text("Open Google Maps"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }
}