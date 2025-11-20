import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import '../models/saved_app.dart';
import '../genui/genui_conversation.dart';
import '../genui/genui_manager.dart';
import '../genui/widget_catalog.dart';
import '../services/firebase_ai_content_generator.dart';
import '../services/app_storage_service.dart';

/// Screen for editing a saved app with chat input
class AppEditScreen extends StatefulWidget {
  final SavedApp app;

  const AppEditScreen({super.key, required this.app});

  @override
  State<AppEditScreen> createState() => _AppEditScreenState();
}

class _AppEditScreenState extends State<AppEditScreen> {
  late final MvpGenUiConversation _conversation;
  late final GenUiManager _genUiManager;
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  final AppStorageService _storageService = AppStorageService();

  @override
  void initState() {
    super.initState();
    final catalog = WidgetCatalog.createCatalog();
    final contentGenerator = MvpFirebaseAiContentGenerator(catalog: catalog);
    _conversation = MvpGenUiConversation(contentGenerator: contentGenerator);
    _genUiManager = MvpGenUiManager().instance;
    
    // Load existing surfaces into the conversation
    _loadExistingSurfaces();
    
    // Listen to conversation updates
    _conversation.conversationHistory.addListener(() {
      if (mounted) {
        setState(() {
          _isLoading = _conversation.conversation.isProcessing.value;
        });
      }
    });
    
    // Listen to processing state
    _conversation.conversation.isProcessing.addListener(() {
      if (mounted) {
        setState(() {
          _isLoading = _conversation.conversation.isProcessing.value;
        });
      }
    });
  }

  void _loadExistingSurfaces() {
    // Recreate surfaces from saved data and add to conversation
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

        // Set the surface in the manager
        final notifier = _genUiManager.getSurfaceNotifier(surfaceId);
        notifier.value = uiDefinition;
      } catch (e) {
        debugPrint('Error loading surface: $e');
      }
    }
  }
  
  @override
  void dispose() {
    _conversation.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _messageController.clear();
    });

    try {
      await _conversation.sendRequest(UserMessage.text(message));
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _saveApp() async {
    try {
      // Get all surfaces from the conversation
      final messages = _conversation.conversationHistory.value;
      final surfaceMessages = messages.whereType<AiUiMessage>().toList();
      
      // Also get surfaces directly from the manager
      final allSurfaceIds = <String>{};
      for (final message in surfaceMessages) {
        allSurfaceIds.add(message.surfaceId);
      }
      
      // Get surfaces from manager that might not be in messages yet
      for (final surfaceId in _genUiManager.surfaces.keys) {
        allSurfaceIds.add(surfaceId);
      }

      if (allSurfaceIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No UI surfaces to save')),
        );
        return;
      }

      // Serialize surfaces
      final surfaces = <Map<String, dynamic>>[];
      for (final surfaceId in allSurfaceIds) {
        final notifier = _conversation.host.getSurfaceNotifier(surfaceId);
        final uiDefinition = notifier.value;
        if (uiDefinition != null) {
          surfaces.add(uiDefinition.toJson());
        }
      }

      // Update existing app
      final updatedApp = widget.app.copyWith(
        surfaces: surfaces,
        updatedAt: DateTime.now(),
      );

      await _storageService.saveApp(updatedApp);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('App "${updatedApp.name}" updated successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate app was updated
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving app: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit ${widget.app.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveApp,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: Column(
        children: [
          // UI surfaces area (non-scrollable, fills available space)
          Expanded(
            child: ValueListenableBuilder<List<ChatMessage>>(
              valueListenable: _conversation.conversationHistory,
              builder: (context, messages, _) {
                // Get all surface IDs from both messages and manager
                final surfaceIds = <String>{};
                final surfaceMessages = messages.whereType<AiUiMessage>().toList();
                for (final message in surfaceMessages) {
                  surfaceIds.add(message.surfaceId);
                }
                for (final surfaceId in _genUiManager.surfaces.keys) {
                  surfaceIds.add(surfaceId);
                }

                if (surfaceIds.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Send prompts to modify the app',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: surfaceIds.length,
                  itemBuilder: (context, index) {
                    final surfaceId = surfaceIds.elementAt(index);
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: GenUiSurface(
                        host: _conversation.host,
                        surfaceId: surfaceId,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),

          // Chat input area (fixed at bottom)
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Describe changes to make...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

