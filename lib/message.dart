import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String text;
  final String sender;
  final String userId;
  final Timestamp timestamp;

  Message({
    required this.id,
    required this.text,
    required this.sender,
    required this.userId,
    required this.timestamp,
  });

  factory Message.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      text: data['text'],
      sender: data['sender'],
      userId: data['userId'],
      timestamp: data['timestamp'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'sender': sender,
      'userId': userId,
      'timestamp': timestamp,
    };
  }
}
