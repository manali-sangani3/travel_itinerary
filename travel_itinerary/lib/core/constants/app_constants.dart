import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  static const String appName = 'Travel Itinerary';
  
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3002';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3002';
    } else {
      return 'http://localhost:3002';
    }
  }

  static String get socketUrl => baseUrl;
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  static const List<String> budgetCategories = [
    'accommodation',
    'food',
    'transport',
    'activities',
    'misc',
  ];

  static const List<String> bookingTypes = [
    'flight',
    'hotel',
    'car_rental',
    'activity',
  ];

  static const List<String> docTypes = [
    'confirmation',
    'passport',
    'insurance',
    'other',
  ];

  static const List<String> tripStatuses = ['planning', 'active', 'completed'];
  static const List<String> collaboratorRoles = ['viewer', 'editor', 'admin'];
}
