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
}
