import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

String formatRupiah(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}

String formatRupiahInput(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 0,
  );
  return formatter.format(amount).trim();
}

String formatQty(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toString().replaceAll('.', ',');
}

String formatMoneyDisplay(String text) {
  final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (cleaned.isEmpty) return '';
  final number = int.tryParse(cleaned);
  if (number == null) return '';
  final formatter = NumberFormat('#,##0', 'id_ID');
  return formatter.format(number);
}

class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final number = int.parse(digits);
    final formatted = NumberFormat('#,##0', 'id_ID').format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String formatDate(DateTime date) {
  return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
}

String formatDateShort(DateTime date) {
  return DateFormat('dd/MM/yyyy', 'id_ID').format(date);
}

String formatTime(DateTime date) {
  return DateFormat('HH:mm', 'id_ID').format(date);
}

double parseRupiah(String text) {
  final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
  return double.tryParse(cleaned) ?? 0;
}
