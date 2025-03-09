import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;

  final LatLng _initialPosition = LatLng(7.8731, 80.7718); // Sri Lanka
  final Set<Marker> _markers = {}; // Set to store markers

  @override
  void initState() {
    super.initState();
    _addInitialMarker(); // Add initial marker when screen loads
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  // Function to add a marker at a given position
  void _addMarker(LatLng position) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(position.toString()),
          position: position,
          infoWindow: InfoWindow(
            title: "Custom Marker",
            snippet: "${position.latitude}, ${position.longitude}",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
  }

  // Function to add an initial marker at the default location
  void _addInitialMarker() {
    _markers.add(
      Marker(
        markerId: MarkerId("initialPosition"),
        position: _initialPosition,
        infoWindow: InfoWindow(title: "Sri Lanka", snippet: "Initial Marker"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Google Map with Markers')),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 7.0,
        ),
        markers: _markers,
        onTap: _addMarker, // Add marker when user taps on the map
      ),
    );
  }
}
