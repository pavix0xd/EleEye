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
  bool _isSearching = false;

  // Expanded locations map for Sri Lanka
  final Map<String, LatLng> _sriLankaLocations = {
    "colombo": LatLng(6.9271, 79.8612),
    "kandy": LatLng(7.2906, 80.6337),
    "galle": LatLng(6.0535, 80.2210),
    "jaffna": LatLng(9.6615, 80.0255),
    "anuradhapura": LatLng(8.3114, 80.4037),
    "negombo": LatLng(7.2081, 79.8384),
    "trincomalee": LatLng(8.5707, 81.2335),
    "batticaloa": LatLng(7.7164, 81.7000),
    "matara": LatLng(5.9485, 80.5353),
    "kurunegala": LatLng(7.4863, 80.3647),
    "ratnapura": LatLng(6.6949, 80.3998),
    "badulla": LatLng(6.9934, 81.0550),
    "ampara": LatLng(7.2975, 81.6659),
    "polonnaruwa": LatLng(7.9403, 81.0188),
    "nuwara eliya": LatLng(6.9497, 80.7891),
    "gampaha": LatLng(7.0917, 80.0000),
    "kalutara": LatLng(6.5854, 79.9607),
    "hambantota": LatLng(6.1429, 81.1212),
    "puttalam": LatLng(8.0408, 79.8394),
    "kegalle": LatLng(7.2513, 80.3464),
    "monaragala": LatLng(6.8715, 81.3487),
    "mathale": LatLng(7.4675, 80.6234),
    "vavuniya": LatLng(8.7514, 80.4997),
    "kilinochchi": LatLng(9.3803, 80.3770),
    "mannar": LatLng(8.9697, 79.9045),
    "mullaitivu": LatLng(9.2695, 80.8139),
  };

  @override
  void initState() {
    super.initState();
    _setupSocketConnection();
    _checkLocationPermissions();
    // Start location tracking immediately to ensure accurate position
    _startLocationTracking();
  }

  @override
  void dispose() {
    socket.dispose();
    _positionStream?.cancel();
    _destinationController.dispose();
    super.dispose();
  }
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // When map is created, immediately update to current location if available
    if (_currentLocation != null) {
      _animateCameraToPosition(_currentLocation!);
    }
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
        _updateCurrentLocationMarker();
      });
      _fetchNearbyElephants();

      // Animate camera to current location when first determined
      if (_currentLocation != null && mapController != null) {
        _animateCameraToPosition(_currentLocation!);
      }
    } catch (e) {
      _showAlert("Error", "Failed to get location: ${e.toString()}");
    }
  }
   // Start continuous location tracking
  void _startLocationTracking() {
    // Cancel any existing stream first
    _positionStream?.cancel();

    // Start a new position stream with high accuracy
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen((Position position) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _updateCurrentLocationMarker();

        // Update route if journey is started
        if (_isJourneyStarted && _destination != null) {
          _getRoutePoints();
        }
      });

      _fetchNearbyElephants();
      if (_isJourneyStarted) {
        _checkForElephantsNearby();
      }
    });
  }

  void _updateCurrentLocationMarker() {
    if (_currentLocation == null) return;

    setState(() {
      // Remove old marker
      _markers.removeWhere((marker) => marker.markerId.value == "currentLocation");

      // Add updated marker
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
      // Only remove elephant markers, not the current location or destination markers
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

  // Improved method to search for destination
  Future<void> _searchDestination() async {
    final query = _destinationController.text.trim().toLowerCase();
    if (query.isEmpty) {
      _showAlert("Error", "Please enter a destination");
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // First check if the location is in our predefined list
      bool locationFound = false;

      // Try exact match first
      if (_sriLankaLocations.containsKey(query)) {
        _setDestination(query, _sriLankaLocations[query]!);
        locationFound = true;
      } else {
        // Try partial match if exact match fails
        for (var entry in _sriLankaLocations.entries) {
          if (entry.key.contains(query) || query.contains(entry.key)) {
            _setDestination(entry.key, entry.value);
            locationFound = true;
            break;
          }
        }
      }

      // If no match found, try the server-based search or show error
      if (!locationFound) {
        // Try to call a server-based location API (implement as per your backend)
        bool serverSearchSuccessful = await _searchViaServer(query);

        if (!serverSearchSuccessful) {
          _showAlert("Location Not Found",
              "The location '$query' was not found. Please try a more common city name in Sri Lanka.");
        }
      }
    } catch (e) {
      _showAlert("Error", "Failed to find location: ${e.toString()}");
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }
  void _setDestination(String locationName, LatLng coordinates) {
    setState(() {
      _destination = coordinates;

      // Add destination marker
      _markers.removeWhere((marker) => marker.markerId.value == "destination");
      _markers.add(
        Marker(
          markerId: MarkerId("destination"),
          position: _destination!,
          infoWindow: InfoWindow(title: "Destination: ${locationName.toUpperCase()}"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );

      // Update the camera to show both current location and destination
      _updateCameraToShowRoute();

      // Calculate and display route
      _getRoutePoints();
    });
  }

  // Search via server API (placeholder - implement according to your API)
  Future<bool> _searchViaServer(String query) async {
    try {
      // Endpoint should be replaced with your actual geocoding API
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5003/geocode?query=${Uri.encodeComponent(query)}'),
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['found'] == true) {
          _setDestination(
              data['name'] ?? query,
              LatLng(data['latitude'], data['longitude'])
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      print("Server search error: $e");
      // Fallback to default coordinates for Sri Lanka if server fails
      if (query.length > 2) {
        // Only use this as last resort - set to a default central Sri Lanka location
        final centralSriLanka = LatLng(7.8731, 80.7718);
        _showAlert("Using Approximate Location",
            "Could not find exact coordinates. Showing an approximate location in Sri Lanka.");
        _setDestination(query, centralSriLanka);
        return true;
      }
      return false;
    }
  }
   // Update camera to show both current location and destination
  e bounds with padding
    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        min(_currentLocation!.latitude, _destination!.latitude) - 0.05,
        min(_currentLocation!.longitude, _destination!.longitude) - 0.05,
      ),
      northeast: LatLng(
        max(_currentLocation!.latitude, _destination!.latitude) + 0.05,
        max(_currentLocation!.longitude, _destination!.longitude) + 0.05,
      ),
    );

    // Make sure the cvoid _updateCameraToShowRoute() {
    //     if (_currentLocation == null || _destination == null) return;
    // 
    //     // Creatontroller is initialized
    if (mapController != null) {
      mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
    }
  }

  // Helper method for min/max
  double min(double a, double b) => a < b ? a : b;
  double max(double a, double b) => a > b ? a : b;

  // Method to get route between current location and destination
  Future<void> _getRoutePoints() async {
    if (_currentLocation == null || _destination == null) return;

    try {
      // Clear existing routes
      setState(() {
        _routes.clear();
      });

      // Try to get route from server
      bool routeFromServerSuccess = await _getRouteFromServer();

      // If server route fails, fall back to direct line
      if (!routeFromServerSuccess) {
        setState(() {
          _routes.add(
            Polyline(
              polylineId: PolylineId("route"),
              points: [_currentLocation!, _destination!],
              color: Colors.blue,
              width: 5,
            ),
          );
        });
      }
    } catch (e) {
      print("Error getting route: $e");
      // Fallback to direct line if any error occurs
      setState(() {
        _routes.add(
          Polyline(
            polylineId: PolylineId("route"),
            points: [_currentLocation!, _destination!],
            color: Colors.blue,
            width: 5,
          ),
        );
      });
    }
  }

  // Get route from server (placeholder - implement according to your routing API)
  Future<bool> _getRouteFromServer() async {
    try {
      if (_currentLocation == null || _destination == null) return false;

      // Replace with your actual routing API endpoint
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:5003/route?origin_lat=${_currentLocation!.latitude}'
                '&origin_lng=${_currentLocation!.longitude}'
                '&dest_lat=${_destination!.latitude}'
                '&dest_lng=${_destination!.longitude}'
        ),
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          List<LatLng> routePoints = [];
          for (var point in data['routes'][0]['points']) {
            routePoints.add(LatLng(point['lat'], point['lng']));
          }

          setState(() {
            _routes.add(
              Polyline(
                polylineId: PolylineId("route"),
                points: routePoints,
                color: Colors.blue,
                width: 5,
              ),
            );
          });
          return true;
        }
      }
      return false;
    } catch (e) {
      print("Server route error: $e");
      return false;
    }
  }
    void _startJourney() {
    if (_destination == null) {
      _showAlert("Error", "Please enter a destination first");
      return;
    }

    if (_currentLocation == null) {
      _showAlert("Error", "Waiting for your current location. Please try again in a moment.");
      return;
    }

    setState(() {
      _isJourneyStarted = true;
    });

    // Ensure we're tracking position with high accuracy
    _startLocationTracking();

    // Update the route with the latest current location
    _getRoutePoints();

    // Focus on the route when journey starts
    _updateCameraToShowRoute();

    _showAlert("Journey Started", "Navigation to ${_destinationController.text} has begun. Stay alert for elephants nearby!");
  }

  void _animateCameraToPosition(LatLng position) {
    if (mapController != null) {
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(position, 15),
      );
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

        // Convert to kilometers with 2 decimal places
        double distanceKm = distance / 1000;

        // Alert if elephant is within 500 meters
        if (distanceKm < 0.5) {
          _showAlert(
              "Warning!",
              "Elephant detected ${distanceKm.toStringAsFixed(2)} km away!"
          );

          // Vibrate to alert user
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
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            zoomControlsEnabled: false,
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
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _destinationController,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: "Enter destination (e.g., Colombo, Kandy)",
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.location_on, color: Colors.red),
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      onSubmitted: (_) => _searchDestination(),
                    ),
                  ),
                  IconButton(
                    icon: _isSearching
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.search, color: Colors.blue),
                    onPressed: _searchDestination,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "recenter",
            onPressed: _currentLocation != null
                ? () => _animateCameraToPosition(_currentLocation!)
                : null,
            backgroundColor: Colors.white,
            child: Icon(Icons.my_location, color: Colors.blue),
          ),
          SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: "startJourney",
            onPressed: (_destination != null && _currentLocation != null)
                ? _startJourney
                : null,
            label: Text(
                _isJourneyStarted ? "Restart Journey" : "Start Journey",
                style: TextStyle(color: Colors.white)
            ),
            icon: Icon(Icons.directions, color: Colors.white),
            backgroundColor: (_destination != null && _currentLocation != null)
                ? Colors.teal
                : Colors.grey,
            elevation: 6,
          ),
        ],
      ),
    );
  }
}