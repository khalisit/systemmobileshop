import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Replace these with your actual Supabase URL & Anon Key when ready
  static const String supabaseUrl = 'https://gnvtnviwtyvxjfkhncha.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_FHBqMTu9HUg3Yr8zsKXHCQ_Ed29EckL';

  static bool isConfigured() {
    return !supabaseUrl.contains('YOUR_SUPABASE_URL') &&
        !supabaseAnonKey.contains('YOUR_SUPABASE_ANON_KEY');
  }

  static Future<void> init() async {
    if (isConfigured()) {
      try {
        await Supabase.initialize(
          url: supabaseUrl,
          publishableKey: supabaseAnonKey,
        );
      } catch (e) {
        debugPrint('Supabase initialization error: $e');
      }
    } else {
      debugPrint('Supabase not configured yet.');
    }
  }
}
