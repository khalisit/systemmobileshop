import 'package:flutter/services.dart';

/// Formatter that automatically converts Arabic & Kurdish/Persian digits
/// (٠١٢٣٤٥٦٧٨٩ and ۰۱۲۳۴۵۶۷۸۹) to standard English digits (0123456789)
class EnglishDigitsTextInputFormatter extends TextInputFormatter {
  const EnglishDigitsTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    String text = newValue.text;
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    for (int i = 0; i < 10; i++) {
      text = text.replaceAll(arabicDigits[i], englishDigits[i]);
      text = text.replaceAll(persianDigits[i], englishDigits[i]);
    }

    return newValue.copyWith(
      text: text,
      selection: newValue.selection,
    );
  }
}
