// ignore_for_file: avoid_print, use_build_context_synchronously, non_constant_identifier_names

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:vpool/constants/colors.dart';
import 'package:vpool/constants/keys.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Location _locationController = Location();
  final Completer _mapController = Completer<GoogleMapController>();
  static const LatLng _pStart = LatLng(12.968688776803814, 79.15588731716967);
  static const LatLng _pEnd = LatLng(11.943346102098497, 79.809578764766);
  LatLng? _currentLocation;

  final Map<PolylineId, Polyline> _polyLines = {};

  @override
  void initState() {
    super.initState();
    getLocationUpdates().then((_) => {
          getPolylinePoints().then((coordinates) => {
                generatePolylineFromPoints(coordinates),
              }),
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 12,
            child: _currentLocation == null
                ? const Center(child: Text("Map Loading..."))
                : GoogleMap(
                    myLocationButtonEnabled: true,
                    myLocationEnabled: true,
                    onMapCreated: ((GoogleMapController controller) =>
                        _mapController.complete(controller)),
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation!,
                      zoom: 16,
                    ),
                    markers: {
                      const Marker(
                          markerId: MarkerId("_sourceLocation"),
                          icon: BitmapDescriptor.defaultMarker,
                          position: _pStart),
                      const Marker(
                          markerId: MarkerId("_destinationLocation"),
                          icon: BitmapDescriptor.defaultMarker,
                          position: _pEnd),
                    },
                    polylines: Set<Polyline>.of(_polyLines.values),
                  ),
          ),
          BottomBarWidget(),
        ],
      ),
    );
  }

  // Widget MapWidget() {
  //   return Expanded(
  //     flex: 12,
  //     child: _currentLocation == null
  //         ? const Center(child: Text("Map Loading..."))
  //         : GoogleMap(
  //             myLocationButtonEnabled: true,
  //             myLocationEnabled: true,
  //             onMapCreated: ((GoogleMapController controller) =>
  //                 _mapController.complete(controller)),
  //             initialCameraPosition: CameraPosition(
  //               target: _currentLocation!,
  //               zoom: 16,
  //             ),
  //             markers: {
  //               const Marker(
  //                   markerId: MarkerId("_sourceLocation"),
  //                   icon: BitmapDescriptor.defaultMarker,
  //                   position: _pStart),
  //               const Marker(
  //                   markerId: MarkerId("_destinationLocation"),
  //                   icon: BitmapDescriptor.defaultMarker,
  //                   position: _pEnd),
  //             },
  //             polylines: Set<Polyline>.of(_polyLines.values),
  //           ),
  //   );
  // }

  Widget BottomBarWidget() {
    return Expanded(
      flex: 5,
      child: Container(
        color: appPrimaryColor,
        child: const Column(
          children: [],
        ),
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
        // _cameraToPosition(_currentLocation!);
      }
    });
  }

  Future<void> updateCameraLocation(
    LatLng source,
    LatLng destination,
    GoogleMapController mapController,
  ) async {
    LatLngBounds bounds;

    if (source.latitude > destination.latitude &&
        source.longitude > destination.longitude) {
      bounds = LatLngBounds(southwest: destination, northeast: source);
    } else if (source.longitude > destination.longitude) {
      bounds = LatLngBounds(
          southwest: LatLng(source.latitude, destination.longitude),
          northeast: LatLng(destination.latitude, source.longitude));
    } else if (source.latitude > destination.latitude) {
      bounds = LatLngBounds(
          southwest: LatLng(destination.latitude, source.longitude),
          northeast: LatLng(source.latitude, destination.longitude));
    } else {
      bounds = LatLngBounds(southwest: source, northeast: destination);
    }

    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 90);

    return checkCameraLocation(cameraUpdate, mapController);
  }

  Future<void> checkCameraLocation(
      CameraUpdate cameraUpdate, GoogleMapController mapController) async {
    mapController.animateCamera(cameraUpdate);
    LatLngBounds l1 = await mapController.getVisibleRegion();
    LatLngBounds l2 = await mapController.getVisibleRegion();

    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90) {
      return checkCameraLocation(cameraUpdate, mapController);
    }
  }

  // Future<void> _cameraToPosition(LatLng pos) async {
  //   final GoogleMapController controller = await _mapController.future;
  //   CameraPosition newCameraPosition = CameraPosition(
  //     target: pos,
  //     zoom: 18,
  //   );
  //   await controller
  //       .animateCamera(CameraUpdate.newCameraPosition(newCameraPosition));
  // }

  Future<List<LatLng>> getPolylinePoints() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        GOOGLE_MAPS_API_KEY,
        PointLatLng(_pStart.latitude, _pStart.longitude),
        PointLatLng(_pEnd.latitude, _pEnd.longitude),
        travelMode: TravelMode.driving);
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    } else {
      print(result.errorMessage);
    }
    return polylineCoordinates;
  }

  void generatePolylineFromPoints(List<LatLng> polylineCoordinates) async {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.black,
      points: polylineCoordinates,
      width: 4,
    );

    setState(() {
      _polyLines[id] = polyline;
    });
    await updateCameraLocation(_pStart, _pEnd, await _mapController.future);
  }
}
