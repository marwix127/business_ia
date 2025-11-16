import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'infrastructure/services/firebase/auth_state_notifier.dart';
import 'infrastructure/services/firebase/exercises_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:business_ia/infrastructure/services/theme_notifier.dart';
import 'package:business_ia/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    name: "dev project",
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final authState = AuthStateNotifier();
  router = createRouter(authState);

  EjercicioService().cargarEjerciciosInicialesSiEsNecesario();
  await dotenv.load(fileName: "variables.env");
  runApp(ChangeNotifierProvider.value(value: authState, child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final themeNotifier = ThemeNotifier();
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp.router(
          title: 'Business IA',
          debugShowCheckedModeBanner: false,

          // Temas
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,

          // Tu GoRouter
          routerConfig: router, // Reemplaza con tu configuración de router
        );
      },
    );
  }
}
