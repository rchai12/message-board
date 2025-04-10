import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'message.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> registerUser({
    required String name,
    required String email,
    required String password,
    required DateTime dateOfBirth,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'date_of_birth': Timestamp.fromDate(dateOfBirth),
          'created_at': Timestamp.now(),
        });

        await _firestore.collection('users').doc(user.uid).collection('messages').add({
          'content': '', 
          'timestamp': Timestamp.now(),
        });

        await user.updateDisplayName(name);
        await user.reload();
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logoutUser() async {
    await _auth.signOut();
  }

  Future<void> updateDisplayName(String name) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(name);
      await user.reload();

      await _firestore.collection('users').doc(user.uid).update({
        'name': name,
      });
    }
  }

  Future<void> updatePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);

        await user.updatePassword(newPassword);
        await user.reload();

        print('Password updated successfully');
      } on FirebaseAuthException catch (e) {
        throw Exception('Password update failed: ${e.message}');
      }
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  Future<User?> updateEmail({
    required String email,
    required String currentPassword,
    required String newEmail,
  }) async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);

        await user.verifyBeforeUpdateEmail(newEmail);
        await _auth.currentUser!.reload();
        print('New Email: ${_auth.currentUser!.email}');
        return _auth.currentUser;
      } on FirebaseAuthException catch (e) {
        throw Exception('Email update failed: ${e.message}');
      }
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> getUserData() async {
    User? user = _auth.currentUser;
    
    if (user != null) {
      try {
        return await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
      } catch (e) {
        throw Exception('Error fetching user data: $e');
      }
    } else {
      return null;
    }
  }

  Future<void> updateName(String newName) async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        await user.updateProfile(displayName: newName);

        await user.reload();

        print('Name updated successfully');
      } on FirebaseAuthException catch (e) {
        throw Exception('Failed to update name: ${e.message}');
      }
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  Future<List<Map<String, dynamic>>> getUserMessages(String userId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> messageSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('messages')
          .orderBy('timestamp')
          .get();
      List<Map<String, dynamic>> messages = messageSnapshot.docs.map((doc) {
        return doc.data();
      }).toList();
      return messages;
    } catch (e) {
      throw Exception('Error fetching messages: $e');
    }
  }

  Future<void> addMessageToCollection({
    required String userId,
    required String sender,
    required String text,
  }) async {
    try {
      Timestamp timestamp = Timestamp.now();
      Message message = Message(
        id: '',
        text: text,
        sender: sender,
        userId: userId,
        timestamp: timestamp,
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('messages')
          .add(message.toMap());
      await FirebaseFirestore.instance
          .collection('messages')
          .add(message.toMap());
    } catch (e) {
      throw Exception('Error adding message: $e');
    }
  }

  Future<List<Message>> getMessagesFromCollection() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .get();
      List<Message> messages = snapshot.docs.map((doc) {
        return Message.fromDoc(doc);
      }).toList();
      return messages;
    } catch (e) {
      throw Exception('Error retrieving messages: $e');
    }
  }

  User? get currentUser => _auth.currentUser;
}
