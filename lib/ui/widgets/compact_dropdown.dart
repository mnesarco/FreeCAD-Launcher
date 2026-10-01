// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

class CompactDropdown<T> extends StatelessWidget {
  const CompactDropdown({
    super.key,
    required this.value,
    this.hint,
    required this.items,
    required this.onChanged,
  });

  final T? value;
  final Widget? hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(isDense: true),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: hint,
          isDense: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
