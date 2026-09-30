/// Pure developer text tools. Every function returns a [ToolResult] so the UI
/// can show either output or a readable error without try/catch.
library;

import 'dart:convert';

class ToolResult {
  const ToolResult.ok(this.output) : error = null;
  const ToolResult.error(this.error) : output = '';

  final String output;
  final String? error;

  bool get isOk => error == null;
}

enum DevTool {
  jsonFormat('JSON format'),
  jsonMinify('JSON minify'),
  base64Encode('Base64 encode'),
  base64Decode('Base64 decode'),
  urlEncode('URL encode'),
  urlDecode('URL decode'),
  camelCase('camelCase'),
  snakeCase('snake_case'),
  kebabCase('kebab-case');

  const DevTool(this.label);
  final String label;
}

ToolResult runTool(DevTool tool, String input) {
  switch (tool) {
    case DevTool.jsonFormat:
      return _json(input, const JsonEncoder.withIndent('  '));
    case DevTool.jsonMinify:
      return _json(input, const JsonEncoder());
    case DevTool.base64Encode:
      return ToolResult.ok(base64.encode(utf8.encode(input)));
    case DevTool.base64Decode:
      return _base64Decode(input);
    case DevTool.urlEncode:
      return ToolResult.ok(Uri.encodeComponent(input));
    case DevTool.urlDecode:
      try {
        return ToolResult.ok(Uri.decodeComponent(input));
      } on ArgumentError {
        return const ToolResult.error('Invalid percent-encoding');
      } on FormatException {
        return const ToolResult.error('Invalid percent-encoding');
      }
    case DevTool.camelCase:
      final w = splitWords(input);
      if (w.isEmpty) return const ToolResult.ok('');
      return ToolResult.ok(
        w.first +
            w.skip(1).map((s) => s[0].toUpperCase() + s.substring(1)).join(),
      );
    case DevTool.snakeCase:
      return ToolResult.ok(splitWords(input).join('_'));
    case DevTool.kebabCase:
      return ToolResult.ok(splitWords(input).join('-'));
  }
}

ToolResult _json(String input, JsonEncoder encoder) {
  if (input.trim().isEmpty) return const ToolResult.error('Enter some JSON');
  try {
    return ToolResult.ok(encoder.convert(jsonDecode(input)));
  } on FormatException catch (e) {
    return ToolResult.error('Invalid JSON: ${e.message}');
  }
}

ToolResult _base64Decode(String input) {
  final cleaned = input.replaceAll(RegExp(r'\s'), '');
  try {
    final normalised = base64.normalize(
      cleaned.replaceAll('-', '+').replaceAll('_', '/'),
    );
    return ToolResult.ok(utf8.decode(base64.decode(normalised)));
  } on FormatException {
    return const ToolResult.error('Not valid Base64 or not UTF-8 text');
  }
}

/// Splits identifiers and phrases into lower-case words:
/// `helloWorld`, `Hello_world`, `hello-world`, `HTTPServer2` ...
List<String> splitWords(String input) {
  final spaced = input
      .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAllMapped(
          RegExp(r'([A-Z]+)([A-Z][a-z])'), (m) => '${m[1]} ${m[2]}');
  return spaced
      .split(RegExp(r'[^A-Za-z0-9]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w.toLowerCase())
      .toList();
}
