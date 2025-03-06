import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class UpdateLocationScreen extends StatefulWidget {
  const UpdateLocationScreen({Key? key}) : super(key: key);

  @override
  _UpdateLocationScreenState createState() => _UpdateLocationScreenState();
}

class _UpdateLocationScreenState extends State<UpdateLocationScreen> {
  LatLng? _lastLocation;
  Stream<Position>? _positionStream;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  // Iniciar la obtención de la ubicación en tiempo real
  void _startLocationUpdates() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Actualiza cada vez que se mueva 10 metros
      ),
    );

    _positionStream!.listen((Position position) {
      setState(() {
        _lastLocation = LatLng(position.latitude, position.longitude);
      });
      _saveLocationToFirebase(_lastLocation!);
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(_lastLocation!));
      }
    });
  }

  // Guardar la ubicación en Firestore
  void _saveLocationToFirebase(LatLng location) async {
    await FirebaseFirestore.instance.collection('pueba').add({
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Última Ubicación")),
      body: Column(
        children: [
          Expanded(
            child: _lastLocation != null
                ? GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: _lastLocation!,
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: MarkerId('current_location'),
                  position: _lastLocation!,
                ),
              },
            )
                : const Center(child: CircularProgressIndicator()),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _lastLocation != null
                ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Última Ubicación:"),
                Text("Latitud: ${_lastLocation!.latitude}"),
                Text("Longitud: ${_lastLocation!.longitude}"),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Aquí puedes añadir lógica adicional si es necesario
                  },
                  child: const Text("Acciones adicionales"),
                ),
              ],
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _positionStream?.listen((_) {}).cancel(); // Cancelar el stream al salir de la pantalla
    super.dispose();
  }
}
