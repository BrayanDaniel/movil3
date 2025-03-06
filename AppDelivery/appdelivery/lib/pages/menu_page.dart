import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'cart_page.dart';

class MenuItem {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String? description;
  final String? category;
  int quantity;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.description,
    this.category,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'description': description,
      'category': category,
    };
  }
}

class CartProvider extends ChangeNotifier {
  List<MenuItem> _items = [];

  List<MenuItem> get items => _items;

  int get itemCount => _items.length;

  double get totalAmount {
    return _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  void addItem(MenuItem menuItem) {
    final existingIndex = _items.indexWhere((item) => item.id == menuItem.id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += 1;
    } else {
      _items.add(menuItem);
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void incrementQuantity(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index].quantity += 1;
      notifyListeners();
    }
  }

  void decrementQuantity(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity -= 1;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clear() {
    _items = [];
    notifyListeners();
  }
}

class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  String _selectedCategory = 'Todos';
  late TabController _tabController;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> categories = ['Todos', 'Hamburguesas', 'Pizzas', 'Bebidas', 'Postres'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedCategory = categories[_tabController.index];
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: true);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'FoodExpress',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showSearch(
                context: context,
                delegate: MenuSearchDelegate(
                  cartProvider: cartProvider,
                  firestore: _firestore,
                ),
              );
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartPage(cartProvider: cartProvider),
                    ),
                  );
                },
              ),
              if (cartProvider.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cartProvider.itemCount}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white,
          tabs: categories.map((category) => Tab(text: category)).toList(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar en el menú',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _firestore.collection('menu').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  );
                }

                var allItems = snapshot.data!.docs;

                // Filtrar por categoría si no está en "Todos"
                var filteredItems = _selectedCategory == 'Todos'
                    ? allItems
                    : allItems.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return data['category'] == _selectedCategory;
                }).toList();

                // Filtrar por búsqueda
                if (_searchQuery.isNotEmpty) {
                  filteredItems = filteredItems.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return (data['name'] as String)
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                if (filteredItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.no_food,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No se encontraron productos',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    var item = filteredItems[index].data() as Map<String, dynamic>;
                    var docId = filteredItems[index].id;

                    String imageUrl = item['image'] ?? '';
                    String name = item['name'] ?? 'Producto desconocido';
                    double price = (item['price'] is int)
                        ? (item['price'] as int).toDouble()
                        : item['price'] ?? 0.0;
                    String description = item['description'] ?? 'Sin descripción';

                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          _showProductDetails(
                              context,
                              docId,
                              name,
                              price,
                              imageUrl,
                              description,
                              cartProvider
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                imageUrl,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 150,
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: Icon(
                                        Icons.fastfood,
                                        size: 50,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  );
                                },
                              )
                                  : Container(
                                height: 150,
                                color: Colors.grey[200],
                                child: Center(
                                  child: Icon(
                                    Icons.fastfood,
                                    size: 50,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          '\$${price.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      final menuItem = MenuItem(
                                        id: docId,
                                        name: name,
                                        price: price,
                                        imageUrl: imageUrl,
                                        description: description,
                                      );
                                      cartProvider.addItem(menuItem);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('$name añadido al carrito'),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          backgroundColor: Colors.green,
                                          duration: Duration(seconds: 2),
                                          action: SnackBarAction(
                                            label: 'Ver Carrito',
                                            textColor: Colors.white,
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => CartPage(cartProvider: cartProvider),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      elevation: 0,
                                    ),
                                    child: Icon(
                                      Icons.add_shopping_cart,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          // Navegación a otras pantallas
          if (index == 0) { // Inicio
            Navigator.of(context).pop(); // Volver a HomePage
          } else if (index == 2) { // Carrito
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartPage(cartProvider: cartProvider),
              ),
            );
          } else if (index == 3) { // Perfil
            // Aquí podría ir la navegación al perfil
            Navigator.of(context).pop(); // Volvemos a HomePage por ahora
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fastfood_outlined),
            activeIcon: Icon(Icons.fastfood),
            label: 'Menú',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined),
                if (cartProvider.itemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '${cartProvider.itemCount}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Carrito',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  void _showProductDetails(
      BuildContext context,
      String id,
      String name,
      double price,
      String imageUrl,
      String description,
      CartProvider cartProvider
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 250,
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.fastfood,
                            size: 80,
                            color: Colors.orange,
                          ),
                        ),
                      );
                    },
                  )
                      : Container(
                    height: 250,
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(
                        Icons.fastfood,
                        size: 80,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20,
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '\$${price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Descripción',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    final menuItem = MenuItem(
                      id: id,
                      name: name,
                      price: price,
                      imageUrl: imageUrl,
                      description: description,
                    );
                    cartProvider.addItem(menuItem);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name añadido al carrito'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                        action: SnackBarAction(
                          label: 'Ver Carrito',
                          textColor: Colors.white,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CartPage(cartProvider: cartProvider),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
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
                      Icon(Icons.add_shopping_cart, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Añadir al carrito',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MenuSearchDelegate extends SearchDelegate<String> {
  final CartProvider cartProvider;
  final FirebaseFirestore firestore;

  MenuSearchDelegate({required this.cartProvider, required this.firestore});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Busca por nombre de producto',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<QuerySnapshot>(
      future: firestore.collection('menu').get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          );
        }

        final allItems = snapshot.data!.docs;
        final results = allItems.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return (data['name'] as String)
              .toLowerCase()
              .contains(query.toLowerCase());
        }).toList();

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.no_food,
                  size: 80,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No se encontraron productos',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(12),
          itemCount: results.length,
          itemBuilder: (context, index) {
            var item = results[index].data() as Map<String, dynamic>;
            var docId = results[index].id;

            String imageUrl = item['image'] ?? '';
            String name = item['name'] ?? 'Producto desconocido';
            double price = (item['price'] is int)
                ? (item['price'] as int).toDouble()
                : item['price'] ?? 0.0;

            return Card(
              margin: EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.fastfood,
                          color: Colors.orange,
                          size: 30,
                        ),
                      );
                    },
                  )
                      : Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.fastfood,
                      color: Colors.orange,
                      size: 30,
                    ),
                  ),
                ),
                title: Text(
                  name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('\$${price.toStringAsFixed(2)}'),
                trailing: IconButton(
                  icon: Icon(Icons.add_circle, color: Colors.orange),
                  onPressed: () {
                    final menuItem = MenuItem(
                      id: docId,
                      name: name,
                      price: price,
                      imageUrl: imageUrl,
                    );
                    cartProvider.addItem(menuItem);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name añadido al carrito'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                onTap: () {
                  close(context, docId);
                },
              ),
            );
          },
        );
      },
    );
  }
}