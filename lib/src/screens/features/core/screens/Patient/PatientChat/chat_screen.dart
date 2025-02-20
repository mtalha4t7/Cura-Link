import 'dart:typed_data';
import 'package:cura_link/src/repository/user_repository/user_repository.dart';
import 'package:cura_link/src/screens/features/authentication/models/chat_user_model.dart';
import 'package:cura_link/src/screens/features/authentication/models/message_model.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/PatientChat/widgets/chat_input_widget.dart';
import 'package:cura_link/src/screens/features/core/screens/Patient/PatientChat/widgets/chat_message_card.dart';
import 'package:flutter/material.dart';
import 'package:cura_link/src/constants/colors.dart';

class ChatScreen extends StatefulWidget {
  final ChatUserModelMongoDB user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  String? loggedInUserEmail;

  @override
  void initState() {
    super.initState();
    _fetchLoggedInUserEmail();
  }

  /// Fetch currently logged-in user's email
  Future<void> _fetchLoggedInUserEmail() async {
    loggedInUserEmail = await UserRepository.instance.getCurrentUser();
    debugPrint("Logged-in user email: $loggedInUserEmail"); // ✅ Debug print
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          elevation: 1.0,
          automaticallyImplyLeading: false,
          backgroundColor: isDarkMode ? tDarkColor : tPrimaryColor,
          title: Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_back,
                  color: isDarkMode ? tWhiteColor : Colors.black54,
                ),
              ),
              CircleAvatar(
                backgroundColor: Colors.grey[300],
                backgroundImage: widget.user.profileImage != null
                    ? MemoryImage(widget.user.profileImage! as Uint8List)
                    : null,
                child: widget.user.profileImage == null
                    ? Icon(Icons.person, color: tWhiteColor)
                    : null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.userName ?? "Unknown User",
                    style: TextStyle(
                      color: isDarkMode ? tWhiteColor : tDarkColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    widget.user.userLastActive ?? "Last seen not available",
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream: UserRepository.instance.getAllMessagesStream().map(
                  (snapshot) {
                    debugPrint(
                        "Fetched raw messages: $snapshot"); // ✅ Check raw JSON data
                    return snapshot
                        .map((json) => Message.fromJson(json))
                        .toList();
                  },
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    debugPrint("No messages found."); // ✅ Debug check if empty
                    return Center(child: Text("No messages yet."));
                  }

                  List<Message> messages = snapshot.data!;
                  debugPrint(
                      "Parsed messages: ${messages.map((m) => m.toJson()).toList()}"); // ✅ Debug parsed messages

                  // Sorting messages by timestamp
                  messages.sort((a, b) {
                    try {
                      DateTime aTime = a.sent is int
                          ? DateTime.fromMillisecondsSinceEpoch(a.sent as int)
                          : DateTime.parse(a.sent);
                      DateTime bTime = b.sent is int
                          ? DateTime.fromMillisecondsSinceEpoch(b.sent as int)
                          : DateTime.parse(b.sent);
                      return aTime.compareTo(bTime);
                    } catch (e) {
                      debugPrint("Sorting error: $e"); // ✅ Debug sorting issues
                      return 0;
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      debugPrint(
                          "Rendering message: ${message.toJson()}"); // ✅ Debug message before rendering

                      return ChatMessageCard(
                        message: message,
                        isFromCurrentUser: message.fromId ==
                            loggedInUserEmail, // ✅ Compare email correctly
                      );
                    },
                  );
                },
              ),
            ),
            chatInput(),
          ],
        ),
      ),
    );
  }
}
