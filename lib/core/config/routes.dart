
import 'package:flutter/material.dart';

class CustomRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    debugPrint('This is route: ${routeSettings.name}');
    switch (routeSettings.name) {
      // case SplashScreen.routeName:
        // return SplashScreen.route();

      
      // Mini-app routes
      case '/food-rescue':
      case '/transit-pass':
      case '/green-grocery':
      case '/bike-share':
      case '/solar-credits':
      case '/eco-marketplace':
      case '/carbon-impact':
        return _comingSoonRoute(routeSettings.name ?? "");
      
      default:
        return _errorRoute();
    }
  }

  static Route _comingSoonRoute(String routeName) {
    String title = _getRouteTitle(routeName);
    return MaterialPageRoute(
      settings: RouteSettings(name: routeName),
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.construction,
                  size: 80,
                  color: Colors.orange,
                ),
                const SizedBox(height: 24),
                Text(
                  'Coming Soon!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$title is under development.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Stay tuned for updates!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Cart'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _getRouteTitle(String routeName) {
    switch (routeName) {
      case '/food-rescue':
        return 'Food Rescue Network';
      case '/transit-pass':
        return 'Public Transit Pass';
      case '/green-grocery':
        return 'Green Grocery Rewards';
      case '/bike-share':
        return 'Bike Share Program';
      case '/solar-credits':
        return 'Solar Energy Credits';
      case '/eco-marketplace':
        return 'Eco Product Marketplace';
      case '/carbon-impact':
        return 'Donation Links';
      default:
        return 'Feature';
    }
  }

  static Route _errorRoute() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: '/error'),
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Center(child: Text('Error Page'))),
      ),
    );
  }
}
