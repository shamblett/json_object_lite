///
/// This example is taken from the following article :-
/// http://www.dartlang.org/articles/json-web-service/
///

import 'package:json_object_lite/json_object_lite.dart';

/// The Dart 2.0 update has changed how JsonObjectLite is used, previously you could do this :-
///
/// JsonObjectLite o = new JsonObjectLite.fromJSonString('........');
/// print(o.bob);
/// print(o.fred);
/// ....
///
/// If you do this now the o.bob line will be flagged by the analyser as 'the getter bob is not defined.....'
/// which is correct, its not. This was suppressed in Dart 1.0 by annotating the class with 'proxy'.
/// This annotation has been deprecated in Dart 2.0 hence the error.
///
/// The fix for Dart 2.0 is to do this :-
/// dynamic o = new JsonObjectLite.fromJSonString('........');
///
/// Declaring the created object as dynamic gives the analyzer no clues about the
/// objects structure and hence it produces no errors.
///
/// This is unfortunate in the fact the user code has to change to accommodate this but
/// in the long run its cleaner as we now know that we don't know the object structure if
/// you see what I mean.
///
/// An example taken from the dartlang article for JSON object, found here
/// https://webdev.dartlang.org/articles/get-data/json-web-service.

class LanguageWebsite extends JsonObjectLite {
  LanguageWebsite(); // default constructor (empty) implementation

  factory LanguageWebsite.fromJsonString(String json) {
    // from JSON constructor implementation
    final languageWebsite =
    new LanguageWebsite(); // create an empty instance of this class
    // Create an instance of JsonObjectLite, populated with the json string and
    // injecting the _LanguageWebsite instance.
    final jsonObject = new JsonObjectLite.fromJsonString(json, languageWebsite);
    return jsonObject; // return the populated JsonObject instance
  }

  factory LanguageWebsite.fromJsonObject(JsonObjectLite jsonObject) {
    return JsonObjectLite.toTypedJsonObjectLite(
        jsonObject, new LanguageWebsite());
  }
}

class Language extends JsonObjectLite {
  Language(); // empty, default constructor

  factory Language.fromJsonString(String json) {
    // from JSON constructor implementation
    return new JsonObjectLite.fromJsonString(
        json, new Language()); // as _LangaugeWebsite, return an instance
    // of JsonObjectLite, containing the json string and
    // injecting a _Language instance
  }
}

int main() {
  final responseText = """
{
  "language": "dart", 
  "targets": ["dartium","javascript"], 
  "website": {
    "homepage": "www.dartlang.org",
    "api": "api.dartlang.org"
  }
}""";
  final dynamic data = new Language.fromJsonString(responseText);

  // tools can now validate the property access
  print(data.language); // should be dart
  print(data.targets[0]); // should be dartium

  // nested types are also strongly typed
  final dynamic website = new LanguageWebsite.fromJsonObject(
      data.website); // contains a JsonObjectLite
  print(website.homepage);
  website.isImmutable = false; // Now we can extend it
  website.homepage = "http://www.dartlang.org";
  print(website.homepage);

  return 0;
}
