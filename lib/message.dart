import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String text;
  final String sender;
  final String userId;
  final Timestamp timestamp;
  final String messageBoardId;

  Message({
    required this.id,
    required this.text,
    required this.sender,
    required this.userId,
    required this.timestamp,
    required this.messageBoardId,
  });

  factory Message.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      text: data['text'],
      sender: data['sender'],
      userId: data['userId'],
      timestamp: data['timestamp'],
      messageBoardId: data['messageBoardId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'sender': sender,
      'userId': userId,
      'timestamp': timestamp,
      'messageBoardId': messageBoardId, 
    };
  }
}
