import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthStateNotifier extends ChangeNotifier {
  User? user;
  bool initialized = false;

  AuthStateNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((u) {
      user = u;
      initialized = true;
      notifyListeners();
    });
  }

  bool get isLoggedIn => user != null;
}
