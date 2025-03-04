import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // For opening Google Maps

class LocationScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<LocationScreen> {
  late GoogleMapController mapController;

  final LatLng _initialPosition = LatLng(7.8731, 80.7718); // Sri Lanka
  final Set<Marker> _markers = {}; // Markers for elephants & locations
  final List<LatLng> _elephantLocations = [
    LatLng(8.03300357030694, 80.75161888210204),
  ];

  @override
  void initState() {
    super.initState();
    _addElephantMarkers();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _addElephantMarkers() {
    setState(() {
      for (var loc in _elephantLocations) {
        _markers.add(
          Marker(
            markerId: MarkerId(loc.toString()),
            position: loc,
            infoWindow: InfoWindow(
              title: "Elephant Detected",
              snippet: "${loc.latitude}, ${loc.longitude}",
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      }
    });
  }

  // Function to open Google Maps with the current location
  void _openGoogleMaps() async {
    String googleUrl = "https://www.google.com/maps/search/?api=1&query=${_initialPosition.latitude},${_initialPosition.longitude}";
    if (await canLaunch(googleUrl)) {
      await launch(googleUrl);
    } else {
      throw 'Could not open Google Maps';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: Text('EleEYE Map')),
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
}