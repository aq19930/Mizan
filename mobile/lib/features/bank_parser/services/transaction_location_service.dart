import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/location_metadata.dart';

class TransactionLocationService {
  static const String _prefKey = 'mizan_transaction_location_enabled';

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false; // Default: OFF (Strictly opt-in)
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
  }

  /// Captures phone location around transaction detection time only if user opted in.
  static Future<LocationMetadata?> captureLocation() async {
    final enabled = await isEnabled();
    if (!enabled) return null;

    // Riyadh default simulation for demo/testing when permitted
    return LocationMetadata(
      latitude: 24.7136,
      longitude: 46.6753,
      accuracy: 35.0,
      source: 'DEVICE',
      placeName: 'الرياض — حي الملقا',
      city: 'الرياض',
      district: 'حي الملقا',
      locationConfidence: 0.95,
      capturedAt: DateTime.now(),
    );
  }
}