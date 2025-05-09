import 'dart:async';
import 'package:cura_link/src/repository/user_repository/user_repository.dart';
import 'package:cura_link/src/screens/features/authentication/models/chat_user_model.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/PatientChat/widgets/chat_user_card.dart';
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
  bool _isLoading = true;
  StreamSubscription? _userStreamSubscription;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _updateUserLastActive();
    _setupMessageListener();
  }

  void _setupMessageListener() {
    UserRepository.instance.getNewMessagesStream().listen((_) {
      _loadUsers();
    });
  }

  void _updateUserLastActive() async {
    try {
      final currentUserEmail = await UserRepository.instance.getCurrentUser();
      if (currentUserEmail != null) {
        await UserRepository.instance.updateUserLastActive(currentUserEmail);
      }
    } catch (e) {
      debugPrint("Error updating last active: $e");
    }
  }

  void _loadUsers() {
    _userStreamSubscription?.cancel();

    setState(() {
      _isLoading = true;
    });

    _userStreamSubscription = UserRepository.instance
        .getChatUsersWithMessages()
        .listen((userData) {
      if (mounted) {
        setState(() {
          _allUsers = userData
              .map((userMap) => ChatUserModelMongoDB.fromMap(userMap))
              .toList();

          // Sort users by last message time (newest first)
          _allUsers.sort((a, b) {
            try {
              final aTime = a.lastMessageTime ?? '';
              final bTime = b.lastMessageTime ?? '';

              if (aTime.isEmpty || bTime.isEmpty) {
                return bTime.isEmpty ? -1 : 1;
              }

              DateTime aDateTime;
              DateTime bDateTime;

              if (RegExp(r'^\d+$').hasMatch(aTime)) {
                aDateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(aTime));
              } else {
                aDateTime = DateTime.parse(aTime);
              }

              if (RegExp(r'^\d+$').hasMatch(bTime)) {
                bDateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(bTime));
              } else {
                bDateTime = DateTime.parse(bTime);
              }

              return bDateTime.compareTo(aDateTime);
            } catch (e) {
              debugPrint("Error sorting users: $e");
              return 0;
            }
          });

          _filteredUsers = _allUsers;
          _isLoading = false;
        });
      }
    }, onError: (error) {
      debugPrint("Error fetching users: $error");
      setState(() {
        _isLoading = false;
      });
    });
  }

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
  void dispose() {
    _userStreamSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
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
          style: txtTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
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
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
        ),
      )
          : _filteredUsers.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.message,
              size: 64,
              color: theme.primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "No conversations yet",
              style: txtTheme.titleMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: () async {
          await UserRepository.instance.fetchChatUsers();
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _filteredUsers.length,
          physics: const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return ChatUserCard(user: _filteredUsers[index]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Implement new chat functionality
        },
        backgroundColor: theme.primaryColor,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }
}