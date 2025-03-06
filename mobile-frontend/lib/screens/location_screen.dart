import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<LocationScreen> {
  late GoogleMapController mapController;
  LatLng? _currentLocation;
  LatLng? _destination;
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

  // Update elephant markers dynamically
  void _updateElephantMarkers(dynamic data) {
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value.startsWith("elephant"));
      for (var elephant in data) {
        _markers.add(
          Marker(
            markerId: MarkerId("elephant_${elephant['id']}"),
            position: LatLng(elephant['latitude'], elephant['longitude']),
            infoWindow: InfoWindow(title: "Elephant Detected"),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }
    });
  }

  // Get user's current location
  Future<void> _determineCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return;
    }

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
  }

  // Search for a destination and set marker
  void _searchDestination() async {
    String place = _destinationController.text;
    final response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=$place&key=YOUR_GOOGLE_MAPS_API_KEY'));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      var location = data['results'][0]['geometry']['location'];
      LatLng destinationLatLng = LatLng(location['lat'], location['lng']);

      setState(() {
        _destination = destinationLatLng;
        _markers.add(
          Marker(
            markerId: MarkerId("destination"),
            position: _destination!,
            infoWindow: InfoWindow(title: "Destination"),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });

      _drawRoute();
    }
  }

  // Draw route from current location to destination
  Future<void> _drawRoute() async {
    if (_currentLocation == null || _destination == null) return;

    final response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=${_currentLocation!.latitude},${_currentLocation!.longitude}&destination=${_destination!.latitude},${_destination!.longitude}&key=YOUR_GOOGLE_MAPS_API_KEY'));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      var points = data['routes'][0]['overview_polyline']['points'];
      List<LatLng> polylineCoords = _decodePolyline(points);

      setState(() {
        _routes.clear();
        _routes.add(Polyline(
          polylineId: PolylineId("route"),
          points: polylineCoords,
          color: Colors.blue,
          width: 5,
        ));
      });

      checkForElephantsNearby();
    }
  }

  // Decode polyline points
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  // Check if an elephant is within 500m of the route
  void checkForElephantsNearby() {
    for (var marker in _markers) {
      if (marker.markerId.value.startsWith("elephant")) {
        double distance = Geolocator.distanceBetween(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          marker.position.latitude,
          marker.position.longitude,
        ) / 1000; // Convert to km

        if (distance < 0.5) {
          _showAlert("Warning!", "Elephant detected $distance km away!");
        }
      }
    }
  }

  // Show alert dialog
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
            child: TextField(
              controller: _destinationController,
              decoration: InputDecoration(
                hintText: "Enter destination",
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) => _searchDestination(),
            ),
          ),
        ],
      ),
    );
  }
}