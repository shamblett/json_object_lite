# json_object_lite
[![Build Status](https://travis-ci.org/shamblett/json_object_lite.svg?branch=master)](https://travis-ci.org/shamblett/joson_object_lite)

json_object_lite allows dot notation access to JSON.parse'd objects, for Dart, lite version.

This package is a re-implementation of the [json_object](https://pub.dartlang.org/packages/json_object) package by Chris Buckett 
except it doesn't use mirrors and hence is a much lighter version. You of course lose the JSON serialization/deserialization of
the original package, however there are more advanced packages you can use for this purpose, e.g 
[dson](https://pub.dartlang.org/packages/dson).

Other than that this is a faithful, lighter, re-implementation intended as a drop in replacement for 
the original JsonObject. Please see the json_object documentation for further details.

Note that for compatibility with Dart 2.0 only construction from strings is now supported, there are
also a few other more minor updates, see the example for more details. 

