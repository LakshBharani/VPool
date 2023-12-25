import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:vpool/main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Location _locationController = Location();

  static const LatLng _pStart = LatLng(12.9738442468678, 79.16423234743702);
  static const LatLng _pEnd = LatLng(12.958698377535645, 79.137714527879);
  LatLng? _currentLocation = null;

  @override
  void initState() {
    super.initState();
    getLocationUpdates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 7,
            child: _currentLocation == null
                ? Center(child: Text("Map Loading..."))
                : GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: _pStart,
                      zoom: 14,
                    ),
                    markers: {
                      Marker(
                          markerId: MarkerId("_currentLocation"),
                          icon: BitmapDescriptor.defaultMarker,
                          position: _currentLocation!),
                      const Marker(
                          markerId: MarkerId("_sourceLocation"),
                          icon: BitmapDescriptor.defaultMarker,
                          position: _pStart),
                      const Marker(
                          markerId: MarkerId("_destinationLocation"),
                          icon: BitmapDescriptor.defaultMarker,
                          position: _pEnd),
                    },
                  ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.white,
              child: ElevatedButton(
                  onPressed: () async {
                    await supabase.auth.signOut();
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  child: Text("Sign out")),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> getLocationUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _locationController.serviceEnabled();
    if (serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
    } else {
      return;
    }

    permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          _currentLocation =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
        });
        print(_currentLocation);
      }
    });
  }
}
