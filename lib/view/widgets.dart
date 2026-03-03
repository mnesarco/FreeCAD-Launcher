import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';

import '../path.dart';

const double _labelWidth = 130;

Widget formFieldRow({
  IconData? icon,
  required String label,
  required Widget field,
  double? labelWidth,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: labelWidth ?? _labelWidth,
        height: 48,
        child: Row(
          children: [
            if (icon != null) Icon(icon, size: 20),
            if (icon != null) const SizedBox(width: 8),
            Text("$label:"),
          ],
        ),
      ),
      const SizedBox(width: 12),
      Expanded(child: field),
    ],
  );
}

enum PathType { file, dir }

class PathFormField extends StatefulWidget {
  final Signal<String> value;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final List<XTypeGroup>? acceptedTypeGroups;
  final PathType type;
  final String? initialDirectory;
  final String? confirmButtonText;
  final bool? canCreateDirectories;

  const PathFormField({
    super.key,
    required this.value,
    this.hintText,
    this.validator,
    this.onChanged,
    this.acceptedTypeGroups,
    this.type = PathType.file,
    this.initialDirectory,
    this.confirmButtonText,
    this.canCreateDirectories,
  });

  @override
  State<PathFormField> createState() => _PathFormFieldState();
}

class _PathFormFieldState extends State<PathFormField> {
  late final Signal<int> _version;
  Path? lastDirectory;

  @override
  void initState() {
    super.initState();
    _version = signal(0);
  }

  @override
  void dispose() {
    _version.dispose();
    super.dispose();
  }

  Future<void> _pickPath() async {
    lastDirectory ??= await Path.home();
    if (widget.type == PathType.file) {
      final file = await openFile(
        acceptedTypeGroups: widget.acceptedTypeGroups ?? [],
        initialDirectory: widget.initialDirectory ?? lastDirectory!.str,
        confirmButtonText: widget.confirmButtonText,
      );
      if (file != null) {
        widget.value.value = file.path;
        widget.onChanged?.call(file.path);
        lastDirectory = Path(file.path).parent();
        _version.value++;
      }
    } else {
      final dir = await getDirectoryPath(
        initialDirectory: widget.initialDirectory ?? lastDirectory!.str,
        confirmButtonText: widget.confirmButtonText,
        canCreateDirectories: widget.canCreateDirectories,
      );
      if (dir != null) {
        widget.value.value = dir;
        widget.onChanged?.call(dir);
        lastDirectory = Path(dir).parent();
        _version.value++;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Watch(
          (_) => Expanded(
            child: TextFormField(
              key: ValueKey(_version.value),
              initialValue: widget.value.peek(),
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) {
                widget.value.value = v;
                widget.onChanged?.call(v);
              },
              validator: widget.validator,
              textInputAction: TextInputAction.next,
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: Icon(widget.type == PathType.file ? Icons.file_open : Icons.folder_open),
          tooltip: 'Browse...',
          onPressed: _pickPath,
        ),
      ],
    );
  }
}

class TextFormFieldExt extends StatelessWidget {
  final Signal<String> value;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  const TextFormFieldExt({
    super.key,
    required this.value,
    this.hintText,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value.value,
      decoration: const InputDecoration(
        hintText: 'e.g. FreeCAD 1.0',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (v) {
        value.value = v;
        onChanged?.call(v);
      },
      validator: validator,
      textInputAction: TextInputAction.next,
    );
  }
}

class SearchField extends StatelessWidget {
  final Signal<String> value;
  final String? hintText;

  const SearchField({super.key, required this.value, this.hintText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: hintText ?? 'Search...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 24),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
          ),
        ),
        onChanged: (val) => value.value = val,
      ),
    );
  }
}
