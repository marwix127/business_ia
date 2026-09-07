import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:stronger/infrastructure/services/theme_notifier.dart';
import 'package:stronger/theme/theme.dart';

import 'firebase_options.dart';
import 'infrastructure/services/firebase/auth_state_notifier.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await _initializeFirebase();
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization failed: $error\n$stackTrace');
    runApp(const StartupErrorApp());
    return;
  }

  if (_useFirebaseEmulators) {
    await _connectFirebaseEmulators();
  } else {
    try {
      await _activateAppCheck();
    } catch (error, stackTrace) {
      debugPrint('App Check activation failed: $error\n$stackTrace');
    }
  }

  final authState = AuthStateNotifier();
  router = createRouter(authState);

  runApp(ChangeNotifierProvider.value(value: authState, child: const MyApp()));
}

const _useFirebaseEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
const _firebaseEmulatorHost = String.fromEnvironment(
  'FIREBASE_EMULATOR_HOST',
  defaultValue: '127.0.0.1',
);

Future<void> _initializeFirebase() async {
  if (_useFirebaseEmulators &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android) {
    try {
      // Local builds can already contain the native app generated from
      // google-services.json. Reusing it avoids creating a second [DEFAULT]
      // app, while a clean CI build falls back to the explicit options below.
      await Firebase.initializeApp();
      return;
    } catch (error) {
      debugPrint(
        'Native Firebase configuration unavailable in E2E mode; '
        'using explicit options ($error)',
      );
    }
  }

  if (_useFirebaseEmulators ||
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return;
  }

  await Firebase.initializeApp();
}

Future<void> _connectFirebaseEmulators() async {
  await Future.wait([
    _requireEmulator('Auth', 9099),
    _requireEmulator('Firestore', 8080),
  ]);

  await FirebaseAuth.instance.useAuthEmulator(_firebaseEmulatorHost, 9099);
  await FirebaseAuth.instance.signOut();

  final firestore = FirebaseFirestore.instance;
  firestore.settings = const Settings(persistenceEnabled: false);
  firestore.useFirestoreEmulator(_firebaseEmulatorHost, 8080);
  debugPrint('Firebase Emulator Suite connected at $_firebaseEmulatorHost');
}

Future<void> _requireEmulator(String name, int port) async {
  try {
    await http
        .get(Uri.parse('http://$_firebaseEmulatorHost:$port'))
        .timeout(const Duration(seconds: 3));
  } catch (error) {
    throw StateError(
      '$name Emulator is not reachable at '
      '$_firebaseEmulatorHost:$port ($error)',
    );
  }
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Stronger no ha podido iniciar Firebase.\n\n'
              'Comprueba la conexión y la configuración de Firebase, '
              'después cierra y vuelve a abrir la aplicación.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _activateAppCheck() async {
  if (kIsWeb) {
    const siteKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');
    if (siteKey.isEmpty) {
      debugPrint(
        'App Check web no está activo: falta RECAPTCHA_SITE_KEY. '
        'El coach IA rechazará peticiones hasta configurarla.',
      );
      return;
    }
    await FirebaseAppCheck.instance.activate(
      providerWeb: ReCaptchaV3Provider(siteKey),
    );
    return;
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      // Play Integrity solo atesta apps que Google Play reconoce, y Stronger se
      // distribuye como APK desde GitHub: en release la atestación siempre
      // devuelve 403. Como firebase_ai pide el token sin capturar el error, eso
      // dejaba al coach sin responder. Al no activar App Check en release el
      // servicio ni se registra, firebase_ai no lo consulta y la petición sale
      // sin cabecera (requiere App Check sin imponer en la consola).
      if (kDebugMode) {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: const AndroidDebugProvider(),
        );
      } else {
        debugPrint(
          'App Check desactivado en Android release: la distribución fuera de '
          'Play no puede superar Play Integrity.',
        );
      }
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      await FirebaseAppCheck.instance.activate(
        providerApple: kDebugMode
            ? const AppleDebugProvider()
            : const AppleAppAttestWithDeviceCheckFallbackProvider(),
      );
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      debugPrint('App Check no está configurado para esta plataforma.');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ThemeNotifier();
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp.router(
          title: 'Stronger',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: router,
        );
      },
    );
  }
}
