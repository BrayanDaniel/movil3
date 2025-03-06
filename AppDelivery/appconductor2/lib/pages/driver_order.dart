import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:developer' as developer;

class DriverOrdersScreen extends StatefulWidget {
  const DriverOrdersScreen({Key? key}) : super(key: key);

  @override
  _DriverOrdersScreenState createState() => _DriverOrdersScreenState();
}

class _DriverOrdersScreenState extends State<DriverOrdersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Stream<QuerySnapshot>? _ordersStream;
  LatLng? _lastLocation;
  Stream<Position>? _positionStream;
  GoogleMapController? _mapController;
  String? _selectedOrderId;
  bool _isTrackingLocation = false;
  String _locationUpdateStatus = "No hay seguimiento activo";
  int _locationUpdateCount = 0;
  bool _hasActiveOrder = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _loadOrders();
    _checkForActiveOrders();
  }

  // Verificar si ya hay un pedido en curso
  Future<void> _checkForActiveOrders() async {
    try {
      final querySnapshot = await _firestore.collection('orders')
          .where('status', isEqualTo: 'on_the_way')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final orderId = querySnapshot.docs.first.id;
        setState(() {
          _selectedOrderId = orderId;
          _hasActiveOrder = true;
          _isTrackingLocation = true;
        });
        developer.log('Encontrado pedido activo: $orderId');
        _startLocationUpdates(orderId);
      }
    } catch (e) {
      developer.log('Error al verificar pedidos activos: $e');
    }
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si los servicios de ubicación están habilitados
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Los servicios de ubicación están desactivados')),
        );
      }
      return;
    }

    // Verificar permisos de ubicación
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Los permisos de ubicación fueron denegados')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Los permisos de ubicación están permanentemente denegados')),
        );
      }
      return;
    }

    // Obtener ubicación inicial
    try {
      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _lastLocation = LatLng(position.latitude, position.longitude);
          _locationUpdateStatus = "Ubicación inicial obtenida";
        });
      }
      developer.log('Ubicación inicial obtenida: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationUpdateStatus = "Error obteniendo ubicación inicial: $e";
        });
      }
      developer.log('Error al obtener ubicación inicial: $e');
    }
  }

  void _loadOrders() {
    // Usando una consulta más simple que no requiere índices compuestos
    // Simplemente obtenemos todas las órdenes y luego filtramos en el cliente
    _ordersStream = _firestore.collection('orders')
        .orderBy('timestamp', descending: true)
        .snapshots();
    developer.log('Stream de órdenes inicializado (consulta simplificada)');
  }

  // Iniciar la obtención de la ubicación en tiempo real
  void _startLocationUpdates(String orderId) {
    developer.log('Iniciando seguimiento de ubicación para el pedido: $orderId');
    setState(() {
      _locationUpdateStatus = "Iniciando seguimiento para pedido: $orderId";
      _locationUpdateCount = 0;
      _isTrackingLocation = true;
      _hasActiveOrder = true;
    });

    // Cancelar stream previo si existe
    if (_positionStream != null) {
      _positionStream!.listen((_) {}).cancel();
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Actualiza cada vez que se mueva 10 metros
      ),
    );

    _positionStream!.listen((Position position) {
      developer.log('Nueva posición recibida: ${position.latitude}, ${position.longitude}');
      _locationUpdateCount++;

      if (mounted) {
        setState(() {
          _lastLocation = LatLng(position.latitude, position.longitude);
          _locationUpdateStatus = "Posición #$_locationUpdateCount actualizada: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
        });
      }

      _updateOrderLocation(orderId, _lastLocation!);

      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(_lastLocation!));
      }
    });

    setState(() {
      _selectedOrderId = orderId;
    });

    // Actualizar inmediatamente con la ubicación actual si ya la tenemos
    if (_lastLocation != null) {
      _updateOrderLocation(orderId, _lastLocation!);
    }
  }

  // Actualizar la ubicación del pedido en Firestore
  Future<void> _updateOrderLocation(String orderId, LatLng location) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'locationOrder': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        }
      });
      developer.log('Ubicación actualizada en Firestore para el pedido $orderId: ${location.latitude}, ${location.longitude}');

      // Verificar que la ubicación se actualizó correctamente
      DocumentSnapshot doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('locationOrder')) {
          Map<String, dynamic> locationOrder = data['locationOrder'] as Map<String, dynamic>;
          developer.log('Verificación: locationOrder en Firestore = ${locationOrder['latitude']}, ${locationOrder['longitude']}');

          if (mounted) {
            setState(() {
              _locationUpdateStatus += "\n✓ Guardado en Firebase";
            });
          }
        } else {
          developer.log('Error: locationOrder no existe en el documento');
          if (mounted) {
            setState(() {
              _locationUpdateStatus += "\n✗ Error: locationOrder no existe en Firebase";
            });
          }
        }
      }
    } catch (e) {
      developer.log('Error al actualizar ubicación en Firestore: $e');
      if (mounted) {
        setState(() {
          _locationUpdateStatus += "\n✗ Error al guardar: $e";
        });
      }
    }
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    developer.log('Actualizando estado del pedido $orderId a: $status');

    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status
      });

      developer.log('Estado actualizado correctamente a: $status');

      // Solo iniciar el seguimiento cuando el estado cambia a "on_the_way"
      if (status == 'on_the_way') {
        _startLocationUpdates(orderId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seguimiento de ubicación iniciado')),
          );
        }
      }

      if (status == 'delivered' || status == 'cancelled') {
        // Cancelar el stream de ubicación
        if (_positionStream != null) {
          _positionStream!.listen((_) {}).cancel();
          _positionStream = null;
        }

        setState(() {
          _selectedOrderId = null;
          _isTrackingLocation = false;
          _hasActiveOrder = false;
          _locationUpdateStatus = "Seguimiento finalizado";
        });

        developer.log('Seguimiento de ubicación cancelado');
      }
    } catch (e) {
      developer.log('Error al actualizar estado: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar estado: $e')),
        );
      }
    }
  }

  // Calcula la distancia entre la ubicación actual y la de entrega
  double _calculateDistance(double lat, double lng) {
    if (_lastLocation == null) return double.infinity;

    double distance = Geolocator.distanceBetween(
      _lastLocation!.latitude,
      _lastLocation!.longitude,
      lat,
      lng,
    );

    developer.log('Distancia calculada al destino: $distance metros');
    return distance;
  }

  int _getStepFromStatus(String status) {
    switch (status) {
      case 'pending':
      case 'preparing':
        return 0;
      case 'on_the_way':
        return 1;
      case 'delivered':
        return 2;
      case 'cancelled':
        return 3;
      default:
        return 0;
    }
  }

  String _getNextStatus(String currentStatus) {
    switch (currentStatus) {
      case 'pending':
        return 'preparing';
      case 'preparing':
        return 'on_the_way';
      case 'on_the_way':
        return 'delivered';
      default:
        return currentStatus;
    }
  }

  String _getButtonText(String status) {
    switch (status) {
      case 'pending':
        return 'Preparar Pedido';
      case 'preparing':
        return 'Iniciar Entrega';
      case 'on_the_way':
        return 'Entregar Pedido';
      default:
        return 'Siguiente';
    }
  }

  IconData _getButtonIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.restaurant;
      case 'preparing':
        return Icons.delivery_dining;
      case 'on_the_way':
        return Icons.check_circle;
      default:
        return Icons.arrow_forward;
    }
  }

  Color _getButtonColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.blue;
      case 'preparing':
        return Colors.amber.shade700;
      case 'on_the_way':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pedidos para Entrega",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.amber[700],
      ),
      body: Column(
        children: [
          // Indicador de ubicación actual
          if (_isTrackingLocation)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black87,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estado del Seguimiento:',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _locationUpdateStatus,
                    style: const TextStyle(color: Colors.white),
                  ),
                  if (_lastLocation != null)
                    Text(
                      'Ubicación actual: ${_lastLocation!.latitude.toStringAsFixed(6)}, ${_lastLocation!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                ],
              ),
            ),

          // Sección del mapa (si hay un pedido seleccionado)
          if (_selectedOrderId != null && _lastLocation != null)
            SizedBox(
              height: 200,
              child: StreamBuilder<DocumentSnapshot>(
                stream: _firestore.collection('orders').doc(_selectedOrderId).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final orderData = snapshot.data!.data() as Map<String, dynamic>;
                  final customerLocation = orderData['location'] as Map<String, dynamic>;
                  final locationOrder = orderData['locationOrder'] as Map<String, dynamic>?;

                  // Depurar la ubicación del pedido
                  if (locationOrder != null) {
                    developer.log('Ubicación actual del pedido (Firestore): ${locationOrder['latitude']}, ${locationOrder['longitude']}');
                  }

                  developer.log('Ubicación del cliente: ${customerLocation['latitude']}, ${customerLocation['longitude']}');
                  developer.log('Ubicación actual del conductor: ${_lastLocation!.latitude}, ${_lastLocation!.longitude}');

                  return GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    initialCameraPosition: CameraPosition(
                      target: _lastLocation!,
                      zoom: 15,
                    ),
                    markers: {
                      // Marcador de conductor
                      Marker(
                        markerId: const MarkerId('driver'),
                        position: _lastLocation!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                        infoWindow: const InfoWindow(title: 'Tu ubicación'),
                      ),
                      // Marcador de cliente
                      Marker(
                        markerId: const MarkerId('customer'),
                        position: LatLng(customerLocation['latitude'], customerLocation['longitude']),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                        infoWindow: InfoWindow(title: 'Cliente: ${orderData['customerName']}'),
                      ),
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  );
                },
              ),
            ),

          // Lista de pedidos
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _ordersStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  developer.log('Error en el stream de órdenes: ${snapshot.error}');
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allOrders = snapshot.data!.docs;

                // Filtrar los pedidos entregados y cancelados en el cliente
                final orders = allOrders.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] as String? ?? '';
                  return status != 'delivered' && status != 'cancelled';
                }).toList();

                if (orders.isEmpty) {
                  return const Center(child: Text('No hay pedidos disponibles'));
                }

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final orderData = order.data() as Map<String, dynamic>;
                    final orderId = order.id;
                    final String status = orderData['status'] ?? 'pending';
                    final currentStep = _getStepFromStatus(status);
                    final List<dynamic> items = orderData['items'] ?? [];
                    final customerLocation = orderData['location'] as Map<String, dynamic>?;
                    final locationOrder = orderData['locationOrder'] as Map<String, dynamic>?;

                    bool canDeliver = false;
                    if (_lastLocation != null && customerLocation != null && status == 'on_the_way') {
                      // Verificar si el conductor está cerca del punto de entrega (menos de 100 metros)
                      double distance = _calculateDistance(
                        customerLocation['latitude'],
                        customerLocation['longitude'],
                      );
                      canDeliver = distance < 100;

                      if (_selectedOrderId == orderId) {
                        developer.log('Distancia al cliente para pedido $orderId: $distance metros. Puede entregar: $canDeliver');
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Pedido #${orderId.substring(0, 5)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                _buildStatusChip(status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Cliente: ${orderData['customerName']}'),
                            Text('Teléfono: ${orderData['customerPhone']}'),
                            Text('Dirección: ${orderData['customerAddress']}'),
                            Text('Notas: ${orderData['orderNotes'] ?? ''}'),
                            Text('Método de pago: ${orderData['paymentMethod']}'),
                            Text('Total: \$${orderData['totalAmount']}'),

                            // Mostrar la ubicación actual del pedido si está disponible
                            if (locationOrder != null && status == 'on_the_way')
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Ubicación actual del repartidor:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text('Lat: ${locationOrder['latitude'].toStringAsFixed(6)}'),
                                    Text('Lng: ${locationOrder['longitude'].toStringAsFixed(6)}'),
                                  ],
                                ),
                              ),

                            const Divider(),
                            Text(
                              'Productos:',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            ...items.map<Widget>((item) {
                              final itemData = item as Map<String, dynamic>;
                              return Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Row(
                                  children: [
                                    Text('${itemData['quantity']}x '),
                                    Expanded(child: Text(itemData['name'])),
                                    Text('\$${itemData['price']}'),
                                  ],
                                ),
                              );
                            }).toList(),

                            const SizedBox(height: 16),
                            _buildOrderProgress(currentStep),

                            const SizedBox(height: 16),
                            _buildActionButtons(orderId, status, canDeliver),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    String statusText;

    switch (status) {
      case 'pending':
        chipColor = Colors.orange;
        statusText = 'Pendiente';
        break;
      case 'preparing':
        chipColor = Colors.blue;
        statusText = 'En preparación';
        break;
      case 'on_the_way':
        chipColor = Colors.amber;
        statusText = 'En camino';
        break;
      case 'delivered':
        chipColor = Colors.green;
        statusText = 'Entregado';
        break;
      case 'cancelled':
        chipColor = Colors.red;
        statusText = 'Cancelado';
        break;
      default:
        chipColor = Colors.grey;
        statusText = 'Desconocido';
    }

    return Chip(
      label: Text(statusText),
      backgroundColor: chipColor.withOpacity(0.2),
      labelStyle: TextStyle(color: chipColor, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildOrderProgress(int currentStep) {
    return Stepper(
      currentStep: currentStep,
      controlsBuilder: (context, details) => Container(),
      steps: [
        Step(
          title: const Text('Preparación'),
          content: Container(),
          isActive: currentStep >= 0,
          state: currentStep > 0 ? StepState.complete : StepState.indexed,
        ),
        Step(
          title: const Text('En camino'),
          content: Container(),
          isActive: currentStep >= 1,
          state: currentStep > 1 ? StepState.complete : StepState.indexed,
        ),
        Step(
          title: const Text('Entregado'),
          content: Container(),
          isActive: currentStep >= 2,
          state: currentStep > 2 ? StepState.complete : StepState.indexed,
        ),
      ],
    );
  }

  Widget _buildActionButtons(String orderId, String status, bool canDeliver) {
    // Determinar si es el pedido actual seleccionado
    bool isSelectedOrder = orderId == _selectedOrderId;

    // Si ya hay un pedido activo y este no es el pedido seleccionado, desactivar los botones
    bool disableButton = _hasActiveOrder && !isSelectedOrder;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Botón principal que cambia según el estado
        ElevatedButton.icon(
          onPressed: disableButton
              ? null // Deshabilitar botón si ya hay un pedido activo y no es este
              : () {
            String nextStatus = _getNextStatus(status);

            if (status == 'on_the_way' && !canDeliver) {
              // Si está en camino pero no está lo suficientemente cerca para entregar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Debes estar cerca del cliente para entregar el pedido')),
              );
              return;
            }

            _updateOrderStatus(orderId, nextStatus);

            // Si cambiamos a estado entregado o cancelado, volver a cargar la lista
            if (nextStatus == 'delivered' || nextStatus == 'cancelled') {
              // Usar Future.delayed para dar tiempo a que se complete la transacción
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  _loadOrders();
                }
              });
            }
          },
          icon: Icon(_getButtonIcon(status)),
          label: Text(_getButtonText(status)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getButtonColor(status),
            disabledBackgroundColor: Colors.grey.shade400,
          ),
        ),

        // Botón de cancelar (siempre visible para pedidos activos)
        ElevatedButton.icon(
          onPressed: disableButton && status != 'on_the_way'
              ? null // Deshabilitar botón de cancelar si no es el pedido seleccionado
              : () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Cancelar Pedido'),
                content: const Text('¿Estás seguro de que deseas cancelar este pedido?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () {
                      // Primero cerramos el diálogo
                      Navigator.pop(context);
                      // Luego actualizamos el estado
                      _updateOrderStatus(orderId, 'cancelled');

                      // Usar Future.delayed para dar tiempo a que se complete la transacción
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          _loadOrders();
                        }
                      });
                    },
                    child: const Text('Sí, cancelar'),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.cancel),
          label: const Text('Cancelar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            disabledBackgroundColor: Colors.red.shade200,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Cancelar el stream de ubicación
    if (_positionStream != null) {
      _positionStream!.listen((_) {}).cancel();
    }
    _mapController?.dispose();
    developer.log('Recursos liberados en la pantalla de pedidos');
    super.dispose();
  }
}