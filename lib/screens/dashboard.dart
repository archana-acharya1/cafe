import 'package:deskgoo_cafe/screens/home_screen.dart';
import 'package:deskgoo_cafe/screens/stock_screen.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'area_screen.dart';
import 'table_screen.dart';
import 'items_screen.dart';
import 'order_screen.dart';
import 'orders_screen.dart';
import 'home_screen.dart';

import '../services/backup_restore_service.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String selectedMenu = 'Home';

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B4513)),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFF7043)),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
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
        return OrderScreen();
      case 'Orders':
        return const OrdersScreen();
      case 'Home':
        return const HomeScreen();
      case 'Stock':
        return const StockScreen();

      default:
        return const Center(child: Text('Welcome to Deskgoo Cafe!'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFFFF7043);
    return Scaffold(
      appBar: AppBar(
        title: Text("Deskgoo Cafe - $selectedMenu",
          style: TextStyle(color: Colors.white),

        ), iconTheme: const IconThemeData(
        color: Colors.white, // all icons white
      ),
        backgroundColor: themeColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
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
                decoration: BoxDecoration(color: Color(0xFFFF7043)),
                child: Text(
                  'Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              drawerItem('Home', Icons.home),
              drawerItem('Items', Icons.fastfood),
              drawerItem('Areas', Icons.location_city),
              drawerItem('Tables', Icons.table_bar),
              drawerItem('New Order', Icons.add_shopping_cart),
              drawerItem('Orders', Icons.receipt),
              drawerItem('Stock', Icons.inventory),
            ],
          ),
        ),
      ),
      body: getMainContent(),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.backup),
              label: const Text("Backup"),
              onPressed: () async {
                try {
                  await BackupRestoreService.backupAllHive(
                      shareAfterCreate: true);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Backup completed")),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("❌ Backup failed: $e")),
                  );
                }
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.restore),
              label: const Text("Restore"),
              onPressed: () async {
                try {
                  await BackupRestoreService.restoreFromZip(
                    boxesToReopen: [
                      'users',
                      'items',
                      'areas',
                      'tables',
                      'orders',
                      'settings'
                    ],
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("♻️ Restore completed. Please restart app")),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("❌ Restore failed: $e")),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget drawerItem(String title, IconData icon) {
    final isSelected = selectedMenu == title;

    return ListTile(
      leading: Icon(icon, color: isSelected ? Color(0xFFF57C00) : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Color(0xFFF57C00) : null,
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