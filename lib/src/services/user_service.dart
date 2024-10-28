import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch user document by UID
  Future<DocumentSnapshot?> getUserDocument(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      return userDoc.exists ? userDoc : null;
    } catch (e) {
      print("Error fetching user document: $e");
      return null;
    }
  }

  // Create or update user document in Firestore
  Future<void> saveUserData(User user, String name, String email) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'email': email, // Save email passed as parameter
        'name': name, // Ensure name is passed in
        'profilePic': user.photoURL ?? "", // Default to empty string if null
        'createdAt': FieldValue.serverTimestamp(), // Timestamp for creation
        'updatedAt': FieldValue.serverTimestamp(), // Timestamp for update
      }, SetOptions(merge: true)); // Use merge to update existing fields
    } catch (e) {
      print("Error saving user data: $e");
    }
  }

  // Update user data
  Future<void> updateUserData(String uid, String name, String email, String profilePic) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'name': name,
        'email': email,
        'profilePic': profilePic,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error updating user data: $e");
    }
  }

  // Delete user data
  Future<void> deleteUserData(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      print("Error deleting user data: $e");
    }
  }
}
