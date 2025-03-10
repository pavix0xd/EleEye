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