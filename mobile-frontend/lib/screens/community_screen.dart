import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:vibration/vibration.dart';

class CommunityScreen extends StatefulWidget {
  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<CommunityScreen> {
  late GoogleMapController mapController;
  LatLng? _currentLocation;
  LatLng? _destination;
  bool _isJourneyStarted = false;
  final Set<Marker> _markers = {};
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
        _showAlert("Permission Denied", "Location access is required.");
        return;
      }
    }

    void _checkForElephantsNearby() {
      if (_currentLocation == null) return;

      for (var marker in _markers) {
        if (marker.markerId.value.startsWith("elephant")) {
          double distance = Geolocator.distanceBetween(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
            marker.position.latitude,
            marker.position.longitude,
          );

          if (distance < 100) {
            Vibration.vibrate();
            _showAlert("Warning", "An elephant is nearby!");
            break;
          }
        }
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showAlert("Permission Denied", "Enable location access in settings.");
      return;
    }
    _determineCurrentLocation();
  }

  Future<void> _determineCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _updateCurrentLocationMarker();
      });
      _fetchNearbyElephants();
    } catch (e) {
      _showAlert("Error", "Failed to get location: ${e.toString()}");
    }
  }

  void _updateCurrentLocationMarker() {
    if (_currentLocation == null) return;
    setState(() {
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
  }

  void _setupSocketConnection() {
    socket = io.io('http://10.0.2.2:5003', <String, dynamic>{
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
          'http://10.0.2.2:5003/elephants/nearby?latitude=${_currentLocation!.latitude}&longitude=${_currentLocation!.longitude}'));

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

  void _startJourney() async {
    if (_currentLocation == null) {
      await _determineCurrentLocation(); // Ensure location is fetched before starting
    }

    setState(() {
      _isJourneyStarted = true;
    });

    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _updateCurrentLocationMarker();
      });

      _fetchNearbyElephants();
      _animateCameraToPosition(_currentLocation!);
    });
  }

  Future<void> _searchLocation() async {
    String destination = _destinationController.text;
    if (destination.isEmpty) {
      _showAlert("Error", "Enter a destination");
      return;
    }

    try {
      final response = await http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?address=$destination&key=YOUR_GOOGLE_MAPS_API_KEY'));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['results'].isNotEmpty) {
          double lat = data['results'][0]['geometry']['location']['lat'];
          double lng = data['results'][0]['geometry']['location']['lng'];

          setState(() {
            _destination = LatLng(lat, lng);
            _markers.add(
              Marker(
                markerId: MarkerId("destination"),
                position: _destination!,
                infoWindow: InfoWindow(title: "Destination"),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              ),
            );
            _animateCameraToPosition(_destination!);
          });
        }
      }
    } catch (e) {
      _showAlert("Error", "Failed to find location");
    }
  }

  void _animateCameraToPosition(LatLng position) {
    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(position, 15),
    );
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
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: TextField(
                controller: _destinationController,
                decoration: InputDecoration(
                  hintText: "Enter destination",
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.blue),
                ),
                onSubmitted: (_) => _searchLocation(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startJourney,
        label: Text("Start Journey"),
        icon: Icon(Icons.directions),
        backgroundColor: Colors.teal,
      ),
    );
  }
}