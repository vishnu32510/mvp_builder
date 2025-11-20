import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import '../genui/genui_conversation.dart';
import '../genui/widget_catalog.dart';
import '../services/firebase_ai_content_generator.dart';
import '../services/app_storage_service.dart';
import '../models/saved_app.dart';

/// Screen for building a new app with full-screen UI and chat input
class AppBuilderScreen extends StatefulWidget {
  const AppBuilderScreen({super.key});

  @override
  State<AppBuilderScreen> createState() => _AppBuilderScreenState();
}

class _AppBuilderScreenState extends State<AppBuilderScreen> {
  late final MvpGenUiConversation _conversation;
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  final AppStorageService _storageService = AppStorageService();

  @override
  void initState() {
    super.initState();
    final catalog = WidgetCatalog.createCatalog();
    final contentGenerator = MvpFirebaseAiContentGenerator(catalog: catalog);
    _conversation = MvpGenUiConversation(contentGenerator: contentGenerator);
    
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
      
      if (surfaceMessages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No UI surfaces to save')),
        );
        return;
      }

      // Serialize surfaces
      final surfaces = <Map<String, dynamic>>[];
      for (final message in surfaceMessages) {
        final notifier = _conversation.host.getSurfaceNotifier(message.surfaceId);
        final uiDefinition = notifier.value;
        if (uiDefinition != null) {
          surfaces.add(uiDefinition.toJson());
        }
      }

      // Generate app name
      final appName = await _storageService.generateNextAppName();

      // Create and save app
      final app = SavedApp(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: appName,
        surfaces: surfaces,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _storageService.saveApp(app);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('App "$appName" saved successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate app was saved
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
        title: const Text('Build App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveApp,
            tooltip: 'Save App',
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
                final surfaceMessages = messages
                    .whereType<AiUiMessage>()
                    .toList();

                if (surfaceMessages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Describe your app idea to get started',
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
                  itemCount: surfaceMessages.length,
                  itemBuilder: (context, index) {
                    final message = surfaceMessages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: GenUiSurface(
                        host: _conversation.host,
                        surfaceId: message.surfaceId,
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
                          hintText: 'Describe your app idea...',
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

