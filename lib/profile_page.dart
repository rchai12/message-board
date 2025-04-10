import 'login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'authentication.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  User user;
  final AuthService _authService = AuthService();

  ProfilePage({super.key, required this.user});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController = TextEditingController();
  DateTime? _dob;
  bool _isEditingName = false;
  bool _isEditingDob = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    try {
      DocumentSnapshot<Map<String, dynamic>>? userDoc =
          await widget._authService.getUserData();
      if (userDoc != null && userDoc.exists) {
        var userData = userDoc.data()!;
        widget.user = FirebaseAuth.instance.currentUser!;
        _nameController = TextEditingController(text: userData['name']);
        _dob = (userData['dob'] as Timestamp).toDate();
        setState(() {});
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateName() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget._authService.updateName(_nameController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name updated successfully')),
      );
      setState(() {
        _isEditingName = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateDob(DateTime newDob) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update({'dob': Timestamp.fromDate(newDob)});
      setState(() {
        _dob = newDob;
        _isEditingDob = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Date of birth updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating DOB: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await widget._authService.logoutUser();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      print('Error logging out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  Future<void> _pickDob() async {
    DateTime initialDate = _dob ?? DateTime(2000);
    DateTime firstDate = DateTime(1900);
    DateTime lastDate = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      await _updateDob(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDob = _dob != null ? DateFormat.yMMMd().format(_dob!) : 'Not set';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _isEditingName
              ? Column (
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Full Name'),
                    ),
                    ElevatedButton(
                      onPressed: _updateName,
                      child: _isLoading
                          ? CircularProgressIndicator()
                          : Text('Save Name'),
                    ),
                  ],
                )
              : ListTile(
                  title: Text('Full Name: ${_nameController.text}'),
                  trailing: IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      setState(() {
                        _isEditingName = true;
                      });
                    },
                  ),
                ),
            const SizedBox(height: 16),
            ListTile(
              title: Text('Date of Birth: $formattedDob'),
              trailing: IconButton(
                icon: Icon(Icons.calendar_today),
                onPressed: _pickDob,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await widget._authService.currentUser!.reload();
                widget.user = widget._authService.currentUser!;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Account Reloaded')),
                );
              },
              child: Text('Refresh Account'),
            ),
          ],
        ),
      ),
    );
  }
}
