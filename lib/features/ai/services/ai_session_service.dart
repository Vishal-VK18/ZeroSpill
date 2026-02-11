import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_session_model.dart';
import '../models/ai_message.dart';

class AiSessionService {
  static const String _storageKey = 'ai_chat_sessions';
  static const int _maxSessions = 5;

  Future<void> saveSession(AiSession session) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> sessionsJson = prefs.getStringList(_storageKey) ?? [];
    
    List<AiSession> sessions = sessionsJson
        .map((s) => AiSession.fromMap(jsonDecode(s)))
        .toList();

    // Check if session with same ID exists and update it
    final index = sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      sessions[index] = session;
    } else {
      sessions.insert(0, session); // Add new to top
    }

    // Trim to max sessions
    if (sessions.length > _maxSessions) {
      sessions = sessions.sublist(0, _maxSessions);
    }

    // Save back
    sessionsJson = sessions.map((s) => jsonEncode(s.toMap())).toList();
    await prefs.setStringList(_storageKey, sessionsJson);
  }

  Future<List<AiSession>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getStringList(_storageKey) ?? [];
    
    return sessionsJson
        .map((s) => AiSession.fromMap(jsonDecode(s)))
        .toList();
  }

  Future<AiSession?> getLastSession() async {
    final sessions = await getSessions();
    if (sessions.isNotEmpty) {
      return sessions.first;
    }
    return null;
  }
  
  Future<void> deleteSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> sessionsJson = prefs.getStringList(_storageKey) ?? [];
    
    List<AiSession> sessions = sessionsJson
        .map((s) => AiSession.fromMap(jsonDecode(s)))
        .toList();
        
    sessions.removeWhere((s) => s.id == sessionId);
    
    sessionsJson = sessions.map((s) => jsonEncode(s.toMap())).toList();
    await prefs.setStringList(_storageKey, sessionsJson);
  }
}
