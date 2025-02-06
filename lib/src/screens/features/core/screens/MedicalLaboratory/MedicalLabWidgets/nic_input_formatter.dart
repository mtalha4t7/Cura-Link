import 'package:flutter/services.dart';

class NICInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text;

    // Remove any existing dashes
    text = text.replaceAll('-', '');

    // Add dashes at the correct positions
    String formattedText = '';
    if (text.length > 5) {
      formattedText += '${text.substring(0, 5)}-';
      if (text.length > 12) {
        formattedText += '${text.substring(5, 12)}-';
        formattedText += text.substring(12, text.length);
      } else {
        formattedText += text.substring(5, text.length);
      }
    } else {
      formattedText = text;
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
