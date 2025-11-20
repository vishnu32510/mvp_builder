import 'package:flutter/material.dart';
import '../models/saved_app.dart';
import '../services/app_storage_service.dart';
import 'app_builder_screen.dart';
import 'app_view_screen.dart';
import 'app_edit_screen.dart';

/// Dashboard screen showing saved apps in a grid layout
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AppStorageService _storageService = AppStorageService();
  List<SavedApp> _apps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() {
      _isLoading = true;
    });
    
    final apps = await _storageService.loadApps();
    
    setState(() {
      _apps = apps;
      _isLoading = false;
    });
  }

  Future<void> _navigateToBuilder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AppBuilderScreen()),
    );
    
    // Reload apps if a new app was saved
    if (result == true) {
      _loadApps();
    }
  }

  void _navigateToView(SavedApp app) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppViewScreen(app: app),
      ),
    );
  }

  void _navigateToEdit(SavedApp app) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppEditScreen(app: app),
      ),
    );
    
    // Reload apps if app was updated
    if (result == true) {
      _loadApps();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MVP Builder'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: _apps.length + 1, // +1 for the add button
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Add button
                  return _buildAddButton();
                } else {
                  // App card
                  final app = _apps[index - 1];
                  return _buildAppCard(app);
                }
              },
            ),
    );
  }

  Widget _buildAddButton() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _navigateToBuilder,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'New App',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppCard(SavedApp app) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToView(app),
        onLongPress: () => _navigateToEdit(app),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.apps,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                app.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                'Tap to view\nLong press to edit',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

