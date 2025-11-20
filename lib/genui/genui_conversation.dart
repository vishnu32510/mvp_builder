import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'genui_manager.dart';
import '../services/firebase_ai_content_generator.dart';

/// Manages GenUI conversation state and interactions
class MvpGenUiConversation {
  late final GenUiConversation conversation;
  final MvpFirebaseAiContentGenerator contentGenerator;

  MvpGenUiConversation({required this.contentGenerator}) {
    final genUiManager = MvpGenUiManager().instance;
    conversation = GenUiConversation(
      genUiManager: genUiManager,
      contentGenerator: contentGenerator.generator,
    );
  }

  /// Send a user message and get AI response
  Future<void> sendRequest(ChatMessage message) async {
    await conversation.sendRequest(message);
  }

  /// Get the conversation history
  ValueListenable<List<ChatMessage>> get conversationHistory => conversation.conversation;

  /// Get the host for surfaces
  GenUiHost get host => conversation.host;

  /// Dispose resources
  void dispose() {
    conversation.dispose();
  }
}

