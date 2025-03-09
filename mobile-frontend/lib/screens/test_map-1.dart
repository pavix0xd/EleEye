import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:dio/dio.dart'; // For API calls
import 'dart:math'; // For distance calculations

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;

  final LatLng _initialPosition = LatLng(7.8731, 80.7718); // Sri Lanka
  final Set<Marker> _markers = {}; // Markers for elephants & locations
  final List<LatLng> _elephantLocations = [
    // Sample elephant locations
    LatLng(7.8801, 80.7728),
    LatLng(7.8650, 80.7700),
    LatLng(8.03300357030694, 80.75161888210204),
  ];

  List<LatLng> _routeCoords = []; // Holds the route coordinates (Polyline)
  String _googleMapsApiKey =
      "AIzaSyBb_w7wsSIkniGrQn_Z_mbB4eZZJn3v4Ls"; // Replace with actual API key

  @override
  void initState() {
    super.initState();
    _addElephantMarkers(); // Add elephant markers on map load
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  // Function to add elephant markers
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
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      }
    });
  }

  // Fetch Route from Google Directions API
  Future<void> _getRoute(String destination) async {
    String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${_initialPosition.latitude},${_initialPosition.longitude}&destination=$destination&key=$_googleMapsApiKey";

    Response response = await Dio().get(url);
    if (response.data["status"] == "OK") {
      List<LatLng> newRoute = [];
      var steps = response.data["routes"][0]["legs"][0]["steps"];
      for (var step in steps) {
        newRoute.add(
            LatLng(step["end_location"]["lat"], step["end_location"]["lng"]));
      }

      setState(() {
        _routeCoords = newRoute;
        _markers.add(
          Marker(
            markerId: MarkerId("destination"),
            position: newRoute.last,
            infoWindow: InfoWindow(title: "Destination"),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });

      _highlightElephantsOnRoute(); // Check for elephants near the route
    }
  }

  // Check and highlight elephants near the route
  void _highlightElephantsOnRoute() {
    double thresholdDistance = 1.0; // 1 km radius

    for (var elephant in _elephantLocations) {
      for (var point in _routeCoords) {
        double distance = _calculateDistance(elephant, point);
        if (distance <= thresholdDistance) {
          // Elephant is near the route, highlight it
          setState(() {
            _markers.add(
              Marker(
                markerId: MarkerId("elephant_near_${elephant.latitude}"),
                position: elephant,
                infoWindow: InfoWindow(title: "⚠️ Elephant Nearby!"),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed),
              ),
            );
          });
          break; // Move to the next elephant
        }
      }
    }
  }

  // Calculate distance between two points (in km)
  double _calculateDistance(LatLng pos1, LatLng pos2) {
    const double R = 6371; // Earth's radius in km
    double lat1 = pos1.latitude * pi / 180;
    double lon1 = pos1.longitude * pi / 180;
    double lat2 = pos2.latitude * pi / 180;
    double lon2 = pos2.longitude * pi / 180;

    double dlat = lat2 - lat1;
    double dlon = lon2 - lon1;

    double a =
        pow(sin(dlat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dlon / 2), 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c; // Distance in km
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('EleEYE Map')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 8.0,
              ),
              markers: _markers,
              polylines: {
                Polyline(
                  polylineId: PolylineId("route"),
                  color: Colors.blue,
                  width: 5,
                  points: _routeCoords,
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
