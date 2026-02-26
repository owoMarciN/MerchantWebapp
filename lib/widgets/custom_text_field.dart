import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:user_app/extensions/brand_color_ext.dart';

enum FieldValidator {
  email,
  nip,
  regon,
  postalCode,
  required,
  none,
}

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final IconData? data;
  final String? hintText;
  final String? labelText;
  final bool isObsecure;
  final bool enabled;
  final double fontSize;
  final ValueChanged<String>? onChanged;
  final FieldValidator validator;
  final String? customValidatorPattern;
  final String? customValidatorMessage;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final String? Function(String?)? customValidator;

  const CustomTextField({
    super.key,
    this.controller,
    this.data,
    this.hintText,
    this.labelText,
    this.isObsecure = false,
    this.enabled = true,
    this.fontSize = 15.0,
    this.onChanged,
    this.validator = FieldValidator.none,
    this.customValidatorPattern,
    this.customValidatorMessage,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.customValidator,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _focusNode;
  static const Color _textDark = Color(0xFF21243D);

  static const Map<FieldValidator, _ValidatorConfig> _configs = {
    FieldValidator.email: _ValidatorConfig(
      pattern: r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$',
      message: 'Enter a valid email address',
      keyboard: TextInputType.emailAddress,
    ),
    FieldValidator.nip: _ValidatorConfig(
      pattern: r'^\d{10}$',
      message: 'NIP must be exactly 10 digits',
      keyboard: TextInputType.number,
    ),
    FieldValidator.regon: _ValidatorConfig(
      pattern: r'^\d{9}(\d{5})?$',
      message: 'REGON must be 9 or 14 digits',
      keyboard: TextInputType.number,
    ),
    FieldValidator.postalCode: _ValidatorConfig(
      pattern: r'^\d{2}-\d{3}$',
      message: 'Enter a valid postal code (XX-XXX)',
      keyboard: TextInputType.number,
    ),
    FieldValidator.required: _ValidatorConfig(
      pattern: r'.+',
      message: 'This field is required',
      keyboard: TextInputType.text,
    ),
    FieldValidator.none: _ValidatorConfig(
      pattern: null,
      message: null,
      keyboard: TextInputType.text,
    ),
  };

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    if (widget.customValidator != null) {
      return widget.customValidator!(value);
    }

    if (widget.customValidatorPattern != null) {
      if (value == null || value.isEmpty) return widget.customValidatorMessage ?? 'This field is required';
      final regex = RegExp(widget.customValidatorPattern!);
      if (!regex.hasMatch(value)) return widget.customValidatorMessage ?? 'Invalid format';
      return null;
    }

    final config = _configs[widget.validator];
    if (config == null || config.pattern == null) return null;

    if (value == null || value.isEmpty) return config.message;
    final regex = RegExp(config.pattern!);
    if (!regex.hasMatch(value.trim())) return config.message;
    return null;
  }

  TextInputType get _keyboardType {
    if (widget.keyboardType != null) return widget.keyboardType!;
    return _configs[widget.validator]?.keyboard ?? TextInputType.text;
  }

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<BrandColors>()!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        focusNode: _focusNode,
        controller: widget.controller,
        obscureText: widget.isObsecure,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
        cursorColor: brand.navy,
        keyboardType: _keyboardType,
        inputFormatters: widget.inputFormatters,
        maxLines: widget.maxLines,
        validator: _validate,
        style: TextStyle(fontSize: widget.fontSize, color: _textDark),
        decoration: InputDecoration(
          hintText: "Enter ${widget.hintText?.toLowerCase() ?? 'details'}",
          labelText: widget.labelText,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: widget.enabled ? Colors.white : Colors.grey[50],
          prefixIcon: widget.data != null
              ? Icon(widget.data, size: 20, color: _focusNode.hasFocus ? brand.navy : Colors.grey)
              : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: brand.navy!, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _ValidatorConfig {
  final String? pattern;
  final String? message;
  final TextInputType keyboard;

  const _ValidatorConfig({
    required this.pattern,
    required this.message,
    required this.keyboard,
  });
}