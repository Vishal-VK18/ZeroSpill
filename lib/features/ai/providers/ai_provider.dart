import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/ai_message.dart';
import '../models/ai_session_model.dart';
import '../services/ai_service.dart';
import '../services/ai_session_service.dart';

class AiProvider extends ChangeNotifier {
  final AiService _aiService = AiService();
  final AiSessionService _sessionService = AiSessionService();
  final List<AiMessage> _messages = [];
  bool _isLoading = false;
  final Uuid _uuid = const Uuid();
  
  String? _currentSessionId;

  List<AiMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  
  bool _hasStartedChat = false;
  bool get hasStartedChat => _hasStartedChat;

  AiProvider() {
    _loadLastSession();
  }
  
  Future<void> _loadLastSession() async {
    final session = await _sessionService.getLastSession();
    if (session != null) {
      _currentSessionId = session.id;
      _messages.addAll(session.messages);
      // Do NOT set _hasStartedChat = true here. 
      // We want to start on the Launch Screen.
      _hasStartedChat = false; 
      notifyListeners();
    }
  }

  void startChat() {
    // This is called if we just want to "continue" or if explicit.
    // If we have messages/session, just show chat.
    // If not, start new.
    if (_currentSessionId == null) {
       _currentSessionId = _uuid.v4();
    }
    _hasStartedChat = true;
    notifyListeners();
  }
  
  void startNewChat() {
    // Force save old if exists (sanity check, usually saved on message)
    _saveCurrentSession();
    
    _currentSessionId = _uuid.v4();
    _messages.clear();
    _hasStartedChat = true;
    notifyListeners();
  }
  
  Future<void> loadSession(String sessionId) async {
    await _saveCurrentSession();
    
    final sessions = await _sessionService.getSessions();
    final session = sessions.firstWhere((s) => s.id == sessionId, orElse: () => sessions.first);
    
    _currentSessionId = session.id;
    _messages.clear();
    _messages.addAll(session.messages);
    _hasStartedChat = true;
    notifyListeners();
  }

  Future<void> resetChat() {
      // Actually "Go to Home/Launch"
      return _saveCurrentSession().then((_) {
          _hasStartedChat = false; // Show launch screen
          notifyListeners();
      });
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!_hasStartedChat) {
      // If sending from somewhere else? or just failsafe
      startChat();
    }
    
    if (_currentSessionId == null) {
        _currentSessionId = _uuid.v4();
    }

    _messages.add(AiMessage(
      id: _uuid.v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _isLoading = true;
    notifyListeners();

    // Fake delay for typing indicator
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final response = await _aiService.generateResponse(text, user.uid);
      _messages.add(response);
    } catch (e) {
      _messages.add(AiMessage(
        id: _uuid.v4(),
        text: "Sorry, I encountered an error. Please try again.",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
      _saveCurrentSession();
    }
  }

  Future<void> _saveCurrentSession() async {
    if (_currentSessionId != null && _messages.isNotEmpty) {
      final session = AiSession(
        id: _currentSessionId!,
        createdAt: DateTime.now(),
        messages: _messages,
      );
      await _sessionService.saveSession(session);
    }
  }

  void clearSession() {
    _messages.clear();
    _currentSessionId = _uuid.v4();
    notifyListeners();
  }
  
  Future<void> deleteSession(String sessionId) async {
    await _sessionService.deleteSession(sessionId);
    if (_currentSessionId == sessionId) {
        _currentSessionId = null;
        _messages.clear();
        _hasStartedChat = false;
    }
    notifyListeners();
  }
}
