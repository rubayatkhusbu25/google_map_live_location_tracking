import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class GoogleMapLocationTrack extends StatefulWidget {
  const GoogleMapLocationTrack({super.key});

  @override
  State<GoogleMapLocationTrack> createState() =>
      _GoogleMapLocationTrackState();
}

class _GoogleMapLocationTrackState extends State<GoogleMapLocationTrack> {
  LocationData? currentLocation;
  Marker? _currentLocationMarker;
  List<LatLng> _routePoints = [];

  late GoogleMapController _googleMapController;

  Future<void> _getCurrentLocation() async {
    bool isLocationPermissionEnabled = await _isLocationPermissionEnabled();
    if (isLocationPermissionEnabled) {
      bool isLocationServiceEnabled = await Location.instance.serviceEnabled();
      if (!isLocationServiceEnabled) {
        isLocationServiceEnabled = await Location.instance.requestService();
        if (!isLocationServiceEnabled) return;
      }

      Location.instance.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 10000, // 10 seconds
        distanceFilter: 3,
      );

      currentLocation = await Location.instance.getLocation();
      _addLocationMarker(currentLocation!);
    } else {
      bool granted = await _requestPermission();
      if (granted) {
        _getCurrentLocation();
      }
    }
  }

  Future<void> _listenCurrentLocation() async {
    bool isLocationPermissionEnabled = await _isLocationPermissionEnabled();
    if (isLocationPermissionEnabled) {
      bool isLocationServiceEnabled = await Location.instance.serviceEnabled();
      if (!isLocationServiceEnabled) {
        isLocationServiceEnabled = await Location.instance.requestService();
        if (!isLocationServiceEnabled) return;
      }

      Location.instance.onLocationChanged.listen((location) {
        currentLocation = location;
        _addLocationMarker(location);
      });
    } else {
      bool granted = await _requestPermission();
      if (granted) {
        _listenCurrentLocation();
      }
    }
  }

  void _addLocationMarker(LocationData location) {
    LatLng newPosition = LatLng(location.latitude!, location.longitude!);
    setState(() {
      _currentLocationMarker = Marker(
        markerId:  MarkerId("current_location"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow:  InfoWindow(
            title: "My current location",
        snippet: "Latitude:${currentLocation?.latitude!}, Longitude:${currentLocation?.longitude!}"),
        position: newPosition,
      );

      _routePoints.add(newPosition);
    });
  }

  Future<bool> _isLocationPermissionEnabled() async {
    PermissionStatus status = await Location.instance.hasPermission();
    return status == PermissionStatus.granted ||
        status == PermissionStatus.grantedLimited;
  }

  Future<bool> _requestPermission() async {
    PermissionStatus status = await Location.instance.requestPermission();
    return status == PermissionStatus.granted ||
        status == PermissionStatus.grantedLimited;
  }

  @override
  Widget build(BuildContext context){

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Map Current Location Tracker",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: () {
              _listenCurrentLocation();
            },
            icon: const Icon(Icons.play_arrow),
            tooltip: "Start Tracking",
          ),
        ],
      ),
      body: GoogleMap(
        mapType: MapType.terrain,
        zoomControlsEnabled: true,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        compassEnabled: true,
        onMapCreated: (controller) => _googleMapController = controller,
        initialCameraPosition: const CameraPosition(
          target: LatLng(23.777176, 90.399452), // Default to Dhaka
          zoom: 5,
        ),
        markers: {
          if (_currentLocationMarker != null) _currentLocationMarker!,
        },
        polylines: {
          Polyline(
            polylineId: const PolylineId("polyline_1"),
            color: Colors.red.shade900,
            width: 5,
            startCap: Cap.roundCap,
            endCap: Cap.squareCap,
            jointType: JointType.round,
            points: _routePoints,
          ),
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade800,
        elevation: 2.0,
        onPressed: () {
          if (currentLocation != null) {
            _googleMapController.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(
                    currentLocation!.latitude!,
                    currentLocation!.longitude!,
                  ),
                  zoom: 17,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Location not yet available."),
              ),
            );
          }
        },
        child: const Icon(Icons.location_searching, color: Colors.white),
      ),
    );
  }
}
