import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  LatLng? _currentLocation;
  LatLng? _destination;
  bool _isJourneyStarted = false;
  final Set<Marker> _markers = {};
  final Set<Polyline> _routes = {};
  final TextEditingController _destinationController = TextEditingController();
  late io.Socket socket;

  @override
  void initState() {
    super.initState();
    _setupSocketConnection();
    _determineCurrentLocation();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  // Set up WebSocket connection
  void _setupSocketConnection() {
    socket = io.io('http://your-backend-url.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print('Connected to WebSocket');
    });

    socket.on('elephant_locations', (data) {
      _updateElephantMarkers(data);
    });

    socket.onDisconnect((_) {
      print('Disconnected from WebSocket');
    });
  }

  // Get user's current location
  Future<void> _determineCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _markers.add(
        Marker(
          markerId: MarkerId("currentLocation"),
          position: _currentLocation!,
          infoWindow: InfoWindow(title: "You Are Here"),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    });
    _fetchNearbyElephants();
  }

  // Fetch nearby elephants from the backend
  Future<void> _fetchNearbyElephants() async {
    final response = await http.get(Uri.parse(
        'http://your-backend-url.com/elephants/nearby?latitude=${_currentLocation!.latitude}&longitude=${_currentLocation!.longitude}'));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      _updateElephantMarkers(data);
    }
  }

  // Start journey tracking
  void _startJourney() {
    setState(() {
      _isJourneyStarted = true;
    });

    Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _fetchNearbyElephants();
      checkForElephantsNearby();
    });
  }

  // Update elephant markers dynamically
  void _updateElephantMarkers(dynamic data) {
    setState(() {
      _markers.removeWhere(
          (marker) => marker.markerId.value.startsWith("elephant"));
      for (var elephant in data) {
        _markers.add(
          Marker(
            markerId: MarkerId("elephant_${elephant['id']}"),
            position: LatLng(elephant['latitude'], elephant['longitude']),
            infoWindow: InfoWindow(title: "Elephant Detected"),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }
    });
  }

  // Check if an elephant is within 500m
  void checkForElephantsNearby() {
    for (var marker in _markers) {
      if (marker.markerId.value.startsWith("elephant")) {
        double distance = Geolocator.distanceBetween(
              _currentLocation!.latitude,
              _currentLocation!.longitude,
              marker.position.latitude,
              marker.position.longitude,
            ) /
            1000; // Convert to km

        if (distance < 0.5) {
          _showAlert("Warning!",
              "Elephant detected ${distance.toStringAsFixed(2)} km away!");
        }
      }
    }
  }

  // Show alert dialog when an elephant is nearby
  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition:
                CameraPosition(target: LatLng(7.8731, 80.7718), zoom: 7.8),
            markers: _markers,
            polylines: _routes,
          ),
          Positioned(
            top: 40,
            left: 10,
            right: 10,
            child: Column(
              children: [
                TextField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    hintText: "Enter destination",
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                ElevatedButton(
                  onPressed: _startJourney,
                  child: Text("Start Journey"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
