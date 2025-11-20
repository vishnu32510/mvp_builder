import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_app.dart';

/// Service for saving and loading saved apps using SharedPreferences
class AppStorageService {
  static const String _appsKey = 'saved_apps';

  /// Save or update an app
  Future<void> saveApp(SavedApp app) async {
    final prefs = await SharedPreferences.getInstance();
    final apps = await loadApps();
    
    // Remove existing app with same id if it exists
    apps.removeWhere((a) => a.id == app.id);
    
    // Add updated app
    apps.add(app);
    
    // Save to preferences
    final appsJson = apps.map((a) => a.toJson()).toList();
    await prefs.setString(_appsKey, jsonEncode(appsJson));
  }

  /// Load all saved apps
  Future<List<SavedApp>> loadApps() async {
    final prefs = await SharedPreferences.getInstance();
    final appsJsonString = prefs.getString(_appsKey);
    
    if (appsJsonString == null) {
      return [];
    }
    
    try {
      final List<dynamic> appsJson = jsonDecode(appsJsonString);
      return appsJson.map((json) => SavedApp.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get a specific app by ID
  Future<SavedApp?> getApp(String appId) async {
    final apps = await loadApps();
    try {
      return apps.firstWhere((app) => app.id == appId);
    } catch (e) {
      return null;
    }
  }

  /// Delete an app
  Future<void> deleteApp(String appId) async {
    final prefs = await SharedPreferences.getInstance();
    final apps = await loadApps();
    
    apps.removeWhere((app) => app.id == appId);
    
    final appsJson = apps.map((a) => a.toJson()).toList();
    await prefs.setString(_appsKey, jsonEncode(appsJson));
  }

  /// Generate next app name (app1, app2, etc.)
  Future<String> generateNextAppName() async {
    final apps = await loadApps();
    final count = apps.length + 1;
    return 'app$count';
  }
}

