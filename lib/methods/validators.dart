// ---------------------------------------------------------------------------
// CUSTOM VALIDATORS CAN BE ADDED HERE
// ---------------------------------------------------------------------------
import 'package:flutter_iban_tools/flutter_iban_tools.dart' as ibantools;


String? validateIban(String? value) {
  if (value == null || value.trim().isEmpty) return null;

  final iban = value.replaceAll(' ', '').toUpperCase();

  final validationResult = ibantools.validateIBAN(iban);

  if (!validationResult.valid) {
    return 'Incorrect IBAN (Checksum failed)';
  }

  if (!ibantools.isValidIBANChecksum(iban)) {
    return 'Invalid IBAN format or length';
  }

  return null;
}