import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:business_ia/infrastructure/services/firebase/auth_service.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  static final tabs = [
    {'icon': Icons.home, 'label': 'Inicio', 'path': '/'},
    {'icon': Icons.chat, 'label': 'IA Chat', 'path': '/ia-chat'},
    {'icon': Icons.bar_chart, 'label': 'Gráficos', 'path': '/grafics'},
  ];

  // Removed invalid getter that used 'context' outside of a method.
  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();
    final selectedIndex = tabs.indexWhere(
      (tab) => (tab['path'] == currentLocation),
    );
    final userEmail = AuthService().currentUser?.email ?? 'Usuario';
    String appBarTitle =
        tabs[selectedIndex >= 0 ? selectedIndex : 0]['label'] as String;

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(child: Text(userEmail)),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ajustes'),
              onTap: () {
                Navigator.pop(context);
                context.go('/ajustes');
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Cerrar sesión'),
              onTap: () {
                Navigator.pop(context);
                AuthService().signOut();
                context.go('/login');
              },
            ),
          ],
        ),
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex >= 0 ? selectedIndex : 0,
        onTap: (index) => context.go(tabs[index]['path'] as String),
        items: tabs
            .map(
              (tab) => BottomNavigationBarItem(
                icon: Icon(tab['icon'] as IconData),
                label: tab['label'] as String,
              ),
            )
            .toList(),
      ),
    );
  }
}
