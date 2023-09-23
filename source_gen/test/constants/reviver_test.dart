import 'package:_test_annotations/test_annotations.dart';
import 'package:build_test/build_test.dart';
import 'package:source_gen/src/constants/reader.dart';
import 'package:source_gen/src/constants/reviver.dart';
import 'package:test/test.dart';

void main() {
  group('Reviver', () {
    group('revives classes', () {
      group('returns qualified class', () {
        const declSrc = r'''
library test_lib;

import 'package:_test_annotations/test_annotations.dart';

@TestAnnotation()
class TestClassSimple {}

@TestAnnotationWithComplexObject(ComplexObject(SimpleObject(1)))
class TestClassComplexPositional {}

@TestAnnotationWithComplexObject(ComplexObject(SimpleObject(1), cEnum: CustomEnum.v2))
class TestClassComplexPositionalAndNamed {}
''';
        test('with simple objects', () async {
          final reader = (await resolveSource(
            declSrc,
            (resolver) async => (await resolver.findLibraryByName('test_lib'))!,
          ))
              .getClass('TestClassSimple')!
              .metadata
              .map((e) => ConstantReader(e.computeConstantValue()!))
              .toList()
              .first;

          final reviver = Reviver(reader);
          final instance = reviver.toInstance();
          expect(instance, isNotNull);
          expect(instance, isA<TestAnnotation>());
        });

        for (final s in ['Positional', 'PositionalAndNamed']) {
          test('with complex objects: $s', () async {
            final reader = (await resolveSource(
              declSrc,
              (resolver) async =>
                  (await resolver.findLibraryByName('test_lib'))!,
            ))
                .getClass('TestClassComplex$s')!
                .metadata
                .map((e) => ConstantReader(e.computeConstantValue()!))
                .toList()
                .first;

            final reviver = Reviver(reader);
            final instance = reviver.toInstance();
            expect(instance, isNotNull);
            expect(instance, isA<TestAnnotationWithComplexObject>());
            instance as TestAnnotationWithComplexObject;

            expect(instance.object, isNotNull);
            expect(instance.object.sObj.i, 1);
            expect(instance.object.sObj2, isNull);

            if (s == 'PositionalAndNamed') {
              expect(instance.object.cEnum, isNotNull);
              expect(instance.object.cEnum, CustomEnum.v2);
            }
          });
        }
      });
    });
  });
}
