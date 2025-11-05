import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TrainingDraftService {
  static const _baseKey = 'training_draft_v1';

  static String _keyForUser() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    return '$_baseKey:$uid';
  }

  Future<void> saveDraft(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyForUser(), jsonEncode(data));
  }

  Future<Map<String, dynamic>?> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyForUser());
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> removeDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyForUser());
  }
}
