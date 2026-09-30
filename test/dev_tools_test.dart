import 'dart:convert';

import 'package:devhub/logic/dev_tools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('JSON format, minify and errors', () {
    expect(runTool(DevTool.jsonFormat, '{"a":[1,2]}').output,
        '{\n  "a": [\n    1,\n    2\n  ]\n}');
    expect(runTool(DevTool.jsonMinify, '{ "a" : 1 }').output, '{"a":1}');
    expect(
        runTool(DevTool.jsonFormat, '{bad').error, startsWith('Invalid JSON'));
    expect(runTool(DevTool.jsonFormat, '  ').error, 'Enter some JSON');
  });

  test('Base64 round-trips UTF-8 and accepts url-safe/unpadded input', () {
    final enc = runTool(DevTool.base64Encode, 'สวัสดี hi').output;
    expect(runTool(DevTool.base64Decode, enc).output, 'สวัสดี hi');
    expect(runTool(DevTool.base64Encode, 'hi?').output, 'aGk/');
    expect(runTool(DevTool.base64Decode, 'aGk_').output, 'hi?');
    expect(runTool(DevTool.base64Decode, 'aGk').output, 'hi');
    expect(runTool(DevTool.base64Decode, '@@@').isOk, isFalse);
  });

  test('URL encode/decode', () {
    expect(runTool(DevTool.urlEncode, 'a b&c=d/é').output,
        'a%20b%26c%3Dd%2F%C3%A9');
    expect(runTool(DevTool.urlDecode, 'a%20b%26c').output, 'a b&c');
    expect(runTool(DevTool.urlDecode, '%E0%A4%A').isOk, isFalse);
  });

  test('case conversion splits common identifier styles', () {
    expect(splitWords('helloWorld'), ['hello', 'world']);
    expect(splitWords('HTTPServer2 ready'), ['http', 'server2', 'ready']);
    expect(splitWords('--snake_case-and kebab--'),
        ['snake', 'case', 'and', 'kebab']);
    expect(runTool(DevTool.camelCase, 'user_id value').output, 'userIdValue');
    expect(runTool(DevTool.snakeCase, 'userIdValue').output, 'user_id_value');
    expect(runTool(DevTool.kebabCase, 'User Id Value').output, 'user-id-value');
    expect(runTool(DevTool.camelCase, '  ').output, '');
  });

  group('edge cases (pass 3)', () {
    test('JSON tools never change numbers or escapes', () {
      const input =
          '{"id": 12345678901234567890, "p": 1e2, "f": 1.50, "u": "\\u00e9"}';
      expect(
        runTool(DevTool.jsonMinify, input).output,
        '{"id":12345678901234567890,"p":1e2,"f":1.50,"u":"\\u00e9"}',
      );
      expect(
        runTool(DevTool.jsonFormat, input).output,
        '{\n  "id": 12345678901234567890,\n  "p": 1e2,\n  "f": 1.50,\n'
        '  "u": "\\u00e9"\n}',
      );
    });

    test('JSON strings keep structural characters and escaped quotes', () {
      const input = '{ "a" : "x, {y}: [z] \\" q" , "b":[ ] ,"c":{  }}';
      expect(
        runTool(DevTool.jsonMinify, input).output,
        '{"a":"x, {y}: [z] \\" q","b":[],"c":{}}',
      );
      expect(
        runTool(DevTool.jsonFormat, '[[],[1],{}]').output,
        '[\n  [],\n  [\n    1\n  ],\n  {}\n]',
      );
    });

    test('JSON scalars, unicode and trailing garbage', () {
      expect(
          runTool(DevTool.jsonFormat, ' "สวัสดี 😀" ').output, '"สวัสดี 😀"');
      expect(runTool(DevTool.jsonMinify, 'null').output, 'null');
      expect(runTool(DevTool.jsonFormat, '{"a":1} x').isOk, isFalse);
      expect(runTool(DevTool.jsonFormat, "{'a':1}").isOk, isFalse);
    });

    test('formatted JSON decodes to the same value as the input', () {
      const input = '{"a":[1,{"b":null,"c":[true,false]}],"d":"e\\n"}';
      final formatted = runTool(DevTool.jsonFormat, input).output;
      expect(jsonDecode(formatted), jsonDecode(input));
    });

    test('case tools keep accented and Thai words', () {
      expect(splitWords('café au lait'), ['café', 'au', 'lait']);
      expect(splitWords('สวัสดี_ชาวโลก'), ['สวัสดี', 'ชาวโลก']);
      expect(runTool(DevTool.camelCase, 'éclair value').output, 'éclairValue');
      expect(runTool(DevTool.snakeCase, 'Grüße aus Köln').output,
          'grüße_aus_köln');
      expect(runTool(DevTool.kebabCase, '😀 emoji 😀').output, 'emoji');
    });

    test('Base64 edge cases', () {
      expect(runTool(DevTool.base64Encode, '').output, '');
      expect(runTool(DevTool.base64Decode, '').output, '');
      expect(runTool(DevTool.base64Decode, 'aGVs\nbG8=\n').output, 'hello');
      expect(runTool(DevTool.base64Decode, 'a').isOk, isFalse);
      // Valid Base64 of bytes that are not UTF-8.
      expect(runTool(DevTool.base64Decode, '/w==').isOk, isFalse);
    });

    test('URL decode edge cases', () {
      expect(runTool(DevTool.urlDecode, '%').isOk, isFalse);
      expect(runTool(DevTool.urlDecode, 'a+b').output, 'a+b');
      expect(runTool(DevTool.urlEncode, '').output, '');
      expect(
          runTool(DevTool.urlDecode, runTool(DevTool.urlEncode, 'ก ข😀').output)
              .output,
          'ก ข😀');
    });
  });
}
