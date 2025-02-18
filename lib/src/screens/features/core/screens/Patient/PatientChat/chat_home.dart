import 'dart:developer';

import 'package:cura_link/src/repository/user_repository/user_repository.dart';
import 'package:cura_link/src/screens/features/authentication/models/chat_user_model.dart';
import 'package:cura_link/src/widget/chat_user_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserRepository _userRepository = UserRepository();

  List<ChatUserModelMongoDB> _usersList = [];
  List<ChatUserModelMongoDB> _searchList = [];
  bool _isSearching = false;
  bool _isLoading = true; // To show a loading indicator initially

  @override
  void initState() {
    super.initState();
    _loadUsers();

    // Handle app lifecycle to update active status
    SystemChannels.lifecycle.setMessageHandler((message) {
      log('Lifecycle Event: $message');

      if (message.toString().contains('resume')) {
        _updateUserActiveStatus(true);
      } else if (message.toString().contains('pause')) {
        _updateUserActiveStatus(false);
      }
      return Future.value(message);
    });
  }

  // Fetch users from MongoDB and update UI
  Future<void> _loadUsers() async {
    try {
      final users = await _userRepository.getAllUsersFromAllCollections();
      setState(() {
        _usersList = users!.cast<ChatUserModelMongoDB>();
        _isLoading = false;
      });
    } catch (e) {
      log('Error fetching users: $e');
      setState(() => _isLoading = false);
    }
  }

  // Update user active status in MongoDB
  void _updateUserActiveStatus(bool isActive) async {
    try {
      await _userRepository.updateActiveStatus(isActive);
      log('User status updated to: ${isActive ? 'Online' : 'Offline'}');
    } catch (e) {
      log('Error updating active status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          FocusScope.of(context).unfocus, // Hide keyboard when tapped outside
      child: Scaffold(
        appBar: AppBar(
          // leading: IconButton(
          //   // tooltip: 'View Profile',
          //   // onPressed: () {
          //   //   Navigator.push(
          //   //     context,
          //   //     MaterialPageRoute(
          //   //       builder: (_) => ProfileScreen(),
          //   //     ),
          //   //   );
          //   // },
          //   // icon: const ProfileImage(size: 32),
          // ),
          title: _isSearching
              ? TextField(
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search by Name, Email...',
                  ),
                  autofocus: true,
                  style: const TextStyle(fontSize: 17, letterSpacing: 0.5),
                  onChanged: (val) {
                    _searchList.clear();
                    val = val.toLowerCase();

                    for (var user in _usersList) {
                      if (user.userName!.toLowerCase().contains(val) ||
                          user.userEmail!.toLowerCase().contains(val)) {
                        _searchList.add(user);
                      }
                    }
                    setState(() {});
                  },
                )
              : const Text('We Chat'),
          actions: [
            IconButton(
              tooltip: 'Search',
              onPressed: () => setState(() => _isSearching = !_isSearching),
              icon: Icon(_isSearching
                  ? CupertinoIcons.clear_circled_solid
                  : CupertinoIcons.search),
            ),
            IconButton(
              tooltip: 'Add User',
              onPressed: _addChatUserDialog,
              icon: const Icon(CupertinoIcons.person_add, size: 25),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FloatingActionButton(
            backgroundColor: Colors.white,
            onPressed: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (_) => const AiScreen()),
              // );
            },
            child: Lottie.asset('assets/lottie/ai.json', width: 40),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _usersList.isEmpty
                ? const Center(
                    child: Text(
                      'No Connections Found!',
                      style: TextStyle(fontSize: 20),
                    ),
                  )
                : ListView.builder(
                    itemCount:
                        _isSearching ? _searchList.length : _usersList.length,
                    padding: const EdgeInsets.only(top: 10),
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      return ChatUserCard(
                        user: _isSearching
                            ? _searchList[index]
                            : _usersList[index],
                      );
                    },
                  ),
      ),
    );
  }

  // Show dialog to add a new chat user
  void _addChatUserDialog() {
    String email = '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        title: const Row(
          children: [
            Icon(Icons.person_add, color: Colors.blue, size: 28),
            Text('  Add User'),
          ],
        ),
        content: TextFormField(
          maxLines: null,
          onChanged: (value) => email = value,
          decoration: const InputDecoration(
            hintText: 'Enter Email',
            prefixIcon: Icon(Icons.email, color: Colors.blue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.blue, fontSize: 16)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (email.trim().isNotEmpty) {
                bool userExists = (await _userRepository
                    .getUserByEmailFromAllCollections(email)) as bool;
                if (userExists) {
                  log('User added successfully');
                  _loadUsers(); // Refresh user list
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User does not exist!')),
                  );
                }
              }
            },
            child: const Text('Add',
                style: TextStyle(color: Colors.blue, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
