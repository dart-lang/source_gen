// GENERATED CODE - DO NOT MODIFY BY HAND

part of source_gen.test.example;

// **************************************************************************
// Generator: JsonSerializableGenerator
// Target: class ListGenericTests
// **************************************************************************

ListGenericTests _$ListGenericTestsFromJson(Map json) => new ListGenericTests()
  ..iterable = (json['iterable'] as List)?.map((v0) => v0)
  ..dynamicIterable = (json['dynamicIterable'] as List)?.map((v0) => v0)
  ..objectIterable = (json['objectIterable'] as List)?.map((v0) => v0 as Object)
  ..intIterable = (json['intIterable'] as List)?.map((v0) => v0 as int)
  ..dateTimeIterable = (json['dateTimeIterable'] as List)
      ?.map((v0) => v0 == null ? null : DateTime.parse(v0));

abstract class _$ListGenericTestsSerializerMixin {
  Iterable get iterable;
  Iterable get dynamicIterable;
  Iterable get objectIterable;
  Iterable get intIterable;
  Iterable get dateTimeIterable;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'iterable': iterable,
        'dynamicIterable': dynamicIterable,
        'objectIterable': objectIterable,
        'intIterable': intIterable,
        'dateTimeIterable': dateTimeIterable
      };
}

// **************************************************************************
// Generator: JsonSerializableGenerator
// Target: class Person
// **************************************************************************

Person _$PersonFromJson(Map json) =>
    new Person(json['firstName'] as String, json['lastName'] as String,
        middleName: json['middleName'] as String,
        dateOfBirth: json['dateOfBirth'] == null
            ? null
            : DateTime.parse(json['dateOfBirth']));

abstract class _$PersonSerializerMixin {
  String get firstName;
  String get middleName;
  String get lastName;
  DateTime get dateOfBirth;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'dateOfBirth': dateOfBirth?.toIso8601String()
      };
}

// **************************************************************************
// Generator: JsonSerializableGenerator
// Target: class Order
// **************************************************************************

Order _$OrderFromJson(Map json) => new Order((json['items'] as List)
    ?.map((v0) => v0 == null ? null : new Item.fromJson(v0)))
  ..count = json['count'] as int
  ..isRushed = json['isRushed'] as bool;

abstract class _$OrderSerializerMixin {
  int get count;
  bool get isRushed;
  UnmodifiableListView get items;
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'count': count, 'isRushed': isRushed, 'items': items};
}

// **************************************************************************
// Generator: JsonSerializableGenerator
// Target: class Item
// **************************************************************************

Item _$ItemFromJson(Map json) => new Item(json['price'] as int)
  ..itemNumber = json['itemNumber'] as int
  ..saleDates = (json['saleDates'] as List)
      ?.map((v0) => v0 == null ? null : DateTime.parse(v0))
      ?.toList()
  ..rates = (json['rates'] as List)?.map((v0) => v0 as int)?.toList();

abstract class _$ItemSerializerMixin {
  int get price;
  int get itemNumber;
  List get saleDates;
  List get rates;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'price': price,
        'itemNumber': itemNumber,
        'saleDates': saleDates?.map((v0) => v0?.toIso8601String())?.toList(),
        'rates': rates
      };
}
