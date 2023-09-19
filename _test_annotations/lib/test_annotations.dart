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
  const ComplexObject(this.sObj, {this.sObj2 = null});
}
