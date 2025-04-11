import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:message_board/home_page.dart';
import 'message.dart';
import 'package:intl/intl.dart';
import 'authentication.dart';

class MessageBoardPage extends StatefulWidget {
  User user;
  final AuthService authService;
  final String messageBoardId;
  final String imageUrl;
  MessageBoardPage({super.key,
    required this.user,
    required this.authService,
    required this.messageBoardId,
    required this.imageUrl,
  });

  @override
  _MessageBoardPageState createState() => _MessageBoardPageState();
}

class _MessageBoardPageState extends State<MessageBoardPage> {
  late Future<List<Message>> _messagesFuture;
  late bool _isAdmin = false;
  TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _checkIfAdmin();
  }

  void _loadMessages() {
    setState(() {
      _messagesFuture = widget.authService.getMessagesFromCollection(messageBoardId: widget.messageBoardId);
    });
  }

  Future<void> _checkIfAdmin() async {
    try {
      DocumentSnapshot<Map<String, dynamic>>? userData = await widget.authService.getUserData();
      if (userData != null && userData.exists) {
        String role = userData.data()?['role'] ?? '';
        setState(() {
          _isAdmin = role == 'admin';
        });
      }
    } catch (e) {
      print('Error checking admin status: $e');
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context, false)),
          TextButton(child: const Text('Delete'), onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.authService.deleteMessage(
          messageBoardId: widget.messageBoardId,
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

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;
    try {
      await widget.authService.addMessageToCollection(
        userId: widget.user.uid,
        sender: widget.user.displayName ?? 'Unknown User',
        text: _messageController.text,
        messageBoardId: widget.messageBoardId,
      );
      _messageController.clear();
      _loadMessages();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Message sent.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Board'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.dstATop),
            child: Image.network(
              widget.imageUrl,
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
            ),
          ),
          Column(
            children: [
              Expanded(
                child: FutureBuilder<List<Message>>(
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
                        final canDelete = _isAdmin || message.userId == widget.user.uid;
                        final listTile = ListTile(
                          title: Text('${message.sender}: ${message.text}'),
                          subtitle: Text(
                            DateFormat.yMMMd().add_jm().format(message.timestamp.toDate()),
                          ),
                        );
                        return canDelete
                            ? Dismissible(
                                key: Key(message.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                confirmDismiss: (_) async {
                                  await _deleteMessage(message.id);
                                  return false;
                                },
                                child: listTile,
                              )
                            : listTile;
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Enter your message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        maxLines: 3,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}