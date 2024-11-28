import 'package:cura_link/src/screens/features/authentication/controllers/otp_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

import '../../../../../common_widgets/buttons/custom_button';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  const OtpScreen({super.key, required this.verificationId});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String? otpCode;
  bool canResend = true;

  @override
  Widget build(BuildContext context) {
    final OTPController authController = Get.find<OTPController>();
    return Scaffold(
      body: SafeArea(
        child: Obx(
              () => authController.isLoading.value
              ? const Center(
            child: CircularProgressIndicator(
              color: Colors.purple,
            ),
          )
              : Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 25, horizontal: 30),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: const Icon(Icons.arrow_back),
                    ),
                  ),
                  Container(
                    width: 200,
                    height: 200,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.purple.shade50,
                    ),
                    child: Image.asset(
                      "assets/image2.png",
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Verification",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Enter the OTP sent to your phone number",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black38,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Pinput(
                    length: 6,
                    showCursor: true,
                    defaultPinTheme: PinTheme(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.purple.shade200,
                        ),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onCompleted: (value) {
                      setState(() {
                        otpCode = value;
                      });
                    },
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: 50,
                    child: CustomButton(
                      text: "Verify",
                      onPressed: () {
                        if (otpCode != null) {
                          authController.verifyOtp(
                            verificationId: widget.verificationId,
                            userOtp: otpCode!,
                            phoneNumber: widget.verificationId, // Pass phone number
                            onSuccess: () {
                              // Show success message
                              Get.snackbar(
                                "Success",
                                "OTP Verified Successfully!",
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                              );

                            },
                          );
                        } else {
                          // Show error if OTP is not entered
                          Get.snackbar(
                            "Error",
                            "Enter a 6-digit OTP code",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Didn't receive any code?",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black38,
                    ),
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: canResend
                        ? () {
                      setState(() => canResend = false);
                      Future.delayed(
                        const Duration(seconds: 30),
                            () => setState(() => canResend = true),
                      );
                      authController.resendOtp(widget.verificationId);
                    }
                        : null,
                    child: Text(
                      "Resend New Code",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: canResend ? Colors.purple : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
