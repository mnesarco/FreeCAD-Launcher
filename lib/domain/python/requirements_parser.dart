final RegExp _requirementPattern = RegExp(
  r'^([A-Za-z0-9][A-Za-z0-9._-]*)\s*(?:\[([^\]]*)\])?\s*(.*)$',
);

class PythonRequirement {
  const PythonRequirement({
    required this.raw,
    required this.name,
    this.extras = const [],
    this.specifier = '',
    this.marker = '',
    this.valid = true,
    this.error,
  });

  final String raw;
  final String name;
  final List<String> extras;
  final String specifier;
  final String marker;
  final bool valid;
  final String? error;

  String get display {
    final extrasText = extras.isEmpty ? '' : '[${extras.join(',')}]';
    return '$name$extrasText$specifier';
  }
}

String requirementSpec(PythonRequirement requirement) {
  final extras = requirement.extras.isEmpty ? '' : '[${requirement.extras.join(',')}]';
  final marker = requirement.marker.isEmpty ? '' : '; ${requirement.marker}';
  return '${requirement.name}$extras${requirement.specifier}$marker';
}

List<PythonRequirement> parseRequirements(String text) {
  final requirements = <PythonRequirement>[];
  for (final rawLine in text.split('\n')) {
    final line = _stripComment(rawLine.trim());
    if (line.isEmpty) {
      continue;
    }

    if (line.startsWith('-')) {
      requirements.add(
        PythonRequirement(
          raw: line,
          name: line.split(RegExp(r'\s+')).first,
          valid: false,
          error: 'Unsupported pip option',
        ),
      );
      continue;
    }

    final markerIndex = line.indexOf(';');
    final withoutMarker = markerIndex < 0 ? line : line.substring(0, markerIndex).trim();
    final marker = markerIndex < 0 ? '' : line.substring(markerIndex + 1).trim();

    final match = _requirementPattern.firstMatch(withoutMarker);
    if (match == null) {
      requirements.add(
        PythonRequirement(
          raw: line,
          name: withoutMarker,
          valid: false,
          error: 'Could not parse requirement',
        ),
      );
      continue;
    }

    final extras = (match[2] ?? '')
        .split(',')
        .map((extra) => extra.trim())
        .where((extra) => extra.isNotEmpty)
        .toList();

    requirements.add(
      PythonRequirement(
        raw: line,
        name: match[1]!,
        extras: extras,
        specifier: match[3]!.trim(),
        marker: marker,
      ),
    );
  }
  return requirements;
}

String _stripComment(String line) {
  final match = RegExp(r'(^|\s)#').firstMatch(line);
  if (match == null) {
    return line;
  }
  return line.substring(0, match.start).trim();
}
