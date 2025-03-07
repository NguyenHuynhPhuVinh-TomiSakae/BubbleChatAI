import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static const String apiKeyKey = 'gemini_api_key';
  
  static Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(apiKeyKey, apiKey);
  }
  
  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(apiKeyKey);
  }
} 