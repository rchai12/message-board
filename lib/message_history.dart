import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'message.dart';
import 'authentication.dart';

class MessageHistoryPage extends StatefulWidget {
  final User user;
  final AuthService authService;

  const MessageHistoryPage({
    super.key,
    required this.user,
    required this.authService,
  });

  @override
  State<MessageHistoryPage> createState() => _MessageHistoryPageState();
}

class _MessageHistoryPageState extends State<MessageHistoryPage> {
  late Future<List<Message>> _messagesFuture;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    setState(() {
      _messagesFuture = widget.authService.getUserMessages(widget.user.uid);
    });
  }

  Future<void> _deleteMessage(String messageId, String messageBoardId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.authService.deleteMessage(
          messageBoardId: messageBoardId,
          messageId: messageId,
          userId: widget.user.uid,
        );
        _loadMessages();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Message deleted.')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Message History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<List<Message>>(
        future: _messagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text('No messages found.'));
          final messages = snapshot.data!;
          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return Dismissible(
                key: Key(message.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  await _deleteMessage(message.id, message.messageBoardId);
                  return false;
                },
                child: ListTile(
                  title: Text(message.text),
                  subtitle: Text(
                    DateFormat.yMMMd().add_jm().format(message.timestamp.toDate()),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
