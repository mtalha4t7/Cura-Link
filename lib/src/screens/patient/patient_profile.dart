import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../common/toast.dart';

class ProfileScreen extends StatefulWidget {

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {

    setState(() {});
  }

  Future<void> changePassword() async {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Change Password'),
          content: TextField(
            controller: passwordController,
            decoration: InputDecoration(hintText: 'New Password'),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (passwordController.text.isNotEmpty) {
                  try {
                    User? user = FirebaseAuth.instance.currentUser;

                    // Change the password
                    await user?.updatePassword(passwordController.text);
                    Navigator.of(context).pop(); // Close the dialog
                    showToast(message: 'Password changed successfully!');
                  } catch (e) {
                    showToast(message: 'Error: ${e.toString()}');
                  }
                } else {
                  showToast(message: 'Please enter a new password.');
                }
              },
              child: Text('Change'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, "/patientLogin");
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(userData!['profilePicture']),
            ),
            SizedBox(height: 16),
            Text('Name: ${userData!['name']}'),
            Text('Email: ${userData!['email']}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: changePassword,
              child: Text('Change Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: logout,
              child: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<Map<String, dynamic>?> getUserData(String uid) async {
  DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  if (userDoc.exists) {
    return userDoc.data() as Map<String, dynamic>?;
  }
  return null;
}
