/*
 * Packge : json_object_lite
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/09/2017
 * Copyright :  S.Hamblett
 */

import 'dart:convert';
import 'package:json_object_lite/json_object_lite.dart';
import 'package:test/test.dart';

@proxy
class Person extends JsonObjectLite {
  Person() : super();

  factory Person.fromString(String jsonString) {
    return new JsonObjectLite.fromJsonString(jsonString, new Person());
  }
}

abstract class Address extends JsonObjectLite {
  String line1;
  String postcode;
}

abstract class AddressList extends JsonObjectLite {
  Address address;
}

void main() {
  group("Construction", () {
    test("Default constructor", () {
      final JsonObjectLite jsonObject = new JsonObjectLite();
      expect(jsonObject.isImmutable, true);
    });

    test("From JSON string", () {
      final String jsonString = """
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
      """;

      final JsonObjectLite o = new JsonObjectLite.fromJsonString(jsonString);
      expect(o.isImmutable, false);

      // Basic access
      expect("Chris", equals(o.name));
      expect("Dart", equals(o.languages[0]));
      expect("Java", equals(o.languages[1]));

      // Maps within maps
      expect("+Chris Buckett", equals(o.handles.googlePlus.name));
      expect("@ChrisDoesDev", equals(o.handles.twitter.name));

      // maps within lists
      expect("Dartwatch", equals(o.blogs[0].name));
      expect("http://dartwatch.com", equals(o.blogs[0].url));
      expect("ChrisDoesDev", equals(o.blogs[1].name));
      expect("http://chrisdoesdev.com", equals(o.blogs[1].url));

      // Maps within lists within maps
      expect("Introduction to Dart", equals(o.books[0].chapters[0].chapter1));
      expect("page1", equals(o.books[0].chapters[0].pages[0]));
      expect("page2", equals(o.books[0].chapters[0].pages[1]));

      // Try an update
      o.handles.googlePlus.name = "+ChrisB";
      expect("+ChrisB", equals(o.handles.googlePlus.name));
    });

    test("From Map", () {
      final Map jsonMap = {
        "name": "Chris",
        "languages": ["Dart", "Java", "C#", "Python"],
        "handles": {
          "googlePlus": {"name": "+Chris Buckett"},
          "twitter": {"name": "@ChrisDoesDev"}
        },
        "blogs": [
          {"name": "Dartwatch", "url": "http://dartwatch.com"},
          {"name": "ChrisDoesDev", "url": "http://chrisdoesdev.com"}
        ],
        "books": [
          {
            "title": "Dart in Action",
            "chapters": [
              {
                "chapter1": "Introduction to Dart",
                "pages": ["page1", "page2", "page3"]
              },
              {"chapter2": "Dart tools"}
            ]
          }
        ]
      };

      final JsonObjectLite o = new JsonObjectLite.fromMap(jsonMap);
      expect(o.isImmutable, false);

      // Basic access
      expect("Chris", equals(o.name));
      expect("Dart", equals(o.languages[0]));
      expect("Java", equals(o.languages[1]));

      // Maps within maps
      expect("+Chris Buckett", equals(o.handles.googlePlus.name));
      expect("@ChrisDoesDev", equals(o.handles.twitter.name));

      // maps within lists
      expect("Dartwatch", equals(o.blogs[0].name));
      expect("http://dartwatch.com", equals(o.blogs[0].url));
      expect("ChrisDoesDev", equals(o.blogs[1].name));
      expect("http://chrisdoesdev.com", equals(o.blogs[1].url));

      // Maps within lists within maps
      expect("Introduction to Dart", equals(o.books[0].chapters[0].chapter1));
      expect("page1", equals(o.books[0].chapters[0].pages[0]));
      expect("page2", equals(o.books[0].chapters[0].pages[1]));

      // Try an update
      o.handles.googlePlus.name = "+ChrisB";
      expect("+ChrisB", equals(o.handles.googlePlus.name));
    });
  });

  group("Typing", () {
    test("Typed Object", () {
      final JsonObjectLite o = new JsonObjectLite.fromMap(
          {"Name": "Fred", "Sex": "male", "Age": 40});
      expect(o.isImmutable, false);
      final JsonObjectLite dest =
      JsonObjectLite.toTypedJsonObjectLite(o, new JsonObjectLite());
      expect(dest.Name, "Fred");
      expect(dest.Sex, "male");
      expect(dest.Age, 40);
      expect(dest.isImmutable, true);
    });

    test("Strong typing new", () {
      final Person person = new Person();
      expect(person.isImmutable, true);
      bool thrown = false;
      try {
        expect(throwsNoSuchMethodError, person.name);
      } catch (ex) {
        thrown = true;
      }
      expect(thrown, true);
    });

    test("Strong typing new extendable", () {
      final Person person = new Person();
      expect(person.isImmutable, true);
      person.isImmutable = false;
      person.name = "Steve";
      expect(person.name, "Steve");
      final String s = new JsonEncoder().convert(person);
      expect(s, equals('{"name":"Steve"}'));
    });

    test("Strong typing from JSON string", () {
      final String jsonString = """
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
      """;
      final Person person = new Person.fromString(jsonString);
      expect(person.isImmutable, false);
      expect(person.addresses[0].address.line1, equals("1 the street"));
      person.name = "Steve";
      expect(person.name, "Steve");
    });
  });
}
