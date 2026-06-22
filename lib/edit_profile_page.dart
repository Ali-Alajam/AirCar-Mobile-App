import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final String uid = FirebaseAuth.instance.currentUser!.uid;

  bool isLoaded = false;
  bool isLoading = false;

  Future<void> updateProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final String newEmail = emailController.text.trim();
    final bool isEmailChanged = newEmail != user!.email;

    if (passwordController.text.isEmpty) {
      _showSnackBar("Please enter your current password", const Color.fromARGB(255, 255, 0, 0));
      return;
    }

    setState(() => isLoading = true);

    try {
      
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: passwordController.text.trim(),
      );
      await user.reauthenticateWithCredential(credential);

      
      
      if (isEmailChanged) {
      
        await user.verifyBeforeUpdateEmail(newEmail);

        await FirebaseFirestore.instance.collection("users").doc(uid).update({
          "firstName": firstNameController.text.trim(),
          "lastName": lastNameController.text.trim(),
          "phone": phoneController.text.trim(),
         
        });

        if (mounted) _showVerificationDialog();
        
      } else {
        
        await FirebaseFirestore.instance.collection("users").doc(uid).update({
          "firstName": firstNameController.text.trim(),
          "lastName": lastNameController.text.trim(),
          "phone": phoneController.text.trim(),
          "email": newEmail,
        });

        if (mounted) {
          _showSnackBar("Profile updated successfully", Colors.green);
          Navigator.pop(context);
        }
      }

      // --- نهاية التعديل ---

    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}", Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// Dialog after changing email
  void _showVerificationDialog() {

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Verify Your Email"),
        content: const Text(
            "A verification link has been sent to your new email address.Please verify it to complete the update.!!!You need to log out!!!"),
        actions: [

          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),

        ],
      ),
    );
  }

  /// Handle Firebase errors
  void _handleFirebaseError(FirebaseAuthException e) {

    String message = "An error occurred";

    if (e.code == 'email-already-in-use') {
      message = "Email already in use";
    }

    if (e.code == 'wrong-password') {
      message = "Incorrect password";
    }

    if (e.code == 'requires-recent-login') {
      message = "Please logout and login again";
    }

    _showSnackBar(message, Colors.red);
  }

  /// Show snackbar
  void _showSnackBar(String msg, Color color) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),

      body: StreamBuilder<DocumentSnapshot>(

        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          if (!isLoaded) {

            firstNameController.text = data["firstName"] ?? "";
            lastNameController.text = data["lastName"] ?? "";
            phoneController.text = data["phone"] ?? "";
            emailController.text = data["email"] ?? "";

            isLoaded = true;
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),

              child: ListView(
                padding: const EdgeInsets.all(20),

                children: [

                  const Icon(
                    Icons.person_pin,
                    size: 100,
                    color: Colors.blueAccent,
                  ),

                  const SizedBox(height: 30),

                  TextField(
                    controller: firstNameController,
                    decoration: const InputDecoration(
                        labelText: "First Name",
                        border: OutlineInputBorder()),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: lastNameController,
                    decoration: const InputDecoration(
                        labelText: "Last Name",
                        border: OutlineInputBorder()),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                        labelText: "Phone Number",
                        border: OutlineInputBorder()),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                        labelText: "Email Address",
                        border: OutlineInputBorder()),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Confirm Password",
                      hintText: "Enter password to save changes",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    height: 50,

                    child: ElevatedButton(
                      onPressed: isLoading ? null : updateProfile,

                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent),

                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Save",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16),
                            ),
                    ),
                  ),

                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {

    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }
}