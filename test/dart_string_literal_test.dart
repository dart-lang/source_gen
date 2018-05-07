import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:source_gen/src/dart_string_literal.dart';

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
    var badStrings = (jsonDecode(
            new File('test/big-list-of-naughty-strings.json')
                .readAsStringSync()) as List)
        .cast<String>();
    setUpAll(() {
      testOutput = _getLinesFromDartSource(badStrings);
      expect(testOutput, hasLength(badStrings.length));
    });

    for (var i = 0; i < badStrings.length; i++) {
      test('bad string ${i+i}', () {
        var testString = badStrings[i];
        expect(testOutput[i], testString);
      });
    }
  });
}

List<String> _getLinesFromDartSource(List<String> literals) {
  var tempDir = Directory.systemTemp.createTempSync('test.source_gen.');

  try {
    var tempDartPath = p.join(tempDir.path, 'strings.dart');
    var tempDartFile = new File(tempDartPath);

    var testSource = '''
main() {
${literals.map((l) => "  print(${dartStringLiteral(l)});").join('\n')}
}
''';

    tempDartFile.writeAsStringSync(testSource);

    var result = Process.runSync(Platform.resolvedExecutable, [tempDartPath]);
    if (result.exitCode != 0) {
      print(result.stdout);
      print(result.stderr);
      print(result.exitCode);
      fail('process failed!');
    }
    return LineSplitter.split(result.stdout as String).toList();
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}
