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
      return _json(input, indent: '  ');
    case DevTool.jsonMinify:
      return _json(input);
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

ToolResult _json(String input, {String? indent}) {
  if (input.trim().isEmpty) return const ToolResult.error('Enter some JSON');
  try {
    jsonDecode(input); // Validation only; see [reformatJson].
  } on FormatException catch (e) {
    return ToolResult.error('Invalid JSON: ${e.message}');
  }
  return ToolResult.ok(reformatJson(input, indent: indent));
}

/// Re-indents (or minifies, when [indent] is null) already-valid JSON by
/// rewriting only the whitespace between tokens.
///
/// Decoding and re-encoding would change the data: numbers beyond 2^63 lose
/// precision (`12345678901234567890` -> `12345678901234567000.0`), `1e2`
/// becomes `100.0`, `1.50` becomes `1.5` and escapes like `\u00e9` are
/// rewritten. Token text is copied verbatim instead.
String reformatJson(String json, {String? indent}) {
  final out = StringBuffer();
  var depth = 0;
  var inString = false;
  var escaped = false;
  void newline() {
    if (indent == null) return;
    out
      ..write('\n')
      ..write(indent * depth);
  }

  for (var i = 0; i < json.length; i++) {
    final c = json[i];
    if (inString) {
      out.write(c);
      if (escaped) {
        escaped = false;
      } else if (c == '\\') {
        escaped = true;
      } else if (c == '"') {
        inString = false;
      }
      continue;
    }
    switch (c) {
      case ' ' || '\t' || '\n' || '\r':
        break;
      case '"':
        inString = true;
        out.write(c);
      case '{' || '[':
        out.write(c);
        final close = c == '{' ? '}' : ']';
        var j = i + 1;
        while (j < json.length && ' \t\n\r'.contains(json[j])) {
          j++;
        }
        if (j < json.length && json[j] == close) {
          out.write(close);
          i = j;
        } else {
          depth++;
          newline();
        }
      case '}' || ']':
        depth--;
        newline();
        out.write(c);
      case ',':
        out.write(c);
        newline();
      case ':':
        out.write(indent == null ? ':' : ': ');
      default:
        out.write(c);
    }
  }
  return out.toString();
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

/// Any run of characters that are not letters, combining marks (Thai vowels
/// and tone marks, accents) or digits separates words.
final _wordSeparator = RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true);

/// Splits identifiers and phrases into lower-case words:
/// `helloWorld`, `Hello_world`, `hello-world`, `HTTPServer2`, `café au lait`,
/// `สวัสดี ชาวโลก` ...
List<String> splitWords(String input) {
  final spaced = input
      .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAllMapped(
          RegExp(r'([A-Z]+)([A-Z][a-z])'), (m) => '${m[1]} ${m[2]}');
  return spaced
      .split(_wordSeparator)
      .where((w) => w.isNotEmpty)
      .map((w) => w.toLowerCase())
      .toList();
}
