import 'package:dio/dio.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StripeService {
  StripeService._();

  static final StripeService instance = StripeService._();

  // Initialize Stripe with publishable key from .env
  Future<void> initialize() async {
    await dotenv.load(); // Load environment variables
    Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;
    await Stripe.instance.applySettings();
  }

  Future<void> makePayment(int amount) async {
    try {
      String? paymentIntentClientSecret = await _createPaymentIntent(amount, "usd");
      if (paymentIntentClientSecret == null) return;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: "Talha",
        ),
      );
      await _processPayment();
    } catch (e) {
      print(e);
      rethrow; // Consider proper error handling
    }
  }

  Future<String?> _createPaymentIntent(int amount, String currency) async {
    try {
      final stripeSecretKey = dotenv.env['STRIPE_SECRET_KEY'];
      if (stripeSecretKey == null) {
        throw Exception('Stripe secret key not found in environment variables');
      }

      final Dio dio = Dio();
      final response = await dio.post(
        "https://api.stripe.com/v1/payment_intents",
        data: {
          "amount": _calculateAmount(amount),
          "currency": currency,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            "Authorization": "Bearer $stripeSecretKey",
            "Content-Type": 'application/x-www-form-urlencoded',
          },
        ),
      );
      return response.data["client_secret"];
    } catch (e) {
      print(e);
      rethrow; // Consider proper error handling
    }
  }

  Future<void> _processPayment() async {
    try {
      await Stripe.instance.presentPaymentSheet();
    } catch (e) {
      print(e);
      rethrow; // Consider proper error handling
    }
  }

  String _calculateAmount(int amount) => (amount * 100).toString();
}