// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_gen.example.example;

import 'package:source_gen/generators/json_serializable.dart';
import 'package:source_gen/generators/json_literal.dart';

part 'example.g.dart';

void main() {
  var bigOrder = new BigOrder()
    ..items = [
      new Item()
        ..itemNumber = 1
        ..count = 1
        ..isRushed = true,
      new Item()
        ..itemNumber = 2
        ..count = 3
        ..isRushed = true,
      new Item()
        ..itemNumber = 4
        ..count = 1
        ..isRushed = true
    ];
  print(bigOrder.toJson());
  var deserialized = new BigOrder.fromJson(bigOrder.toJson());
  print(deserialized.items.length);
}

@JsonSerializable()
class Person extends Object with _$PersonSerializerMixin {
  final String firstName, middleName, lastName;
  final DateTime dateOfBirth;

  Person(this.firstName, this.lastName, {this.middleName, this.dateOfBirth});

  factory Person.fromJson(json) => _$PersonFromJson(json);
}

@JsonSerializable()
class Order extends Object with _$OrderSerializerMixin {
  int count;
  int itemNumber;
  bool isRushed;
  Item item;

  Order();

  factory Order.fromJson(json) => _$OrderFromJson(json);
}

@JsonSerializable()
class BigOrder extends Object with _$BigOrderSerializerMixin {
  int count;
  int itemNumber;
  bool isRushed;
  List<Item> items;

  BigOrder();

  factory BigOrder.fromJson(json) => _$BigOrderFromJson(json);
}

@JsonSerializable()
class Item extends Object with _$ItemSerializerMixin {
  int count;
  int itemNumber;
  bool isRushed;

  Item();

  factory Item.fromJson(json) => _$ItemFromJson(json);
}

@JsonLiteral('data.json')
Map get glossaryData => _$glossaryDataJsonLiteral;
