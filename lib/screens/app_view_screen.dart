import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import '../models/saved_app.dart';
import '../genui/genui_manager.dart';

/// Screen for viewing a saved app in read-only mode
class AppViewScreen extends StatefulWidget {
  final SavedApp app;

  const AppViewScreen({super.key, required this.app});

  @override
  State<AppViewScreen> createState() => _AppViewScreenState();
}

class _AppViewScreenState extends State<AppViewScreen> {
  late final GenUiManager _genUiManager;
  late final Map<String, ValueNotifier<UiDefinition?>> _surfaceNotifiers;

  @override
  void initState() {
    super.initState();
    _genUiManager = MvpGenUiManager().instance;
    _surfaceNotifiers = {};
    _loadSurfaces();
  }

  void _loadSurfaces() {
    // Recreate surfaces from saved data
    for (final surfaceJson in widget.app.surfaces) {
      try {
        final surfaceId = surfaceJson['surfaceId'] as String;
        final rootComponentId = surfaceJson['rootComponentId'] as String?;
        final componentsJson = surfaceJson['components'] as Map<String, dynamic>;
        
        // Convert components JSON back to Component objects
        final components = <String, Component>{};
        for (final entry in componentsJson.entries) {
          final componentJson = entry.value as Map<String, dynamic>;
          // Component.fromJson expects the JSON structure from toJson()
          components[entry.key] = Component.fromJson(componentJson);
        }

        // Create UiDefinition
        final uiDefinition = UiDefinition(
          surfaceId: surfaceId,
          rootComponentId: rootComponentId,
          components: components,
        );

        // Get or create notifier and set value
        final notifier = _genUiManager.getSurfaceNotifier(surfaceId);
        notifier.value = uiDefinition;
        _surfaceNotifiers[surfaceId] = notifier;
      } catch (e) {
        debugPrint('Error loading surface: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.app.name),
      ),
      body: widget.app.surfaces.isEmpty
          ? const Center(
              child: Text('No UI surfaces to display'),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.app.surfaces.length,
              itemBuilder: (context, index) {
                final surfaceJson = widget.app.surfaces[index];
                final surfaceId = surfaceJson['surfaceId'] as String;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: GenUiSurface(
                    host: _genUiManager,
                    surfaceId: surfaceId,
                  ),
                );
              },
            ),
    );
  }
}

