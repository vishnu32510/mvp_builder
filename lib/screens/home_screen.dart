import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import '../genui/genui_conversation.dart';
import '../genui/widget_catalog.dart';
import '../services/firebase_ai_content_generator.dart';

/// Home screen with chat-like UI for MVP Builder
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final MvpGenUiConversation _conversation;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

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
        // Auto-scroll to bottom when new surfaces arrive
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
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
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MVP Builder'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Surfaces list
          Expanded(
            child: ValueListenableBuilder<List<ChatMessage>>(
              valueListenable: _conversation.conversationHistory,
              builder: (context, messages, _) {
                // Filter to get only AI UI messages with surfaces
                final surfaceMessages = messages
                    .whereType<AiUiMessage>()
                    .toList();

                if (surfaceMessages.isEmpty && messages.isEmpty) {
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
                        const SizedBox(height: 8),
                        Text(
                          'Example: "Build me a fitness app with progress tracking"',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
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

          // Input field
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

