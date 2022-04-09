import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/state_manager.dart';

import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:marker_icon/marker_icon.dart';
import 'package:location/location.dart';

class MapasController extends GetxController {
  var markerlist = <Marker>[].obs;
  Rx<BitmapDescriptor?> icono = Rx<BitmapDescriptor?>(null);
  Rx<Position?> position = Rx<Position?>(null);
  Rx<StreamSubscription<Position>?> positionStream =
      Rx<StreamSubscription<Position>?>(null);

  @override
  void onInit() async {
    icono.value = await convertIconFromAsset("assets/taxi.png");
    await Geolocator.requestPermission();

    position.value = await Geolocator.getCurrentPosition();

    checkGps();
    updateLocation();

    super.onInit();
  }

  void addMarker(Marker marker) {
    markerlist.add(marker);
  }

  addMarkerToMap(LatLng latLng, String id) {
    markerlist.add(
      Marker(
        markerId: MarkerId(id),
        position: latLng,
        icon: icono.value!,
        infoWindow:
            const InfoWindow(title: "Taxi", snippet: "Chofe pare el Taxi"),
        draggable: false,
        zIndex: 2,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        rotation: position.value!.heading,
      ),
    );
  }

  void checkGps() async {
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      bool locationGps = await Location.instance.requestService();
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  updateLocation() async {
    try {
      await _determinePosition();
      position.value = await Geolocator.getLastKnownPosition();

      positionStream.value = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          distanceFilter: 1,
        ),
      ).listen((Position position) {
        this.position.value = position;
        addMarkerToMap(LatLng(position.latitude, position.longitude), "1");
      });
    } on Exception catch (e) {
      print(e);
    }
  }

  Future<BitmapDescriptor> convertIconFromAsset(String imgPath) async {
    var icon = await MarkerIcon.pictureAsset(
        assetPath: imgPath, width: 80, height: 80);
    return icon;
  }
}
