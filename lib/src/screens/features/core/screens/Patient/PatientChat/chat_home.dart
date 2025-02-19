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
  @override
  Widget build(BuildContext context) {
    final txtTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 1,
        title: Text(
          "Cura Chat",
          style: txtTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
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
      body: StreamBuilder(
        stream: UserRepository.instance.getAllUsers1(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          List<Map<String, dynamic>> users = snapshot.data!;

          if (users.isEmpty) {
            return const Center(
              child: Text(
                "There are no connections for chat",
                style: TextStyle(fontSize: 18),
              ),
            );
          } else {
            return ListView.builder(
              padding: EdgeInsets.only(top: 8),
              itemCount: users.length,
              physics: BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                var userMap = users[index];
                ChatUserModelMongoDB user =
                    ChatUserModelMongoDB.fromMap(userMap);
                return ChatUserCard(user: user);
              },
            );
          }
        },
      ),
    );
  }
}
