import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'authentication.dart';
import 'login_page.dart';

class AccountPage extends StatefulWidget {
  final User user;
  final AuthService authService;

  const AccountPage({
    super.key,
    required this.user,
    required this.authService,
  });

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _newEmailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isEditingEmail = false;
  bool _isEditingPassword = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _newEmailController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? updatedUser = await widget.authService.updateEmail(
        email: widget.user.email!,
        currentPassword: _passwordController.text.trim(),
        newEmail: _newEmailController.text.trim(),
      );

      if (updatedUser != null) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Email Updated'),
            content: Text('You will now be logged out.'),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await widget.authService.logoutUser();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _newEmailController.clear();
        _passwordController.clear();
        _isEditingEmail = false;
      });
    }
  }

  Future<void> _updatePassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.authService.updatePassword(
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
    } finally {
      setState(() {
        _isLoading = false;
        _newPasswordController.clear();
        _passwordController.clear();
      });
    }
  }

  Future<void> _logout() async {
    try {
      await widget.authService.logoutUser();
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
        title: Text('Account Settings'),
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
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _updateEmail,
                        child: _isLoading
                            ? CircularProgressIndicator()
                            : Text('Update Email'),
                      ),
                    ],
                  )
                : ListTile(
                    title: Text('Email: ${widget.user.email}'),
                    trailing: IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        setState(() {
                          _isEditingEmail = true;
                        });
                      },
                    ),
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
                      const SizedBox(height: 10),
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
          ],
        ),
      ),
    );
  }
}
