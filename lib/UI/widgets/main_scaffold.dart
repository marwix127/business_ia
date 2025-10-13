import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:business_ia/infrastructure/services/firebase/auth_service.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  static final tabs = [
    {'icon': Icons.home, 'label': 'Inicio', 'path': '/'},
    {'icon': Icons.chat, 'label': 'Coach IA', 'path': '/ia-chat'},
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
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 50, 47, 56),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: AuthService().currentUser?.photoURL != null
                        ? NetworkImage(AuthService().currentUser!.photoURL!)
                        : null,
                    child: AuthService().currentUser?.photoURL == null
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(userEmail, style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Ejercicios'),
              onTap: () {
                context.push('/exercise-list');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ajustes'),
              onTap: () {
                context.push('/ajustes');
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Cerrar sesión'),
              onTap: () {
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
        selectedItemColor: const Color.fromARGB(255, 86, 73, 202),
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
