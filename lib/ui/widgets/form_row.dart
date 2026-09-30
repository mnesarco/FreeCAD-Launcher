// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

const double formLabelWidth = 195;

class FormRow extends StatelessWidget {
  const FormRow({
    super.key,
    required this.label,
    required this.field,
    this.icon,
    this.labelWidth = formLabelWidth,
    this.padding = const EdgeInsets.only(bottom: 12),
  });

  final String label;
  final Widget field;
  final IconData? icon;
  final double labelWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      '$label:',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: field),
        ],
      ),
    );
  }
}

class FormTextField extends StatelessWidget {
  const FormTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.errorText,
    this.onChanged,
    this.autofocus = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.suffixIcon,
    this.prefixIcon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String? hintText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final bool readOnly;
  final bool enabled;
  final int maxLines;
  final int? minLines;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      readOnly: readOnly,
      enabled: enabled,
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        errorText: errorText,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
      ),
    );
  }
}

class FormDropdown<T> extends StatelessWidget {
  const FormDropdown({
    super.key,
    required this.value,
    required this.items,
    this.onChanged,
    this.hint,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final Widget? hint;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isDense: true,
      isExpanded: true,
      hint: hint,
      items: items,
      onChanged: onChanged,
    );
  }
}
