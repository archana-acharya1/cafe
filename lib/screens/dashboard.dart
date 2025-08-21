import 'package:flutter/material.dart';
import 'login_page.dart';
import 'area_screen.dart';
import 'table_screen.dart';
import 'items_screen.dart';
import 'order_screen.dart';
import 'orders_screen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String selectedMenu = 'Items';

  void logout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Widget getMainContent() {
    switch (selectedMenu) {
      case 'Items':
        return const ItemsScreen();
      case 'Areas':
        return const AreaScreen();
      case 'Tables':
        return const TableScreen();
      case 'New Order':
        return const OrderScreen();
      case 'Orders':
        return const OrdersScreen();
      default:
        return const Center(child: Text('Welcome to Deskgoo Cafe!'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Deskgoo Cafe - $selectedMenu"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          )
        ],
      ),
      drawer: SizedBox(
        width: 180,
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue),
                child: Text(
                  'Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              drawerItem('Items', Icons.fastfood),
              drawerItem('Areas', Icons.location_city),
              drawerItem('Tables', Icons.table_bar),
              drawerItem('New Order', Icons.add_shopping_cart),
              drawerItem('Orders', Icons.receipt),
            ],
          ),
        ),
      ),
      body: getMainContent(),
    );
  }

  Widget drawerItem(String title, IconData icon) {
    bool isSelected = selectedMenu == title;

    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.blue : null,
        ),
      ),
      selected: isSelected,
      onTap: () {
        setState(() {
          selectedMenu = title;
        });
        Navigator.pop(context);
      },
    );
  }
}
