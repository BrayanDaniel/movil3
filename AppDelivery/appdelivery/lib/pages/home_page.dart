import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pruebafirebase/auth.dart';
import 'package:pruebafirebase/pages/livetracking_page.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_page.dart';
import 'menu_page.dart';
import 'order_status_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = Auth().currentUser;
  int _selectedIndex = 0;

  Future<void> signOut() async {
    await Auth().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        title: Row(
          children: [
            Image.network(
              'https://play-lh.googleusercontent.com/pta6_htPZffFjO9cvFGmwPsLTEPY4nkOzsOubmusuZhLhUstu2ouaFb-o-gH33hmLQ',
              height: 40,
              width: 40,
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: "Food",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: "Express",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Acción para notificaciones
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _welcomeSection(),
              const SizedBox(height: 24),
              _featuredSection(context),
              const SizedBox(height: 24),
              _quickActions(context),
              const SizedBox(height: 24),
              _recentOrdersSection(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.fastfood_outlined),
            activeIcon: Icon(Icons.fastfood),
            label: 'Menú',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Carrito',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Inicio - ya estamos aquí
        break;
      case 1: // Menú
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MenuPage())
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
      case 2: // Carrito
        try {
          final cartProvider = Provider.of<CartProvider>(context, listen: false);
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CartPage(cartProvider: cartProvider))
          ).then((_) => setState(() => _selectedIndex = 0));
        } catch (e) {
          // Si no está disponible el CartProvider, muestra un mensaje
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El carrito aún no está disponible'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _selectedIndex = 0);
        }
        break;
      case 3: // Perfil
        _showProfileOptions(context);
        break;
    }
  }

  Widget _welcomeSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.orange,
              child: Icon(Icons.person, size: 30, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¡Bienvenido!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'Usuario',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: () {
                _confirmSignOut(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _featuredSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Promociones destacadas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _promoCard(
                context,
                'https://img.freepik.com/free-photo/delicious-burger-with-many-ingredients-isolated-white-background-tasty-cheeseburger-splash-sauce_90220-1266.jpg',
                '50% OFF',
                'En hamburguesas dobles',
                    () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MenuPage())
                  );
                },
              ),
              _promoCard(
                context,
                'https://img.freepik.com/free-photo/top-view-pepperoni-pizza-with-mushroom-sausages-bell-pepper-olive-corn-black-wooden_141793-2158.jpg',
                '2x1',
                'En pizzas medianas',
                    () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MenuPage())
                  );
                },
              ),
              _promoCard(
                context,
                'https://img.freepik.com/free-photo/side-view-shawarma-with-fried-potatoes-board-cookware_176474-3215.jpg',
                'GRATIS',
                'Bebida con tu combo',
                    () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MenuPage())
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _promoCard(BuildContext context, String imageUrl, String promoText, String promoDescription, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Imagen
              Positioned.fill(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              // Overlay oscuro
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Texto de promoción
              Positioned(
                bottom: 16,
                left: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      promoText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      promoDescription,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones rápidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _actionButton(
              context,
              Icons.restaurant_menu,
              'Menú',
                  () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MenuPage())
                );
              },
            ),
            _actionButton(
              context,
              Icons.shopping_cart,
              'Carrito',
                  () {
                try {
                  final cartProvider = Provider.of<CartProvider>(context, listen: false);
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CartPage(cartProvider: cartProvider))
                  );
                } catch (e) {
                  // Si no está disponible el CartProvider, muestra un mensaje
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El carrito aún no está disponible'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
            ),
            _actionButton(
              context,
              Icons.delivery_dining,
              'Pedidos',
                  () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OrderStatusPage())
                );
              },
            ),
            //Eliminé un botón
          ],
        ),
      ],
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.orange,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentOrdersSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userEmail', isEqualTo: user?.email)
          .orderBy('timestamp', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox(); // No mostrar nada si no hay pedidos
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pedidos recientes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final String orderId = data['orderId'] ?? 'Sin ID';
              final String items = data['items'] ?? 'Sin detalles';
              final String status = data['status'] ?? 'Desconocido';

              // Convertir timestamp a fecha legible
              DateTime? date;
              if (data['timestamp'] != null) {
                if (data['timestamp'] is Timestamp) {
                  date = (data['timestamp'] as Timestamp).toDate();
                }
              }
              final dateStr = date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : 'Fecha desconocida';

              // Determinar color según estado
              Color statusColor;
              switch (status.toLowerCase()) {
                case 'entregado':
                  statusColor = Colors.green;
                  break;
                case 'en proceso':
                  statusColor = Colors.blue;
                  break;
                case 'preparando':
                  statusColor = Colors.orange;
                  break;
                case 'cancelado':
                  statusColor = Colors.red;
                  break;
                default:
                  statusColor = Colors.grey;
              }

              return _orderCard(
                context,
                orderId,
                items,
                status,
                dateStr,
                statusColor,
                    () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => OrderStatusPage())
                  );
                },
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _orderCard(
      BuildContext context,
      String orderNumber,
      String items,
      String status,
      String date,
      Color statusColor,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Colors.orange,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          orderNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          date,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      items,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 5,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mi Perfil',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'Correo no disponible',
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
            const SizedBox(height: 24),
            _profileMenuItem(
              icon: Icons.person_outline,
              title: 'Editar perfil',
              onTap: () {
                Navigator.pop(context);
                // Navegar a pantalla de editar perfil
              },
            ),
            _profileMenuItem(
              icon: Icons.location_on_outlined,
              title: 'Mis direcciones',
              onTap: () {
                Navigator.pop(context);
                // Navegar a pantalla de direcciones
              },
            ),
            _profileMenuItem(
              icon: Icons.payment_outlined,
              title: 'Métodos de pago',
              onTap: () {
                Navigator.pop(context);
                // Navegar a pantalla de métodos de pago
              },
            ),
            _profileMenuItem(
              icon: Icons.history,
              title: 'Historial de pedidos',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OrderStatusPage())
                );
              },
            ),
            _profileMenuItem(
              icon: Icons.logout,
              title: 'Cerrar sesión',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _confirmSignOut(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color ?? Colors.grey[800],
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}