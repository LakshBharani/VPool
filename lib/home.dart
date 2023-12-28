// ignore_for_file: avoid_print, use_build_context_synchronously, non_constant_identifier_names

import 'dart:async';
import 'package:flutter/cupertino.dart';
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
  LatLng? _pStart;
  LatLng? _pEnd;
  LatLng? _currentLocation;
  double mapFlex = 9;
  double bottomBarFlex = 5;
  bool isUsingCurrentLocationAsSource = true;
  bool isBookingNow = false;
  final TextEditingController _sourceController =
      TextEditingController(text: 'Current Location');
  final TextEditingController _destinationController = TextEditingController();
  final Map<PolylineId, Polyline> _polyLines = {};

  @override
  void initState() {
    super.initState();
    getLocationUpdates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          MapWidget(),
          BottomBarWidget(),
        ],
      ),
    );
  }

  // map
  Widget MapWidget() {
    return Expanded(
      flex: mapFlex.toInt(),
      child: _currentLocation == null
          ? Center(
              child: _locationController.hasPermission() ==
                      PermissionStatus.granted
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Fetching your location..."),
                        const SizedBox(height: 50),
                        CircularProgressIndicator(
                          color: elementPrimaryColor,
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                            "Please enable Location Services to continue"),
                        const SizedBox(height: 50),
                        ElevatedButton(
                          onPressed: () async => {
                            await _locationController.serviceEnabled()
                                ? _locationController.requestPermission()
                                : _locationController.requestService(),
                          },
                          child: const Text("Enable Location Services"),
                        ),
                      ],
                    ),
            )
          : Stack(
              children: [
                GoogleMap(
                  myLocationButtonEnabled: false,
                  myLocationEnabled: true,
                  zoomGesturesEnabled: true,
                  rotateGesturesEnabled: false,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
                  ),
                  onCameraMove: (position) {
                    setState(() {
                      // mapPadding = 0;
                    });
                  },
                  onMapCreated: ((GoogleMapController controller) =>
                      _mapController.complete(controller)),
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation!,
                    zoom: 16,
                  ),
                  onTap: (LatLng pos) => {
                    setState(() {
                      mapFlex = 9;
                      bottomBarFlex = 5;
                      _pEnd != null || _pStart != null
                          ? getPolylinePoints().then((coordinates) => {
                                generatePolylineFromPoints(coordinates),
                              })
                          : null;
                    }),
                  },
                  markers: _pEnd != null || _pStart != null
                      ? {
                          Marker(
                              markerId: const MarkerId("_sourceLocation"),
                              position: _pStart!),
                          Marker(
                              markerId: const MarkerId("_destinationLocation"),
                              position: _pEnd!),
                        }
                      : {},
                  polylines: Set<Polyline>.of(_polyLines.values),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => {
                      FocusManager.instance.primaryFocus?.unfocus(),
                      _polyLines.isNotEmpty
                          ? getLocationUpdates().then((_) => {
                                setState(() {
                                  mapFlex = 9;
                                  bottomBarFlex = 5;
                                }),
                                getPolylinePoints().then((coordinates) => {
                                      generatePolylineFromPoints(coordinates),
                                    }),
                              })
                          : _mapController.future.then((value) => {
                                value.animateCamera(
                                  CameraUpdate.newCameraPosition(
                                    CameraPosition(
                                      target: _currentLocation!,
                                      zoom: 16,
                                    ),
                                  ),
                                ),
                                setState(() {
                                  mapFlex = 9;
                                  bottomBarFlex = 5;
                                }),
                              }),
                    },
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromARGB(255, 170, 170, 170),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.my_location_rounded,
                        size: 22,
                        color: elementSecondaryColor,
                      ),
                    ),
                  ),
                )
              ],
            ),
    );
  }

  // bottom bar
  Widget BottomBarWidget() {
    return Expanded(
      flex: bottomBarFlex.toInt(),
      child: Container(
        width: double.infinity,
        color: Colors.white,
        child: mapFlex == 9 ? bottomBarDefault() : bottomBarCustom(),
      ),
    );
  }

  // bottom bar with frequent destinations
  Widget bottomBarDefault() {
    return Column(
      children: [
        searchDestinationButton(),
        FavoritePlacesWidget(),
      ],
    );
  }

  // bottom bar with navigation options, date options and search bar
  Widget bottomBarCustom() {
    return Column(
      children: [
        bottomBarNavOptions(),
        const SizedBox(height: 10),
        bottomBarDateOptions(),
        const SizedBox(height: 10),
      ],
    );
  }

  // custom source and destination selection
  Widget bottomBarNavOptions() {
    return Row(
      children: [
        Container(
          margin: const EdgeInsets.only(left: 15, top: 10),
          child: IntrinsicHeight(
            child: Column(
              children: [
                Icon(
                  Icons.circle_rounded,
                  size: 8,
                  color: elementPrimaryColor,
                ),
                Container(
                    height: 40,
                    width: 1,
                    color: elementSecondaryColor,
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 0)),
                Icon(
                  Icons.square_rounded,
                  size: 8,
                  color: elementSecondaryColor,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              selectSourceTextfield(),
              selectDestinationButton(),
            ],
          ),
        ),
      ],
    );
  }

  // booking now or schedule
  Widget bottomBarDateOptions() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () {
              setState(() {
                isBookingNow = true;
              });
            },
            style: TextButton.styleFrom(
              foregroundColor:
                  isBookingNow ? elementPrimaryColor : elementSecondaryColor,
              backgroundColor:
                  isBookingNow ? elementSecondaryColor : Colors.grey.shade200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
            ),
            child: const Text("Now"),
          ),
        ),
        Expanded(
          child: TextButton(
            onPressed: () {
              setState(() {
                isBookingNow = false;
              });
            },
            style: TextButton.styleFrom(
              foregroundColor:
                  isBookingNow ? elementSecondaryColor : elementPrimaryColor,
              backgroundColor:
                  isBookingNow ? Colors.grey.shade200 : elementSecondaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
            ),
            child: const Text("Schedule"),
          ),
        ),
      ],
    );
  }

  // custom source selection textfield
  Widget selectSourceTextfield() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _sourceController,
              keyboardType: TextInputType.streetAddress,
              onChanged: (value) => {
                setState(() {
                  _sourceController.text = value;
                }),
              },
              onTap: () => {
                _sourceController.text == "Current Location"
                    ? setState(() {
                        _sourceController.text = "";
                      })
                    : null,
              },
              onTapOutside: (value) => {
                FocusManager.instance.primaryFocus?.unfocus(),
              },
              onEditingComplete: () => {
                _sourceController.text == ""
                    ? setState(() {
                        _sourceController.text = "Current Location";
                      })
                    : null,
              },
              onFieldSubmitted: (value) => {
                FocusManager.instance.primaryFocus?.unfocus(),
                print("Source: $value")
              },
              style: TextStyle(
                  fontSize: 14,
                  color: _sourceController.text == "Current Location"
                      ? CupertinoColors.activeBlue
                      : Colors.black),
              cursorHeight: 14,
              autocorrect: false,
              maxLines: 1,
              cursorColor: elementSecondaryColor,
              decoration: InputDecoration(
                hintText: "Pickup Location",
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 0,
                ),
                hintStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(1),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                suffixIcon: _sourceController.text == "Current Location"
                    ? const Icon(
                        Icons.my_location_rounded,
                        color: CupertinoColors.activeBlue,
                      )
                    : _sourceController.text == ""
                        ? null
                        : GestureDetector(
                            onTap: () => {
                              setState(() {
                                _sourceController.text = "";
                              }),
                            },
                            child: Icon(
                              Icons.cancel_outlined,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // custom destination selection textfield
  Widget selectDestinationButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _destinationController,
              keyboardType: TextInputType.streetAddress,
              onChanged: (value) => {
                setState(() {
                  _destinationController.text = value;
                }),
              },
              onFieldSubmitted: (value) => {
                FocusManager.instance.primaryFocus?.unfocus(),
                print("Destination: $value")
              },
              onTapOutside: (value) => {
                FocusManager.instance.primaryFocus?.unfocus(),
              },
              style: const TextStyle(fontSize: 14, color: Colors.black),
              cursorHeight: 14,
              autocorrect: false,
              maxLines: 1,
              cursorColor: elementSecondaryColor,
              decoration: InputDecoration(
                hintText: "Where To?",
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 0,
                ),
                hintStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(1),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                suffixIcon: _destinationController.text != ""
                    ? GestureDetector(
                        onTap: () => {
                          setState(() {
                            _destinationController.text = "";
                          }),
                        },
                        child: Icon(
                          Icons.cancel_outlined,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WHERE TO? button -> custom destination selection
  Widget searchDestinationButton() {
    return GestureDetector(
      onTap: () => {
        setState(() {
          print(_currentLocation);
          mapFlex = 2;
          bottomBarFlex = 7;
        }),
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        height: 70,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: elementSecondaryColor,
        ),
        child: Row(
          children: [
            Icon(
              Icons.subdirectory_arrow_right_rounded,
              color: elementPrimaryColor,
              size: 25,
            ),
            const SizedBox(width: 10),
            Text(
              "Where To?",
              style: TextStyle(
                color: elementPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // frequent destinations
  Widget FavoritePlacesWidget() {
    return Column(
      children: [
        shortCutWidget(1, "VIT Vellore, Tamil Nadu", "0 km", 23),
        shortCutWidget(2, "Katpadi Railway Station", "3.1 km", 14),
        shortCutWidget(3, "Chennai Airport, Tamil Nadu", "129 km", 5),
      ],
    );
  }

  // frequent destinations widget
  Widget shortCutWidget(
      double index, String destination, String distance, int waitingNumber) {
    return GestureDetector(
      onTap: () => {
        setState(() {
          mapFlex = 2;
          bottomBarFlex = 7;
        }),
        _pStart = _currentLocation,
        _pEnd = index == 1
            ? const LatLng(11.943346102098497, 79.809578764766)
            : index == 2
                ? const LatLng(12.971804174947863, 79.13829296711951)
                : index == 3
                    ? const LatLng(13.043346102098497, 80.209578764766)
                    : null,
        getPolylinePoints().then((coordinates) => {
              generatePolylineFromPoints(coordinates),
            }),
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: index == 1
              ? const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                )
              : index == 2
                  ? BorderRadius.circular(0)
                  : index == 3
                      ? const BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        )
                      : null,
          border: index == 2
              ? Border.symmetric(
                  vertical: BorderSide(color: Colors.grey.shade300))
              : Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      index == 1
                          ? Icons.location_city_rounded
                          : index == 2
                              ? Icons.directions_railway_rounded
                              : index == 3
                                  ? Icons.local_airport_rounded
                                  : null,
                      size: 23,
                      color: elementPrimaryColor,
                    ),
                    const SizedBox(width: 40),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(destination),
                        Row(
                          children: [
                            Text(
                              distance,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "$waitingNumber requests",
                              style: TextStyle(
                                  fontSize: 10,
                                  color: elementPrimaryColor,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 30,
                  color: Colors.grey.shade800,
                ),
              ],
            ),
          ],
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

    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 70);

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
      PointLatLng(_pStart!.latitude, _pStart!.longitude),
      PointLatLng(_pEnd!.latitude, _pEnd!.longitude),
      travelMode: TravelMode.driving,
    );
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
    _pStart != null && _pEnd != null
        ? await updateCameraLocation(
            _pStart!, _pEnd!, await _mapController.future)
        : null;
  }
}
