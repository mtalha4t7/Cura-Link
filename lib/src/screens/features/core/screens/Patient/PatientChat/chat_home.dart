import 'package:cura_link/src/repository/user_repository/user_repository.dart';
import 'package:cura_link/src/screens/features/authentication/models/chat_user_model.dart';
import 'package:cura_link/src/widget/chat_user_card.dart';
import 'package:flutter/material.dart';

class ChatHomeScreen extends StatefulWidget {
  const ChatHomeScreen({super.key});

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ChatUserModelMongoDB> _allUsers = [];
  List<ChatUserModelMongoDB> _filteredUsers = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  /// Fetch users from the stream and store them locally for filtering
  void _loadUsers() {
    UserRepository.instance.getAllUsers1().listen((userData) {
      setState(() {
        _allUsers = userData
            .map((userMap) => ChatUserModelMongoDB.fromMap(userMap))
            .toList();
        _filteredUsers = _allUsers; // Initially, show all users
      });
    }, onError: (error) {
      print("Error fetching users: $error");
    });
  }

  /// Filters users based on search input
  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = _allUsers
          .where((user) =>
              user.userName!.toLowerCase().contains(query.toLowerCase()) ||
              user.userEmail!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final txtTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 1,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                onChanged: _filterUsers,
                autofocus: true,
                style: txtTheme.titleMedium?.copyWith(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Search users...",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : Text(
                "Cura Chat",
                style:
                    txtTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredUsers = _allUsers;
                }
              });
            },
            icon: Icon(_isSearching ? Icons.close : Icons.search),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert),
          )
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: theme.primaryColor,
          child: const Icon(Icons.add_comment_rounded, color: Colors.white),
        ),
      ),
      body: _filteredUsers.isEmpty
          ? const Center(
              child: Text(
                "No users found",
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: _filteredUsers.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return ChatUserCard(user: _filteredUsers[index]);
              },
            ),
    );
  }
}
