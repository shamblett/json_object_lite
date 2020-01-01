/*
 * Packge : json_object_lite
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/09/2017
 * Copyright :  S.Hamblett
 */

import 'dart:convert';
import 'package:json_object_lite/json_object_lite.dart';
import 'package:test/test.dart';

// ignore_for_file: omit_local_variable_types
// ignore_for_file: unnecessary_final
// ignore_for_file: cascade_invocations
// ignore_for_file: avoid_print
// ignore_for_file: avoid_annotating_with_dynamic
// ignore_for_file: lines_longer_than_80_chars

class Person extends JsonObjectLite<dynamic> {
  Person() : super();

  factory Person.fromString(String jsonString) =>
      JsonObjectLite<dynamic>.fromJsonString(jsonString, Person());
}

abstract class Address extends JsonObjectLite<dynamic> {
  String line1;
  String postcode;
}

abstract class AddressList extends JsonObjectLite<dynamic> {
  Address address;
}

class MyList extends JsonObjectLite<dynamic> {
  MyList();

  factory MyList.fromString(String jsonString) =>
      JsonObjectLite<dynamic>.fromJsonString(jsonString, MyList());
}

void main() {
  group('Construction', () {
    test('Default constructor', () {
      final JsonObjectLite<dynamic> jsonObject = JsonObjectLite<dynamic>();
      expect(jsonObject.isImmutable, false);
    });

    test('From JSON string', () {
      const String jsonString = '''
      {
        "name" : "Chris",
        "languages" : ["Dart","Java","C#","Python"],
        "handles" : {
          "googlePlus": {"name":"+Chris Buckett"},
          "twitter" : {"name":"@ChrisDoesDev"}
        },
        "blogs" : [
          {
             "name": "Dartwatch",
             "url": "http://dartwatch.com"
          },
          {
             "name": "ChrisDoesDev",
             "url": "http://chrisdoesdev.com"
          }
        ],
        "books" : [
          {
            "title": "Dart in Action",
            "chapters": [
              { 
                 "chapter1" : "Introduction to Dart",
                 "pages" : ["page1","page2","page3"]
              },
              { "chapter2" : "Dart tools"}
            ]
          }
        ]
      }
      ''';

      final dynamic o = JsonObjectLite<dynamic>.fromJsonString(jsonString);
      expect(o.isImmutable, true);

      // Basic access
      expect('Chris', equals(o.name));
      expect('Dart', equals(o.languages[0]));
      expect('Java', equals(o.languages[1]));

      // Maps within maps
      expect('+Chris Buckett', equals(o.handles.googlePlus.name));
      expect('@ChrisDoesDev', equals(o.handles.twitter.name));

      // maps within lists
      expect('Dartwatch', equals(o.blogs[0].name));
      expect('http://dartwatch.com', equals(o.blogs[0].url));
      expect('ChrisDoesDev', equals(o.blogs[1].name));
      expect('http://chrisdoesdev.com', equals(o.blogs[1].url));

      // Maps within lists within maps
      expect('Introduction to Dart', equals(o.books[0].chapters[0].chapter1));
      expect('page1', equals(o.books[0].chapters[0].pages[0]));
      expect('page2', equals(o.books[0].chapters[0].pages[1]));

      // Try an update
      o.handles.googlePlus.isImmutable = false;
      o.handles.googlePlus.name = '+ChrisB';
      expect('+ChrisB', equals(o.handles.googlePlus.name));
    });

    test('From JSON string - list', () {
      const String jsonString =
          '[1, 2, 3, 4, 5, "one", "two", "three", "four", "five", [6, 7, [8, 9]]]';

      final dynamic o = JsonObjectLite<dynamic>.fromJsonString(jsonString);
      expect(o.isImmutable, true);
      final List<dynamic> theList = o.toList();
      expect(theList.toString(),
          '[1, 2, 3, 4, 5, one, two, three, four, five, [6, 7, [8, 9]]]');
    });
  });

  group('Typing', () {
    test('Typed Object', () {
      final JsonObjectLite<dynamic> o = JsonObjectLite<dynamic>.fromJsonString(
          '{"Name": "Fred", "Sex": "male", "Age": 40}');
      expect(o.isImmutable, true);
      final dynamic dest =
          JsonObjectLite.toTypedJsonObjectLite(o, JsonObjectLite<dynamic>());
      expect(dest.Name, 'Fred');
      expect(dest.Sex, 'male');
      expect(dest.Age, 40);
      expect(dest.isImmutable, true);
    });

    test('Strong typing new', () {
      final dynamic person = Person();
      expect(person.isImmutable, false);
      bool thrown = false;
      try {
        expect(throwsNoSuchMethodError, person.name);
        // ignore: avoid_catching_errors
      } on NoSuchMethodError {
        thrown = true;
      }
      expect(thrown, true);
    });

    test('Strong typing new extendable', () {
      final dynamic person = Person();
      expect(person.isImmutable, false);
      person.isImmutable = false;
      person.name = 'Steve';
      expect(person.name, 'Steve');
      final String s = const JsonEncoder().convert(person);
      expect(s, equals('{"name":"Steve"}'));
    });

    test('Strong typing from JSON string', () {
      const String jsonString = '''
      {
        "addresses" : [
          { "address": {
              "line1": "1 the street",
              "postcode": "ab12 3de"
            }
          },
          { "address": {
              "line1": "1 the street",
              "postcode": "ab12 3de"
            }
          }
        ]
      }
      ''';
      final dynamic person = Person.fromString(jsonString);
      expect(person.isImmutable, true);
      expect(person.addresses[0].address.line1, equals('1 the street'));
      person.isImmutable = false;
      person.name = 'Steve';
      expect(person.name, 'Steve');
    });
  });

  group('String handling', () {
    test('Stringify', () {
      final dynamic person = JsonObjectLite<dynamic>();
      person.isImmutable = false;

      // Dynamically create some properties
      person.name = 'Chris';
      person.languages = <String>[];
      person.languages.add('Dart');
      person.languages.add('Java');

      // create a new JsonObjectLite that we will inject
      final dynamic address = JsonObjectLite<dynamic>();
      address.isImmutable = false;
      address.line1 = '1 the street';
      address.postcode = 'AB12 3DE';

      // add the address to the person
      person.address = address;

      // convert to a json string:
      final String json = const JsonEncoder().convert(person);
      expect(json,
          '{"name":"Chris","languages":["Dart","Java"],"address":{"line1":"1 the street","postcode":"AB12 3DE"}}');

      // convert back to a map
      final Map<dynamic, dynamic> convertedBack =
          const JsonDecoder(null).convert(json);

      // test
      expect(convertedBack['address']['line1'], equals(address.line1));
      expect(convertedBack['name'], equals(person.name));
    });

    test('toString - typed + Maps', () {
      final dynamic person = JsonObjectLite<dynamic>();
      person.isImmutable = false;

      // Dynamically create some properties
      person.name = 'Chris';
      person.languages = <String>[];
      person.languages.add('Dart');
      person.languages.add('Java');

      // create a new JsonObjectLite that we will inject
      final dynamic address = JsonObjectLite<dynamic>();
      address.isImmutable = false;
      address.line1 = '1 the street';
      address.postcode = 'AB12 3DE';

      // add the address to the person
      person.address = address;

      // convert to a json string using toString()
      final String json = person.toString();
      expect(json,
          '{"name":"Chris","languages":["Dart","Java"],"address":{"line1":"1 the street","postcode":"AB12 3DE"}}');
    });

    test('toString - List', () {
      final dynamic obj = JsonObjectLite<dynamic>();
      obj.foo = JsonObjectLite<dynamic>.fromJsonString('[1,2,3]');
      print(obj);
      expect(obj.toString(), '{"foo":[1,2,3]}');
    });
  });

  group('Iteration', () {
    test('List', () {
      const String testJson = '''
      [{"Dis":1111.1,"Flag":0,"Obj":{"ID":1,"Title":"Volvo 140"}},
      {"Dis":2222.2,"Flag":0,"Obj":{"ID":2,"Title":"Volvo 240"}}]
      ''';
      final MyList list = MyList.fromString(testJson);
      expect(list[0].Obj.Title, equals('Volvo 140'));
    });

    test('List Iterator', () {
      const String testJson = '''
      [{"Dis":1111.1,"Flag":0,"Obj":{"ID":1,"Title":"Volvo 140"}},
      {"Dis":2222.2,"Flag":0,"Obj":{"ID":2,"Title":"Volvo 240"}}]
      ''';
      final MyList jsonObject = MyList.fromString(testJson);

      String firstTitle = '';
      String secondTitle = '';

      for (final dynamic item in jsonObject.toIterable()) {
        if (firstTitle == '') {
          firstTitle = item.Obj.Title;
        } else {
          secondTitle = item.Obj.Title;
        }
      }
      expect(firstTitle, equals('Volvo 140'));
      expect(secondTitle, equals('Volvo 240'));
    });
  });

  group('Iterables', () {
    test('List', () {
      final dynamic o = JsonObjectLite<dynamic>();
      o.isImmutable = false;
      o.name = 'Steve';
      o.age = 55;
      o.sex = 'male';
      o.languages = <String>['dart', 'c', 'c++'];
      expect(o.name == 'Steve', isTrue);
      expect(o.contains(o.languages), isTrue);
      expect(o.elementAt(0), 'Steve');
      expect(o.every((dynamic element) => element == 55), isFalse);
      expect(o.expand((dynamic i) => <dynamic>[i]).toList(), <dynamic>[
        'Steve',
        55,
        'male',
        <String>['dart', 'c', 'c++']
      ]);
      expect(o.firstWhere((dynamic element) => element == 'male'), o.sex);
      o.sex2 = 'male';
      expect(o.lastWhere((dynamic element) => element == 'male'), o.sex2);
      expect(o.singleWhere((dynamic element) => element == 'male'), o.sex);
      final dynamic folder = JsonObjectLite<dynamic>();
      folder.isImmutable = false;
      folder.nfirst = 1;
      folder.nsecond = 2;
      folder.nthird = 3;
      expect(
          folder.fold(0, (dynamic prev, dynamic element) => prev + element), 6);
      expect(folder.reduce((dynamic value, dynamic element) => value + element),
          6);
      expect(folder.join('-'), '1-2-3');
      expect(folder.skip(2).length, 1);
      expect(folder.take(2).length, 2);
      expect(o.toList(), <dynamic>[
        'Steve',
        55,
        'male',
        <String>['dart', 'c', 'c++'],
        'male'
      ]);
      expect(o.toSet(), <dynamic>[
        'Steve',
        55,
        'male',
        <String>['dart', 'c', 'c++']
      ]);
      expect(folder.where((dynamic element) => element == 55), <dynamic>[]);
      expect(folder.first, 1);
      expect(folder.last, 3);
      final dynamic folder1 = JsonObjectLite<dynamic>();
      folder.isImmutable = false;
      folder1.none = 1;
      try {
        expect(folder1.single, folder1.none);
      } on Exception catch (ex) {
        expect(ex.toString(), 'Bad state: No element');
      }
      expect(o.iterator.toString().contains('Iterator'), true);
    });

    test('Map', () {
      final dynamic o = JsonObjectLite<dynamic>();
      o.isImmutable = false;
      o.name = 'Steve';
      o.age = 55;
      o.sex = 'male';
      o.languages = <String>['dart', 'c', 'c++'];
      expect(o.containsValue('Steve'), isTrue);
      expect(o.containsKey('languages'), isTrue);
      expect(o.isNotEmpty, isTrue);
      expect(o.isEmpty, isFalse);
      expect(o['name'], 'Steve');
      o.forEach((dynamic key, dynamic value) {
        print('$key = $value');
      });
      expect(o.keys.toList(), <String>['name', 'age', 'sex', 'languages']);
      expect(o.values.toList(), <dynamic>[
        'Steve',
        55,
        'male',
        <String>['dart', 'c', 'c++']
      ]);
      expect(o.length, 4);
      final Map<String, String> items = <String, String>{
        'pets': 'none',
        'colour': 'white'
      };
      o.addAll(items);
      expect(o.length, 6);
      expect(o.pets, 'none');
      expect(o.colour, 'white');
      o['middleName'] = 'James';
      expect(o.middleName, 'James');
      o.putIfAbsent('house', () => 6);
      expect(o.house, 6);
      final dynamic ret = o.remove('house');
      expect(ret, 6);
      expect(o.keys.toList(), <String>[
        'name',
        'age',
        'sex',
        'languages',
        'pets',
        'colour',
        'middleName'
      ]);
      o.clear();
      expect(o.length, 0);
    });
  });

  group('Misc', () {
    test('Exceptions', () {
      final JsonObjectLite<dynamic> o = JsonObjectLite<dynamic>();
      o.isImmutable = true;
      bool thrown = false;
      try {
        o['name'] = 'fred';
      } on Exception catch (ex) {
        expect(ex, const TypeMatcher<JsonObjectLiteException>());
        expect(
            ex.toString(), 'JsonObjectException: JsonObject is not extendable');
        thrown = true;
      }
      expect(thrown, true);
      thrown = false;
      try {
        o.putIfAbsent('house', () => 6);
      } on Exception catch (ex) {
        expect(ex, const TypeMatcher<JsonObjectLiteException>());
        expect(
            ex.toString(), 'JsonObjectException: JsonObject is not extendable');
        thrown = true;
      }
      expect(thrown, true);
      thrown = false;
      try {
        o.clear();
      } on Exception catch (ex) {
        expect(ex, const TypeMatcher<JsonObjectLiteException>());
        expect(
            ex.toString(), 'JsonObjectException: JsonObject is not extendable');
        thrown = true;
      }
      expect(thrown, true);
      thrown = false;
      try {
        o.remove('name');
      } on Exception catch (ex) {
        expect(ex, const TypeMatcher<JsonObjectLiteException>());
        expect(
            ex.toString(), 'JsonObjectException: JsonObject is not extendable');
        thrown = true;
      }
      expect(thrown, true);
    });

    test('Special characters', () {
      final dynamic o = JsonObjectLite<dynamic>.fromJsonString(
          '{"_rev": "100678", "@rev2": "300400", "+": "200700"}');
      expect(o._rev, '100678');
      expect(o['@rev2'], '300400');
      expect(o['+'], '200700');
      final dynamic p = JsonObjectLite<dynamic>.fromJsonString(
          '{"_rev": "100678", "@rev2": "300400", "+": "200700"}');
      expect(p._rev, '100678');
      expect(p['@rev2'], '300400');
      expect(p['+'], '200700');
    });

    test('Debug', () {
      enableJsonObjectLiteDebugMessages = true;
      final dynamic o = JsonObjectLite<dynamic>();
      o.isImmutable = false;
      o.name = 'fred';
      bool thrown = false;
      try {
        print(o.address);
        // ignore: avoid_catching_errors
      } on NoSuchMethodError {
        thrown = true;
      }
      expect(thrown, true);
    });
  });
}
