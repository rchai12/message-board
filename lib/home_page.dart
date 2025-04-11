import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'authentication.dart';
import 'account_page.dart';
import 'profile_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  User user;
  final authService = AuthService();
  HomePage({super.key, required this.user});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _messageBoards;
  int _currentIndex = 0;
  late bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _messageBoards = AuthService().getAllMessageBoards();
    _checkIfAdmin();
  }

  Future<void> _checkIfAdmin() async {
    try {
      DocumentSnapshot<Map<String, dynamic>>? userData = await widget.authService.getUserData();
      if (userData != null && userData.exists) {
        String role = userData.data()?['role'] ?? '';
        if (role == 'admin') {
          setState(() {
            _isAdmin = true;
          });
        }
      }
    } catch (e) {
      print('Error fetching user role: $e');
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
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

  void _showCreateMessageBoardDialog() {
    final _titleController = TextEditingController();
    final _imageUrlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Message Board'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _imageUrlController,
              decoration: InputDecoration(labelText: 'Image URL'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              String title = _titleController.text.trim();
              String imageUrl = _imageUrlController.text.trim();
              String userId = widget.user.uid;
              if (title.isNotEmpty && imageUrl.isNotEmpty) {
                try {
                  await widget.authService.createMessageBoard(
                    title: title,
                    createdByUserId: userId,
                    imageUrl: imageUrl,
                  );
                  Navigator.of(context).pop();
                  setState(() {
                    _messageBoards = widget.authService.getAllMessageBoards();
                  });
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating board: $e')),
                  );
                }
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  final List<Widget> _pages = [];

  @override
  Widget build(BuildContext context) {
    _pages.clear();
    _pages.add(HomeTab());
    _pages.add(ProfilePage(user: widget.user, authService: widget.authService));
    _pages.add(AccountPage(user: widget.user, authService: widget.authService));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Boards'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Account Settings',
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: () {
                _showCreateMessageBoardDialog();
                print('Admin Button Pressed');
              },
              child: Icon(Icons.add),
            )
          : null,
    );
  }
}


class HomeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AuthService().getAllMessageBoards(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No message boards available.'));
        } else {
          List<Map<String, dynamic>> boards = snapshot.data!;
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
            ),
            itemCount: boards.length,
            itemBuilder: (context, index) {
              var board = boards[index];
              String boardId = board['id'];
              String title = board['title'];
              String imageUrl = board['image'];
              return GestureDetector(
                onTap: () {
                  // placeholder for navigation to specific board
                },
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          color: Colors.black.withOpacity(0.5),
                          child: Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
}
