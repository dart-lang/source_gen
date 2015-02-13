library source_gen.generated_output;

import 'dart:async';
import 'package:analyzer/src/generated/element.dart';

import 'generator.dart';

class GeneratedOutput {
  final Element sourceMember;
  final Future<String> output;
  final Generator generator;

  GeneratedOutput(this.sourceMember, this.generator, this.output);
}
