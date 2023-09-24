/// A sample library for the Annotations used during testing.
library _test_annotations;

class TestAnnotation {
  const TestAnnotation();
}

class TestAnnotationWithComplexObject {
  final ComplexObject object;
  const TestAnnotationWithComplexObject(this.object);
}

class TestAnnotationWithSimpleObject {
  final SimpleObject obj;
  const TestAnnotationWithSimpleObject(this.obj);
}

class SimpleObject {
  final int i;
  const SimpleObject(this.i);
}

class ComplexObject {
  final SimpleObject sObj;
  final CustomEnum? cEnum;
  final Map<String, ComplexObject>? cMap;
  final List<ComplexObject>? cList;
  final Set<ComplexObject>? cSet;
  const ComplexObject(
    this.sObj, {
    this.cEnum,
    this.cMap,
    this.cList,
    this.cSet,
  });
}

enum CustomEnum {
  v1,
  v2,
  v3;
}
