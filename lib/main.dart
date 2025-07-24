import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/theme.dart';
import 'infrastructure/services/firebase/auth_state_notifier.dart';
import 'infrastructure/services/firebase/exercises_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final authState = AuthStateNotifier();
  router = createRouter(authState);

  EjercicioService().cargarEjerciciosInicialesSiEsNecesario();

  runApp(ChangeNotifierProvider.value(value: authState, child: MyApp()));
}

class MyApp extends StatelessWidget { 
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      title: 'Business IA App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      // home: const AuthGate()
    );
  }
}
