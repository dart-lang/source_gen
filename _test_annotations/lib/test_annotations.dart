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
  final SimpleObject? sObj2;
  final CustomEnum? cEnum;
  const ComplexObject(this.sObj, {this.sObj2 = null, this.cEnum = null});
}

enum CustomEnum {
  v1,
  v2,
  v3;
}
