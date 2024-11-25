import 'package:country_picker/country_picker.dart';
import 'package:cura_link/src/constants/image_strings.dart';
import 'package:cura_link/src/repository/authentication_repository/authentication_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController phoneController = TextEditingController();

  Country selectedCountry = Country(
    phoneCode: "92",
    countryCode: "PK",
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: "Pakistan",
    example: "Pakistan",
    displayName: "Pakistan",
    displayNameNoCountryCode: "PK",
    e164Key: "",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 35),
            child: Column(
              children: [
                Container(
                  width: 200,
                  height: 200,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.purple.shade50,
                  ),
                  child: Image.asset(tLogoImage),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Register",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Add your phone number. We'll send you a verification code",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black38,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  cursorColor: Colors.purple,
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: "Enter phone number",
                    prefixIcon: InkWell(
                      onTap: () => showCountryPicker(
                        context: context,
                        countryListTheme:
                            const CountryListThemeData(bottomSheetHeight: 550),
                        onSelect: (Country country) {
                          setState(() {
                            selectedCountry = country;
                          });
                        },
                      ),
                      child: Text(
                        "${selectedCountry.flagEmoji} +${selectedCountry.phoneCode} ",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: sendPhoneNumber,
                    child: const Text("Login"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void sendPhoneNumber() {
    final phone = phoneController.text.trim();
    if (phone.isEmpty || phone.length < 9) {
      Get.snackbar("Invalid Input", "Please enter a valid phone number.");
      return;
    }
    final formattedPhone = "+${selectedCountry.phoneCode}$phone";
    AuthenticationRepository.instance.phoneAuthentication(formattedPhone);
  }
}
