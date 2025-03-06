import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Modelo de Orden integrado en el mismo archivo
class Order {
  final String id;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String customerAddress;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String status;
  final DateTime timestamp;
  final String? orderNotes;

  Order({
    required this.id,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.customerAddress,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.timestamp,
    this.orderNotes,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Order(
      id: doc.id,
      customerName: data['customerName'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerAddress: data['customerAddress'] ?? '',
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      totalAmount: data['totalAmount'] is int
          ? (data['totalAmount'] as int).toDouble()
          : data['totalAmount'] ?? 0.0,
      status: data['status'] ?? 'pending',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      orderNotes: data['orderNotes'],
    );
  }
}

class OrderStatusPage extends StatefulWidget {
  const OrderStatusPage({Key? key}) : super(key: key);

  @override
  _OrderStatusPageState createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Estado del Pedido"),
          backgroundColor: Colors.orange,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              const Text(
                "Debes iniciar sesión para ver tus pedidos",
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text("Volver", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mis Pedidos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder<QuerySnapshot>(
        // Usado FutureBuilder en lugar de StreamBuilder para evitar el error del índice
        future: _firestore
            .collection('orders')
            .where('customerEmail', isEqualTo: currentUser.email)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_basket, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    "No tienes pedidos activos",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "¡Haz tu primer pedido!",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Ir al Menú", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          // Ordenar manualmente los documentos por fecha (más reciente primero)
          List<DocumentSnapshot> sortedDocs = List.from(snapshot.data!.docs);
          sortedDocs.sort((a, b) {
            Timestamp timestampA = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
            Timestamp timestampB = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
            return timestampB.compareTo(timestampA); // Orden descendente
          });

          List<Order> orders = sortedDocs.map((doc) => Order.fromFirestore(doc)).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderCard(context, order);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    IconData statusIcon;
    Color statusColor;
    String statusText = _getStatusText(order.status);

    switch (order.status) {
      case 'pending':
        statusIcon = Icons.hourglass_bottom;
        statusColor = Colors.orange;
        break;
      case 'preparing':
        statusIcon = Icons.restaurant;
        statusColor = Colors.orange;
        break;
      case 'on_the_way':
        statusIcon = Icons.delivery_dining;
        statusColor = Colors.blue;
        break;
      case 'delivered':
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusIcon = Icons.cancel;
        statusColor = Colors.red;
        break;
      default:
        statusIcon = Icons.hourglass_bottom;
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsPage(order: order),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pedido #${order.id.substring(0, 8)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(order.timestamp),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "\$${order.totalAmount.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Estado: $statusText",
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${order.items.length} ítem${order.items.length != 1 ? 's' : ''}",
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildStatusIndicator(order.status),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'preparing':
        return 'En preparación';
      case 'on_the_way':
        return 'En camino';
      case 'delivered':
        return 'Entregado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  Widget _buildStatusIndicator(String status) {
    int currentStep;

    switch (status) {
      case 'pending':
        currentStep = 0;
        break;
      case 'preparing':
        currentStep = 0;
        break;
      case 'on_the_way':
        currentStep = 1;
        break;
      case 'delivered':
        currentStep = 2;
        break;
      case 'cancelled':
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: Text(
              "PEDIDO CANCELADO",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      default:
        currentStep = -1;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildStepIndicator(0, currentStep >= 0, 'Preparación'),
          _buildStepConnector(currentStep >= 1),
          _buildStepIndicator(1, currentStep >= 1, 'En camino'),
          _buildStepConnector(currentStep >= 2),
          _buildStepIndicator(2, currentStep >= 2, 'Entregado'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, bool isActive, String label) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isActive ? Colors.orange : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStepIcon(step),
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.black87 : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Expanded(
      child: Container(
        height: 3,
        color: isActive ? Colors.orange : Colors.grey.shade300,
      ),
    );
  }

  IconData _getStepIcon(int step) {
    switch (step) {
      case 0:
        return Icons.restaurant;
      case 1:
        return Icons.delivery_dining;
      case 2:
        return Icons.check_circle;
      default:
        return Icons.circle;
    }
  }
}

// Página de detalles del pedido integrada con mapa de seguimiento en tiempo real
class OrderDetailsPage extends StatefulWidget {
  final Order order;

  const OrderDetailsPage({Key? key, required this.order}) : super(key: key);

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  GoogleMapController? _mapController;
  Marker? _deliveryMarker;
  LatLng _deliveryLocation = const LatLng(-0.31472, -78.44333); // Por defecto ESPE
  bool _isLoadingMap = true;

  @override
  void initState() {
    super.initState();
    // Iniciar la escucha de cambios en locationOrder
    _setupLocationListener();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // Método para configurar la escucha de cambios en la ubicación
  void _setupLocationListener() {
    FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.order.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data() as Map<String, dynamic>;
        if (data.containsKey('locationOrder')) {
          final location = data['locationOrder'] as Map<String, dynamic>;
          if (location.containsKey('latitude') && location.containsKey('longitude')) {
            setState(() {
              _deliveryLocation = LatLng(
                location['latitude'] as double,
                location['longitude'] as double,
              );
              _updateMarkerAndCamera();
              _isLoadingMap = false;
            });
          }
        }
      }
    });
  }

  // Actualizar el marcador y centrar el mapa en la nueva ubicación
  void _updateMarkerAndCamera() {
    _deliveryMarker = Marker(
      markerId: const MarkerId('delivery_location'),
      position: _deliveryLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: const InfoWindow(title: "Ubicación de entrega"),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_deliveryLocation, 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Detalles del Pedido #${widget.order.id.substring(0, 8)}"),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderStatus(),
              const SizedBox(height: 20),

              // Mapa de seguimiento en tiempo real
              _buildTrackingMap(),
              const SizedBox(height: 20),

              _buildOrderInfo(),
              const SizedBox(height: 20),
              _buildDeliveryInfo(),
              const SizedBox(height: 20),
              _buildOrderItems(),
              const SizedBox(height: 20),
              _buildOrderSummary(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingMap() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  "Seguimiento en tiempo real",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _isLoadingMap
                    ? const Center(child: CircularProgressIndicator())
                    : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _deliveryLocation,
                    zoom: 15,
                  ),
                  markers: _deliveryMarker != null ? {_deliveryMarker!} : {},
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _updateMarkerAndCamera();
                  },
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: true,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomGesturesEnabled: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (!_isLoadingMap)
              Text(
                "Ubicación actual: ${_deliveryLocation.latitude.toStringAsFixed(6)}, ${_deliveryLocation.longitude.toStringAsFixed(6)}",
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatus() {
    IconData statusIcon;
    Color statusColor;
    String statusText = _getStatusText(widget.order.status);
    String statusDescription = _getStatusDescription(widget.order.status);

    switch (widget.order.status) {
      case 'pending':
        statusIcon = Icons.hourglass_bottom;
        statusColor = Colors.orange;
        break;
      case 'preparing':
        statusIcon = Icons.restaurant;
        statusColor = Colors.orange;
        break;
      case 'on_the_way':
        statusIcon = Icons.delivery_dining;
        statusColor = Colors.blue;
        break;
      case 'delivered':
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusIcon = Icons.cancel;
        statusColor = Colors.red;
        break;
      default:
        statusIcon = Icons.hourglass_bottom;
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(statusIcon, size: 48, color: statusColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusDescription,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.order.status != 'cancelled' && widget.order.status != 'delivered')
              _buildStatusProgress(),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'preparing':
        return 'En preparación';
      case 'on_the_way':
        return 'En camino';
      case 'delivered':
        return 'Entregado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'pending':
        return 'Tu pedido ha sido recibido y está a la espera de ser confirmado por el restaurante';
      case 'preparing':
        return 'El restaurante está preparando tu pedido';
      case 'on_the_way':
        return '¡Tu pedido va en camino! Llegará en aproximadamente 15-30 minutos';
      case 'delivered':
        return 'Tu pedido ha sido entregado. ¡Buen provecho!';
      case 'cancelled':
        return 'Lo sentimos, este pedido ha sido cancelado';
      default:
        return 'Estado del pedido pendiente';
    }
  }

  Widget _buildStatusProgress() {
    int currentStep;

    switch (widget.order.status) {
      case 'pending':
        currentStep = -1;
        break;
      case 'preparing':
        currentStep = 0;
        break;
      case 'on_the_way':
        currentStep = 1;
        break;
      case 'delivered':
        currentStep = 2;
        break;
      default:
        currentStep = -1;
    }

    return Column(
      children: [
        LinearProgressIndicator(
          value: (currentStep + 2) / 3,
          backgroundColor: Colors.grey[300],
          color: Colors.orange,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildProgressStep("Preparación", 0, currentStep),
            _buildProgressStep("En camino", 1, currentStep),
            _buildProgressStep("Entregado", 2, currentStep),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressStep(String label, int step, int currentStep) {
    final isActive = step <= currentStep;
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? Colors.orange : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getStepIcon(step),
            color: Colors.white,
            size: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.black87 : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  IconData _getStepIcon(int step) {
    switch (step) {
      case 0:
        return Icons.restaurant;
      case 1:
        return Icons.delivery_dining;
      case 2:
        return Icons.check_circle;
      default:
        return Icons.circle;
    }
  }

  Widget _buildOrderInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Información del Pedido",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow("ID del Pedido", "#${widget.order.id.substring(0, 8)}"),
            _buildInfoRow(
                "Fecha y Hora",
                DateFormat('dd/MM/yyyy HH:mm').format(widget.order.timestamp)
            ),
            _buildInfoRow(
                "Número de Items",
                "${widget.order.items.length} ítem${widget.order.items.length != 1 ? 's' : ''}"
            ),
            if (widget.order.orderNotes != null && widget.order.orderNotes!.isNotEmpty)
              _buildInfoRow("Notas", widget.order.orderNotes!),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Información de Entrega",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow("Nombre", widget.order.customerName),
            _buildInfoRow("Email", widget.order.customerEmail),
            _buildInfoRow("Teléfono", widget.order.customerPhone),
            _buildInfoRow("Dirección", widget.order.customerAddress),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Productos",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.order.items.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = widget.order.items[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item['imageUrl'] != null && item['imageUrl'].toString().isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item['imageUrl'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[300],
                              child: const Icon(Icons.fastfood, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${item['quantity']}x \$${item['price'].toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "\$${(item['price'] * item['quantity']).toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Resumen",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "\$${widget.order.totalAmount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}