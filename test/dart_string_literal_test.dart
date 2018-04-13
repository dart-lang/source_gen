import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:source_gen/src/dart_string_literal.dart';

final _badStrings = (jsonDecode(
        new File('test/big-list-of-naughty-strings.json')
            .readAsStringSync()) as List)
    .cast<String>();

final _testSource = '''
main() {
${_badStrings.map((l) => "  print(${dartStringLiteral(l)});").join('\n')}
}
''';

void main() {
  void testValue(String name, String value, String withEscaped$,
      [String withoutEscaped$]) {
    assert(withEscaped$ != withoutEscaped$,
        r'Just leave `withoutEscaped\$` unassigned!');
    test(name, () {
      var output = dartStringLiteral(value);
      expect(output, withEscaped$);
    });
    test('$name - explicit escape\$ true', () {
      var output = dartStringLiteral(value, escapeDollar: true);
      expect(output, withEscaped$);
    });
    test('$name - explicit escape\$ false', () {
      var output = dartStringLiteral(value, escapeDollar: false);
      expect(output, withoutEscaped$ ?? withEscaped$);
    });
  }

  testValue(
    'single quotes',
    "'",
    '"\'"',
  );
  testValue('double and single quotes', "'\"", "'\\'\\\"'");
  testValue('single and double quotes', '\'"\'', '\'\\\'\\"\\\'\'');

  testValue('single quotes and \$', r"$ENV{'HOME'}", 'r"\$ENV{\'HOME\'}"',
      '"\$ENV{\'HOME\'}"');

  testValue('backslash', '\\', "\'\\\\\'");
  testValue('newlines', '\n', "\'\\n\'");
  testValue('carriage returns', '\r', "\'\\r\'");
  testValue('\$', '\$', r"r'$'", "'\$'");

  group('bad strings', () {
    List<String> testOutput;
    setUpAll(() {
      var tempDir = Directory.systemTemp.createTempSync('test.source_gen.');

      try {
        var tempDartPath = p.join(tempDir.path, 'strings.dart');
        var tempDartFile = new File(tempDartPath);
        tempDartFile.writeAsStringSync(_testSource);

        var result =
            Process.runSync(Platform.resolvedExecutable, [tempDartPath]);
        if (result.exitCode != 0) {
          print(result.stdout);
          print(result.stderr);
          print(result.exitCode);
          fail('process failed!');
        }
        testOutput = LineSplitter.split(result.stdout as String).toList();
        expect(testOutput, hasLength(_badStrings.length));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    for (var i = 0; i < _badStrings.length; i++) {
      test('bad string ${i+i}', () {
        var testString = _badStrings[i];
        expect(testOutput[i], testString);
      });
    }
  });
}
