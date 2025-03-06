import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> cart = [];

  void addToCart(Map<String, dynamic> item) {
    setState(() {
      cart.add(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menú del Restaurante'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.pushNamed(context, '/cart', arguments: cart);
            },
          )
        ],
      ),
      body: StreamBuilder(
        stream: _firestore.collection('menu').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          var items = snapshot.data!.docs;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              var item = items[index].data() as Map<String, dynamic>;

              // Asegúrate de que los campos existen y no sean nulos
              String imageUrl = item['image'] ?? '';  // Usa una imagen por defecto si no hay 'image'
              String name = item['name'] ?? 'Producto desconocido';  // Valor por defecto
              double price = item['price'] ?? 0.0;  // Valor por defecto para el precio

              return Card(
                child: ListTile(
                  leading: imageUrl.isNotEmpty
                      ? Image.network(imageUrl)
                      : Icon(Icons.image),  // Icono por defecto si no hay imagen
                  title: Text(name),
                  subtitle: Text('\$${price.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: Icon(Icons.add_shopping_cart),
                    onPressed: () => addToCart(item),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
