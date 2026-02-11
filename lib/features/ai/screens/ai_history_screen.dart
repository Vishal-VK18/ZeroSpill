import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/ai_provider.dart';
import '../models/ai_session_model.dart';
import '../services/ai_session_service.dart';

class AiHistoryScreen extends StatefulWidget {
  const AiHistoryScreen({super.key});

  @override
  State<AiHistoryScreen> createState() => _AiHistoryScreenState();
}

class _AiHistoryScreenState extends State<AiHistoryScreen> {
  final AiSessionService _sessionService = AiSessionService();
  late Future<List<AiSession>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = _sessionService.getSessions();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text("Chat History", style: TextStyle(color: colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: FutureBuilder<List<AiSession>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
             return Center(
               child: Text("No history yet.", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))),
             );
          }
          
          final sessions = snapshot.data!;
          
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final session = sessions[index];
              final firstMsg = session.messages.isNotEmpty 
                  ? session.messages.firstWhere((m) => m.isUser).text 
                  : "New Conversation";
              final date = DateFormat.yMMMd().add_jm().format(session.createdAt);
              
              return ListTile(
                tileColor: colorScheme.surfaceContainerHighest?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(
                  firstMsg, 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(date),
                leading: Icon(Icons.chat_bubble_outline, color: colorScheme.primary),
                onTap: () {
                  context.read<AiProvider>().loadSession(session.id);
                  Navigator.pop(context); // Close history
                  // AiMainScreen will see hasStartedChat=true and show ChatScreen
                },
                onLongPress: () {
                  showDialog(
                    context: context, 
                    builder: (ctx) => AlertDialog(
                      title: const Text("Delete Chat?"),
                      content: const Text("Are you sure you want to delete this conversation?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx), 
                          child: const Text("Cancel")
                        ),
                        TextButton(
                          onPressed: () async {
                            await context.read<AiProvider>().deleteSession(session.id);
                            Navigator.pop(ctx);
                            setState(() {
                                // Refresh the list
                                _sessionsFuture = _sessionService.getSessions();
                            });
                          },
                          child: const Text("Delete", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    )
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
