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

class MyList extends JsonObjectLite {
  MyList();

  factory MyList.fromString(String jsonString) {
    return new JsonObjectLite.fromJsonString(jsonString, new MyList());
  }
}

void main() {
  group("Construction", () {
    test("Default constructor", () {
      final JsonObjectLite jsonObject = new JsonObjectLite();
      expect(jsonObject.isImmutable, true);
    });

    test("From JSON string - Map", () {
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

    test("From JSON string - list", () {
      final String jsonString =
          '[1, 2, 3, 4, 5, "one", "two", "three", "four", "five"]';

      final JsonObjectLite o = new JsonObjectLite.fromJsonString(jsonString);
      expect(o.isImmutable, false);
      final List theList = o.toList();
      expect(
          theList.toString(), '[1, 2, 3, 4, 5, one, two, three, four, five]');
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

  group("String handling", () {
    test("Stringify", () {
      final JsonObjectLite person = new JsonObjectLite();
      person.isImmutable = false;

      // Dynamically create some properties
      person.name = "Chris";
      person.languages = new List();
      person.languages.add("Dart");
      person.languages.add("Java");

      // create a new JsonObjectLite that we will inject
      final JsonObjectLite address = new JsonObjectLite();
      address.isImmutable = false;
      address.line1 = "1 the street";
      address.postcode = "AB12 3DE";

      // add the address to the person
      person.address = address;

      // convert to a json string:
      final String json = new JsonEncoder().convert(person);
      expect(json,
          '{"name":"Chris","languages":["Dart","Java"],"address":{"line1":"1 the street","postcode":"AB12 3DE"}}');

      // convert back to a map
      final Map convertedBack = new JsonDecoder(null).convert(json);

      // test
      expect(convertedBack["address"]["line1"], equals(address.line1));
      expect(convertedBack["name"], equals(person.name));
    });

    test("toString", () {
      final JsonObjectLite person = new JsonObjectLite();
      person.isImmutable = false;

      // Dynamically create some properties
      person.name = "Chris";
      person.languages = new List();
      person.languages.add("Dart");
      person.languages.add("Java");

      // create a new JsonObjectLite that we will inject
      final JsonObjectLite address = new JsonObjectLite();
      address.isImmutable = false;
      address.line1 = "1 the street";
      address.postcode = "AB12 3DE";

      // add the address to the person
      person.address = address;

      // convert to a json string using toString()
      final String json = person.toString();
      expect(json,
          '{"name":"Chris","languages":["Dart","Java"],"address":{"line1":"1 the street","postcode":"AB12 3DE"}}');
    });
  });

  group("Iteration", () {
    test("List", () {
      final String testJson = """
      [{"Dis":1111.1,"Flag":0,"Obj":{"ID":1,"Title":"Volvo 140"}},
      {"Dis":2222.2,"Flag":0,"Obj":{"ID":2,"Title":"Volvo 240"}}]
      """;
      final MyList list = new MyList.fromString(testJson);
      expect(list[0].Obj.Title, equals("Volvo 140"));
    });

    test("List Iterator", () {
      final String testJson = """
      [{"Dis":1111.1,"Flag":0,"Obj":{"ID":1,"Title":"Volvo 140"}},
      {"Dis":2222.2,"Flag":0,"Obj":{"ID":2,"Title":"Volvo 240"}}]
      """;
      final MyList jsonObject = new MyList.fromString(testJson);

      var firstTitle = "";
      var secondTitle = "";

      for (var item in jsonObject.toIterable()) {
        if (firstTitle == "") {
          firstTitle = item.Obj.Title;
        } else {
          secondTitle = item.Obj.Title;
        }
      }
      expect(firstTitle, equals("Volvo 140"));
      expect(secondTitle, equals("Volvo 240"));
    });
  });

  group("Utility", () {
    test("Debug", () {
      enableJsonObjectLiteDebugMessages = true;
      final o = new JsonObjectLite();
      o.isImmutable = true;
      o.name = "fred";
      bool thrown = false;
      try {
        print(o.address);
      } catch (ex) {
        thrown = true;
      }
      expect(thrown, true);
    });
  });
}
