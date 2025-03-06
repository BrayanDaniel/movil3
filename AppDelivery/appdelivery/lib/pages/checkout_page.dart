import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:pruebafirebase/pages/home_page.dart';
import 'menu_page.dart';

class CheckoutPage extends StatefulWidget {
  final CartProvider cartProvider;

  const CheckoutPage({Key? key, required this.cartProvider}) : super(key: key);

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  //Instanciar firebase auth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _selectedPaymentMethod;
  bool _isLoading = false;

  // Variables para el mapa
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(-0.31472, -78.44333); // Ubicación predeterminada (ESPE)
  Marker? _marker;
  bool _showMap = false;
  String _addressText = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Obtener la ubicación actual del usuario
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Los servicios de ubicación están desactivados'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permiso de ubicación denegado'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Los permisos de ubicación están permanentemente denegados'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _marker = Marker(
            markerId: const MarkerId('selected_location'),
            position: _selectedLocation,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          );
        });
      }

      // Obtener dirección a partir de las coordenadas
      _getAddressFromLatLng(_selectedLocation);

      if (_mapController != null && mounted) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(_selectedLocation));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al obtener la ubicación: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Obtener la dirección basada en las coordenadas
  Future<void> _getAddressFromLatLng(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude
      );

      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks[0];
        setState(() {
          _addressText =
          '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
        });
      } else if (mounted) {
        setState(() {
          _addressText = 'Ubicación seleccionada: ${location.latitude}, ${location.longitude}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _addressText = 'Ubicación seleccionada: ${location.latitude}, ${location.longitude}';
        });
      }
    }
  }

  Future<void> _submitOrder() async {
    // Obtener el usuario actual y su email
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para realizar un pedido'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final email = currentUser.email;

    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener tu correo electrónico'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate() && _selectedPaymentMethod != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Preparar los datos del pedido
        final orderItems = widget.cartProvider.items.map((item) => item.toMap()).toList();

        // Coordenadas de la Universidad de las Fuerzas Armadas - ESPE
        const espeLatitude = -0.31472;
        const espeLongitude = -78.44333;

        final order = {
          'customerName': _nameController.text,
          'customerPhone': _phoneController.text,
          'customerEmail': email, // Usando el email del usuario autenticado
          'location': {
            'latitude': _selectedLocation.latitude,
            'longitude': _selectedLocation.longitude,
          },
          // Nuevo campo con la ubicación predeterminada de la ESPE
          'locationOrder': {
            'latitude': espeLatitude,
            'longitude': espeLongitude,
          },
          'customerAddress': _addressText,
          'orderNotes': _notesController.text,
          'items': orderItems,
          'totalAmount': widget.cartProvider.totalAmount,
          'status': 'pending', // Estado inicial del pedido
          'paymentMethod': _selectedPaymentMethod,
          'timestamp': FieldValue.serverTimestamp(),
        };

        // Guardar el pedido en Firestore
        await FirebaseFirestore.instance.collection('orders').add(order);

        // Limpiar el carrito
        widget.cartProvider.clear();

        // Mostrar confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Pedido realizado con éxito!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );

        // Navegar a la página de confirmación
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const OrderConfirmationPage(),
          ),
              (route) => route.isFirst,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al realizar el pedido: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete todos los campos y seleccione un método de pago'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Información de Entrega',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.orange),
            const SizedBox(height: 20),
            Text(
              'Procesando tu pedido...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera de sección
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Datos de Entrega',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Campos de datos personales
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre completo',
                  hintText: 'Ingresa tu nombre y apellido',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.orange, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.person, color: Colors.orange),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu nombre';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  hintText: 'Ingresa tu número de teléfono',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.orange, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.phone, color: Colors.orange),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu teléfono';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Mostrar el correo del usuario autenticado (solo informativo)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email, color: Colors.orange),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Correo electrónico',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            currentUser?.email ?? 'No disponible',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Cabecera de sección ubicación
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.place_outlined,
                        color: Colors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Ubicación de entrega',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Mostrar la dirección seleccionada
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.orange, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dirección de entrega',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _addressText.isNotEmpty
                                ? _addressText
                                : 'Selecciona tu ubicación en el mapa',
                            style: TextStyle(
                              fontSize: 14,
                              color: _addressText.isEmpty ? Colors.grey : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Botón para mostrar/ocultar el mapa
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showMap = !_showMap;
                  });
                },
                icon: Icon(_showMap ? Icons.visibility_off : Icons.map, color: Colors.white),
                label: Text(
                  _showMap ? 'Ocultar Mapa' : 'Seleccionar en el Mapa',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),

              // Mapa para seleccionar ubicación
              if (_showMap)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 350,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _selectedLocation,
                            zoom: 15,
                          ),
                          zoomControlsEnabled: false,
                          zoomGesturesEnabled: true,
                          markers: _marker != null ? {_marker!} : {},
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                          },
                          onTap: (LatLng tappedPoint) async {
                            setState(() {
                              _selectedLocation = tappedPoint;
                              _marker = Marker(
                                markerId: const MarkerId('selected_location'),
                                position: tappedPoint,
                                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                              );
                            });
                            await _getAddressFromLatLng(tappedPoint);
                          },
                          mapToolbarEnabled: true,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                        ),
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: FloatingActionButton(
                            mini: true,
                            backgroundColor: Colors.white,
                            elevation: 2,
                            child: const Icon(Icons.my_location, color: Colors.blue),
                            onPressed: _getCurrentLocation,
                          ),
                        ),
                        // Controles de zoom adicionales
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Column(
                            children: [
                              FloatingActionButton(
                                mini: true,
                                backgroundColor: Colors.white,
                                elevation: 2,
                                child: const Icon(Icons.add, color: Colors.black),
                                onPressed: () {
                                  _mapController?.animateCamera(
                                    CameraUpdate.zoomIn(),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              FloatingActionButton(
                                mini: true,
                                backgroundColor: Colors.white,
                                elevation: 2,
                                child: const Icon(Icons.remove, color: Colors.black),
                                onPressed: () {
                                  _mapController?.animateCamera(
                                    CameraUpdate.zoomOut(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notas adicionales (opcional)',
                  hintText: 'Instrucciones de entrega, referencias, etc.',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.orange, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.note, color: Colors.orange),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Cabecera de sección forma de pago
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.payment_outlined,
                        color: Colors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Método de pago',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Selector de método de pago
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    _buildPaymentOption(
                      title: 'Efectivo',
                      subtitle: 'Paga al momento de la entrega',
                      icon: Icons.attach_money,
                      isSelected: _selectedPaymentMethod == 'Efectivo',
                      onTap: () {
                        setState(() {
                          _selectedPaymentMethod = 'Efectivo';
                        });
                      },
                    ),
                    const Divider(height: 1),
                    _buildPaymentOption(
                      title: 'Transferencia',
                      subtitle: 'Transferencia bancaria',
                      icon: Icons.account_balance,
                      isSelected: _selectedPaymentMethod == 'Transferencia',
                      onTap: () {
                        setState(() {
                          _selectedPaymentMethod = 'Transferencia';
                        });
                      },
                    ),
                    const Divider(height: 1),
                    _buildPaymentOption(
                      title: 'App',
                      subtitle: 'Paga a través de la aplicación',
                      icon: Icons.phone_android,
                      isSelected: _selectedPaymentMethod == 'App',
                      onTap: () {
                        setState(() {
                          _selectedPaymentMethod = 'App';
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Cabecera de sección resumen
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: Colors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Resumen del Pedido',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Tarjeta de resumen
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Listado de productos
                    ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: widget.cartProvider.items.length,
                      separatorBuilder: (context, index) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final item = widget.cartProvider.items[index];
                        return Row(
                          children: [
                            // Imagen en miniatura
                            if (item.imageUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.imageUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 40,
                                      height: 40,
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.fastfood,
                                        color: Colors.orange,
                                        size: 20,
                                      ),
                                    );
                                  },
                                ),
                              )
                            else
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.fastfood,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                              ),
                            const SizedBox(width: 12),
                            // Nombre e información
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Cantidad: ${item.quantity}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Precio
                            Text(
                              '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Totales
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        Text(
                          '\$${widget.cartProvider.totalAmount.toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cargo por envío',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const Text(
                          'GRATIS',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total a pagar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${widget.cartProvider.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Botón confirmar pedido
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text(
                        'Confirmar Pedido',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para crear las opciones de pago
  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.withOpacity(0.05) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.orange.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.orange : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.orange : Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.orange,
              ),
          ],
        ),
      ),
    );
  }
}

class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pedido Confirmado',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Elemento visual de confirmación
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 110,
                ),
              ),
              const SizedBox(height: 32),

              // Título y mensaje
              const Text(
                '¡Gracias por tu pedido!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Text(
                  'Tu pedido ha sido recibido y está siendo procesado. Puedes ver su estado en la sección "Mis Pedidos".',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 36),

              // Tarjeta de información de envío
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delivery_dining,
                            color: Colors.orange,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Seguimiento de pedido',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tu pedido está en preparación',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Pasos de seguimiento
                    Row(
                      children: [
                        _buildOrderStep(
                          isActive: true,
                          isCompleted: true,
                          title: 'Pedido',
                          icon: Icons.shopping_bag,
                        ),
                        _buildProgressLine(isActive: true),
                        _buildOrderStep(
                          isActive: true,
                          isCompleted: false,
                          title: 'Preparación',
                          icon: Icons.restaurant,
                        ),
                        _buildProgressLine(isActive: false),
                        _buildOrderStep(
                          isActive: false,
                          isCompleted: false,
                          title: 'Entrega',
                          icon: Icons.delivery_dining,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Botón para volver al inicio
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomePage(),
                      ),
                          (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Volver al Inicio',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Enlace para ver el estado del pedido
              TextButton.icon(
                onPressed: () {
                  // Esta funcionalidad podría llevar a la página de estado del pedido
                  // pero mantendremos la funcionalidad original
                },
                icon: const Icon(
                  Icons.receipt_long,
                  color: Colors.orange,
                ),
                label: const Text(
                  'Ver estado del pedido',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para crear un paso del seguimiento de pedido
  Widget _buildOrderStep({
    required bool isActive,
    required bool isCompleted,
    required String title,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive
                  ? isCompleted
                  ? Colors.green
                  : Colors.orange
                  : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Widget para crear una línea de progreso entre pasos
  Widget _buildProgressLine({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 3,
        color: isActive ? Colors.orange : Colors.grey.shade300,
      ),
    );
  }
}