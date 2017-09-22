/*
 * Packge : json_object_lite
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/09/2017
 * Copyright :  S.Hamblett
 */

import 'package:json_object_lite/json_object_lite.dart';
import 'package:test/test.dart';

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
}
