import 'login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'authentication.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  User user;
  final AuthService _authService = AuthService();

  ProfilePage({super.key, required this.user});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController = TextEditingController();
  late TextEditingController _emailController = TextEditingController();
  late final TextEditingController _passwordController = TextEditingController();
  late final TextEditingController _newEmailController = TextEditingController();
  late final TextEditingController _newPasswordController = TextEditingController();

  bool _isEditingName = false;
  bool _isEditingEmail = false;
  bool _isEditingPassword = false;
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
        _emailController = TextEditingController(text: widget.user.email);
        setState(() {});
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _newEmailController.dispose();
    _newPasswordController.dispose();
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

  Future<void> _updateEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? updatedUser;
      updatedUser = await widget._authService.updateEmail(
        email: widget.user.email!,
        currentPassword: _passwordController.text.trim(),
        newEmail: _newEmailController.text.trim(),
      );
      setState(() {
        widget.user = updatedUser!;
        _isEditingEmail = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _passwordController.clear();
        _newEmailController.clear();
      });
    }
  }

  Future<void> _updatePassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget._authService.updatePassword(
        email: widget.user.email!,
        currentPassword: _passwordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password updated successfully')),
      );
      setState(() {
        _isEditingPassword = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _passwordController.clear();
        _newPasswordController.clear();
      });
    }
    _passwordController.clear();
    _newPasswordController.clear();
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



  @override
  Widget build(BuildContext context) {
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
            _isEditingEmail
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _newEmailController,
                        decoration: InputDecoration(labelText: 'New Email'),
                      ),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(labelText: 'Current Password'),
                        obscureText: true,
                      ),
                      SizedBox(height: 10),
                      /*ElevatedButton(
                        onPressed: _updateEmail,
                        child: _isLoading
                            ? CircularProgressIndicator()
                            : Text('Update Email'),
                      ),*/
                    ],
                  )
                : ListTile(
                    title: Text('Email: ${widget.user.email}'),
                    /*trailing: IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        setState(() {
                          _isEditingEmail = true;
                        });
                      },
                    ),*/
                  ),
            const SizedBox(height: 16),
            _isEditingPassword
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _newPasswordController,
                        decoration: InputDecoration(labelText: 'New Password'),
                        obscureText: true,
                      ),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(labelText: 'Current Password'),
                        obscureText: true,
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _updatePassword,
                        child: _isLoading
                            ? CircularProgressIndicator()
                            : Text('Update Password'),
                      ),
                    ],
                  )
                : ListTile(
                    title: Text('Password: ********'),
                    trailing: IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        setState(() {
                          _isEditingPassword = true;
                        });
                      },
                    ),
                  ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await widget._authService.currentUser!.reload();
                widget.user = widget._authService.currentUser!;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Email refreshed to: ${widget.user.email}')),
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
