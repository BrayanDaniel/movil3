import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:pruebafirebase/pages/updatelocation_page.dart';
 // Asegúrate de importar la nueva pantalla

class LiveTrackingPage extends StatefulWidget {
  const LiveTrackingPage({super.key});

  @override
  _LiveTrackingPageState createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  late GoogleMapController _mapController;
  LatLng _currentPosition = const LatLng(-0.22985, -78.52495); // Posición inicial (Ecuador)
  Marker? _marker;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getLiveLocation();
  }

  // Función para obtener la ubicación en tiempo real
  void _getLiveLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return;
    }

    Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _marker = Marker(
          markerId: const MarkerId('repartidor'),
          position: _currentPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        );
      });

      _mapController.animateCamera(CameraUpdate.newLatLng(_currentPosition));
    });
  }

  // Guardar ubicación en Firebase
  void _saveLocationToFirebase(LatLng location) async {
    await FirebaseFirestore.instance.collection('pueba').add({
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'timestamp': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Ubicación guardada: ${location.latitude}, ${location.longitude}")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Seguimiento en Vivo")),
      body: Column(
        children: [
          // Barra de búsqueda con Google Places
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GooglePlaceAutoCompleteTextField(
              textEditingController: _searchController,
              googleAPIKey: "TU_GOOGLE_API_KEY", // Coloca tu clave de API aquí
              inputDecoration: InputDecoration(
                hintText: "Buscar ubicación...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              debounceTime: 800,
              isLatLngRequired: true,
              getPlaceDetailWithLatLng: (prediction) {
                double lat = double.parse(prediction.lat!);
                double lng = double.parse(prediction.lng!);
                LatLng newPosition = LatLng(lat, lng);

                setState(() {
                  _currentPosition = newPosition;
                  _marker = Marker(
                    markerId: const MarkerId('seleccionado'),
                    position: newPosition,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  );
                });

                _mapController.animateCamera(CameraUpdate.newLatLngZoom(newPosition, 15));
                _saveLocationToFirebase(newPosition);
              },
            ),
          ),

          // Botón para navegar a UpdateLocationScreen
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UpdateLocationScreen()),
              );
            },
            child: const Text("Ver Última Ubicación"),
          ),

          // Mapa
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: _currentPosition, zoom: 15),
              markers: _marker != null ? {_marker!} : {},
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              onTap: (LatLng tappedPoint) {
                setState(() {
                  _currentPosition = tappedPoint;
                  _marker = Marker(
                    markerId: const MarkerId('seleccionado'),
                    position: tappedPoint,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  );
                });

                _saveLocationToFirebase(tappedPoint);
              },
            ),
          ),
        ],
      ),
    );
  }
}
