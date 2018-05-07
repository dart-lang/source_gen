import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:source_gen/src/dart_string_literal.dart';

void main() {
  group('targetted values', () {
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
  });

  testBadStringGroup('bad strings', _badStrings());
  testBadStringGroup('random strings', _randomStrings());
}

List<String> _randomStrings() {
  var rnd = new Random(0);
  return new List<String>.generate(20, (i) {
    return new String.fromCharCodes(
        new Iterable<int>.generate(10, (j) => rnd.nextInt(100)));
  });
}

List<String> _badStrings() =>
    (jsonDecode(new File('test/big-list-of-naughty-strings.json')
            .readAsStringSync()) as List)
        .cast<String>();

void testBadStringGroup(String name, List<String> badStrings) {
  group(name, () {
    List<String> testOutput;
    setUpAll(() {
      testOutput = _getLinesFromDartSource(badStrings);
      expect(testOutput, hasLength(badStrings.length));
    });

    for (var i = 0; i < badStrings.length; i++) {
      test('${i+i}', () {
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

    print(testSource);

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
