import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:business_ia/infrastructure/services/firebase/auth_service.dart';
import 'package:business_ia/infrastructure/services/theme_notifier.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  static final tabs = [
    {'icon': Icons.home, 'label': 'Inicio', 'path': '/'},
    {'icon': Icons.chat, 'label': 'Coach IA', 'path': '/ia-chat'},
    {'icon': Icons.bar_chart, 'label': 'Gráficos', 'path': '/grafics'},
  ];

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();
    final selectedIndex = tabs.indexWhere(
      (tab) => (tab['path'] == currentLocation),
    );
    final userEmail = AuthService().currentUser?.email ?? 'Usuario';
    String appBarTitle =
        tabs[selectedIndex >= 0 ? selectedIndex : 0]['label'] as String;

    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final themeNotifier = ThemeNotifier();

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: colorScheme.surface.withAlpha(240),
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
                  Text(
                    userEmail,
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Ejercicios'),
              selected: currentLocation == '/exercise-list',
              selectedColor: colorScheme.primary,
              selectedTileColor: colorScheme.primary.withAlpha(31),
              onTap: () {
                context.push('/exercise-list');
              },
            ),
            // Switch de tema
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, themeMode, _) {
                final isDark =
                    themeMode == ThemeMode.dark ||
                    (themeMode == ThemeMode.system &&
                        brightness == Brightness.dark);

                return ListTile(
                  leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                  title: const Text('Tema oscuro'),
                  trailing: Switch(
                    value: isDark,
                    onChanged: (_) => themeNotifier.toggleTheme(brightness),
                  ),
                );
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
            ListTile(
              leading: const Icon(Icons.accessibility_new),
              title: const Text('Datos Corporales'),
              selected: currentLocation == '/body-measurements',
              selectedColor: colorScheme.primary,
              selectedTileColor: colorScheme.primary.withAlpha(31),
              onTap: () {
                context.push('/body-measurements');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ajustes'),
              selected: currentLocation == '/settings',
              selectedColor: colorScheme.primary,
              selectedTileColor: colorScheme.primary.withAlpha(31),
              onTap: () {
                context.push('/settings');
              },
            ),
          ],
        ),
      ),
      body: child,
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: const Color.fromARGB(0, 0, 0, 0),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          enableFeedback: false,
          currentIndex: selectedIndex >= 0 ? selectedIndex : 0,
          onTap: (index) => context.go(tabs[index]['path'] as String),
          selectedItemColor: colorScheme.onSurface.withAlpha(153),
          unselectedItemColor: colorScheme.primary,
          items: tabs
              .map(
                (tab) => BottomNavigationBarItem(
                  icon: Icon(tab['icon'] as IconData),
                  label: tab['label'] as String,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
