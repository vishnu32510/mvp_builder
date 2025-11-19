
import 'package:flutter/material.dart';
import 'services.dart';

class ToastService extends Services{
  static GlobalKey<NavigatorState>? _navigatorKey;

  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  static void showSuccess(String message) {
    _showToast(
      message: message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
    );
  }

  static void showError(String message) {
    _showToast(
      message: message,
      backgroundColor: Colors.red,
      icon: Icons.error,
    );
  }

  static void showInfo(String message) {
    _showToast(
      message: message,
      backgroundColor: Colors.blue,
      icon: Icons.info,
    );
  }

  static void showWarning(String message) {
    _showToast(
      message: message,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
    );
  }

  static void _showToast({
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    final context = _navigatorKey?.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }
} 