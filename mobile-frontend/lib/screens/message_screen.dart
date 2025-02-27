import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MessageScreen extends StatefulWidget {
  const MessageScreen({Key? key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MessageScreen> {
  static const LatLng _center = LatLng(7.9333296, 81.0);

  LatLng? _currentLocation;
  LatLng? _markedLocation;
  List<LatLng> _routePoints = [];
  LatLng _cameraPosition = _center;

  final Location _location = Location();
  GoogleMapController? _mapController;
  Timer? _timer;
  final Random _random = Random();
  final String _googleApiKey = "AIzaSyAELGA7uZB-5iyxP7n-_K8D2JuP5xoZonY";

  @override
  void initState() {
    super.initState();
    _currentLocation = _center;
    _startLocationUpdates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: _cameraPosition, zoom: 15.0),
        markers: {
          if (_currentLocation != null)
            Marker(
              markerId: MarkerId("currentLocation"),
              position: _currentLocation!,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            ),
          if (_markedLocation != null)
            Marker(
              markerId: MarkerId("markedLocation"),
              position: _markedLocation!,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
        },
        polylines: {
          if (_routePoints.isNotEmpty)
            Polyline(
              polylineId: PolylineId("route"),
              color: const Color.fromARGB(255, 20, 148, 254),
              width: 5,
              points: _routePoints,
            ),
        },
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        onCameraMove: (CameraPosition position) {
          setState(() {
            _cameraPosition = position.target;
          });
        },
        onTap: (LatLng latLng) {
          _setMarkedLocation(latLng);
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.my_location),
        onPressed: _moveToUserLocation,
      ),
    );
  }

  /// Updates the user's real-time location
  void _startLocationUpdates() {
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      double latOffset = (_random.nextDouble() * 0.002 - 0.001);
      double lonOffset = (_random.nextDouble() * 0.002 - 0.001);
      LatLng newLocation = LatLng(
        _currentLocation!.latitude + latOffset,
        _currentLocation!.longitude + lonOffset,
      );

      _moveGraduallyTo(newLocation);
    });
  }

  /// Moves smoothly from _currentLocation to target
  void _moveGraduallyTo(LatLng target) {
    const int steps = 20;
    const Duration stepDuration = Duration(milliseconds: 200);
    double latStep = (target.latitude - _currentLocation!.latitude) / steps;
    double lonStep = (target.longitude - _currentLocation!.longitude) / steps;

    int stepCount = 0;
    Timer.periodic(stepDuration, (Timer t) {
      if (stepCount >= steps || !mounted) {
        t.cancel();
        return;
      }

      setState(() {
        _currentLocation = LatLng(
          _currentLocation!.latitude + latStep,
          _currentLocation!.longitude + lonStep,
        );
      });

      _mapController?.animateCamera(CameraUpdate.newLatLng(_currentLocation!));

      stepCount++;

      // Update the route dynamically if a marker is set
      if (_markedLocation != null) {
        _fetchRoute();
      }
    });
  }

  /// User taps on the map to set a destination marker
  void _setMarkedLocation(LatLng location) {
    setState(() {
      _markedLocation = location;
    });

    // Fetch road-following route
    _fetchRoute();
  }

  /// Fetches road-following route from Google Directions API
  Future<void> _fetchRoute() async {
    if (_currentLocation == null || _markedLocation == null) return;

    final String url =
        "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${_currentLocation!.latitude},${_currentLocation!.longitude}"
        "&destination=${_markedLocation!.latitude},${_markedLocation!.longitude}"
        "&mode=driving" // Change to driving, biking, or walking
        "&key=$_googleApiKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<LatLng> newRoute = [];

      if (data['routes'].isNotEmpty) {
        final route = data['routes'][0]['legs'][0]['steps'];

        for (var step in route) {
          final endLocation = step['end_location'];
          newRoute.add(LatLng(endLocation['lat'], endLocation['lng']));
        }

        setState(() {
          _routePoints = newRoute;
        });
      }
    }
  }

  /// Moves the camera to the user's current location
  void _moveToUserLocation() {
    if (_currentLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLocation!, zoom: 15),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
