import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:vibration/vibration.dart';

class LocationScreen extends StatefulWidget {
  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  late GoogleMapController mapController;
  LatLng? _currentLocation;
  LatLng? _destination;
  bool _isJourneyStarted = false;
  final Set<Marker> _markers = {};
  final Set<Polyline> _routes = {};
  final TextEditingController _destinationController = TextEditingController();
  late io.Socket socket;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _setupSocketConnection();
    _checkLocationPermissions();
  }

  @override
  void dispose() {
    socket.dispose();
    _positionStream?.cancel();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _checkLocationPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showAlert("Permission Denied", "Location access is required for tracking.");
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showAlert("Permission Denied", "Enable location access in device settings.");
      return;
    }
    _determineCurrentLocation();
  }

  Future<void> _determineCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _markers.add(
          Marker(
            markerId: MarkerId("currentLocation"),
            position: _currentLocation!,
            infoWindow: InfoWindow(title: "You Are Here"),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      });
      _fetchNearbyElephants();
    } catch (e) {
      _showAlert("Error", "Failed to get location: ${e.toString()}");
    }
  }

  void _setupSocketConnection() {
    socket = io.io('http://your-backend-url.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) => print('Connected to WebSocket'));
    socket.on('elephant_locations', (data) => _updateElephantMarkers(data));
    socket.onDisconnect((_) => print('Disconnected from WebSocket'));
  }

  Future<void> _fetchNearbyElephants() async {
    if (_currentLocation == null) return;

    try {
      final response = await http.get(Uri.parse(
          'http://your-backend-url.com/elephants/nearby?latitude=${_currentLocation!.latitude}&longitude=${_currentLocation!.longitude}'));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        _updateElephantMarkers(data);
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Network error: $e");
    }
  }

  void _updateElephantMarkers(dynamic data) {
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value.startsWith("elephant"));
      for (var elephant in data) {
        _markers.add(
          Marker(
            markerId: MarkerId("elephant_${elephant['id']}"),
            position: LatLng(elephant['latitude'], elephant['longitude']),
            infoWindow: InfoWindow(title: "Elephant ${elephant['id']}"),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }
    });
  }

  void _startJourney() {
    setState(() {
      _isJourneyStarted = true;
    });

    Geolocator.getPositionStream(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _markers.removeWhere((marker) => marker.markerId.value == "currentLocation");
        _markers.add(
          Marker(
            markerId: MarkerId("currentLocation"),
            position: _currentLocation!,
            infoWindow: InfoWindow(title: "You Are Here"),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      });

      _fetchNearbyElephants();
      _animateCameraToPosition(_currentLocation!);
      _checkForElephantsNearby();
    });
  }

  void _animateCameraToPosition(LatLng position) {
    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(position, 15),
    );
  }

  void _checkForElephantsNearby() {
    for (var marker in _markers) {
      if (marker.markerId.value.startsWith("elephant")) {
        double distance = Geolocator.distanceBetween(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          marker.position.latitude,
          marker.position.longitude,
        ) / 1000;

        if (distance < 0.5) {
          _showAlert("Warning!", "Elephant detected ${distance.toStringAsFixed(2)} km away!");

          Vibration.vibrate(duration: 500);
        }
      }
    }
  }

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
            initialCameraPosition: CameraPosition(target: LatLng(7.8731, 80.7718), zoom: 7.8),
            markers: _markers,
            polylines: _routes,
          ),
          Positioned(
            top: 40,
            left: 10,
            right: 10,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
              child: TextField(
                controller: _destinationController,
                textAlignVertical: TextAlignVertical.center, 
                decoration: InputDecoration(
                  hintText: "Enter destination",
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.location_on, color: Colors.red),
                  contentPadding: EdgeInsets.symmetric(vertical: 15), 
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          FloatingActionButton(
            heroTag: "recenter",
            onPressed: () => _animateCameraToPosition(_currentLocation!),
            backgroundColor: Colors.white,
            child: Icon(Icons.my_location, color: Colors.blue),
          ),
          SizedBox(height: 10),
          Align(
            alignment: Alignment.bottomLeft, 
            child: FloatingActionButton.extended(
              heroTag: "startJourney",
              onPressed: _startJourney,
              label: Text("Start Journey", style: TextStyle(color: Colors.white)),
              icon: Icon(Icons.directions, color: Colors.white),
              backgroundColor: Colors.teal,
              elevation: 6,
            ),
          ),
        ],
      ),
    );
  }
}
