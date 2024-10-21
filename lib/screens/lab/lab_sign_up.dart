import 'package:cura_link/screens/patient/patient_sign_in.dart';
import 'package:flutter/material.dart';

import '../../widget/widget_support.dart';

class labSignUp extends StatefulWidget {
  const labSignUp({super.key});

  @override
  State<labSignUp> createState() => _LoginState();
}

class _LoginState extends State<labSignUp> {
  final TextEditingController useremailcontroller = TextEditingController();
  final TextEditingController userpasswordcontroller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/registerbg.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Material(
                elevation: 5.0,
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withOpacity(0.1), // Adjust transparency here
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8), // Adjust transparency here
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Form(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Create Account",
                          style: AppWidget.headlineTextFieldStyle(),
                        ),
                        const SizedBox(height: 30),
                        TextFormField(
                          controller: useremailcontroller,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'Name',
                            hintStyle: AppWidget.semiBoldTextFieldStyle(),
                            prefixIcon: const Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 30),
                        TextFormField(
                          controller: useremailcontroller,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter email';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'Email',
                            hintStyle: AppWidget.semiBoldTextFieldStyle(),
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 30),
                        TextFormField(
                          controller: userpasswordcontroller,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter password';
                            }
                            return null;
                          },
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: AppWidget.semiBoldTextFieldStyle(),
                            prefixIcon: const Icon(Icons.password_outlined),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Handle forgot password
                          },
                          child: Container(
                            padding: const EdgeInsets.only(top: 20),
                            alignment: Alignment.topRight,
                            child: const Text('Forgot Password'),
                          ),
                        ),
                        Container(
                          alignment: Alignment.topLeft,
                          child: ElevatedButton(
                            onPressed: () {
                              // Handle login
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00838F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              elevation: 8,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(left:8.0,right: 8.0),
                              child: const Text(
                                'Create account',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.0,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Already have an account?"),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => labSignUp()), // Make sure to import the SignUp class
                                ); // Handle sign up
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00838F),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                                elevation: 8,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(left:8.0,right:8.0),
                                child: const Text(
                                  'Sign in',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.0,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
