/*
 * Package : JsonObjectLite
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/09/2017
 * Copyright :  S.Hamblett
 * Based on json_object (C) 2013 Chris Buckett (chrisbuckett@gmail.com)
 */

library json_object_lite;

import "dart:convert";

/// Set to true to as required
bool enableJsonObjectLiteDebugMessages = false;

/// Debug logger
void _log(String obj) {
  if (enableJsonObjectLiteDebugMessages) {
    print(obj);
  }
}

/// JsonObjectLite allows .property name access to JSON by using
/// noSuchMethod. The object is set to not immutable so properties can be
/// added.
@proxy
class JsonObjectLite<E> extends Object implements Map {
  /// Default constructor.
  /// Creates a new empty map.
  JsonObjectLite() {
    _objectData = new Map();
    isImmutable = false;
  }

  /// Eager constructor parses [jsonString] using [JsonDecoder].
  ///
  /// If [t] is given, will replace [t]'s contents from the string and return [t].
  ///
  /// If [recursive] is true, replaces all maps recursively with JsonObjects.
  /// The default value is [true].
  /// The object is set to immutable, the user must reset this to add more properties.
  factory JsonObjectLite.fromJsonString(String jsonString,
      [JsonObjectLite t, bool recursive = true]) {
    if (t == null) {
      t = new JsonObjectLite();
    }
    t._objectData = decoder.convert(jsonString);
    if (recursive) {
      t._extractElements(t._objectData);
    }
    t.isImmutable = true;
    return t;
  }

  /// An alternate constructor, allows creating directly from a map
  /// rather than a json string.
  ///
  /// If [recursive] is true, all values of the map will be converted
  /// to [JsonObjectLite]s as well. The default value is [true].
  /// The object is set to immutable, the user must reset this to add more properties.
  JsonObjectLite.fromMap(Map map, [bool recursive = true]) {
    _objectData = map;
    if (recursive) {
      _extractElements(_objectData);
    }
    isImmutable = true;
  }

  /// Typed JsonObjectLite
  static JsonObjectLite toTypedJsonObjectLite(
      JsonObjectLite src, JsonObjectLite dest) {
    dest._objectData = src._objectData;
    if (src.isImmutable) {
      dest.isImmutable = true;
    }
    return dest;
  }

  /// Contains either a [List] or [Map]
  dynamic _objectData;

  static JsonEncoder encoder = new JsonEncoder();
  static JsonDecoder decoder = new JsonDecoder(null);

  /// isImmutable indicates if a new item can be added to the internal
  /// map via the noSuchMethod property, or the functions inherited from the
  /// map interface.
  ///
  /// If set to true, then only the properties that were
  /// in the original map or json string passed in can be used.
  ///
  /// If set to false, then calling o.blah="123" will create a new blah property
  /// if it didn't already exist.
  ///
  /// Set to true by default when a JsonObjectLite is created with [JsonObjectLite.fromJsonString()]
  /// or [JsonObjectLite.fromMap()].
  /// The default constructor [JsonObjectLite()], sets this value to
  /// false so properties can be added.
  set isImmutable(bool state) => isExtendable = !state;

  bool get isImmutable => !isExtendable;

  @deprecated

  /// For compatibility the isExtendable boolean is preserved, however new usage
  /// should use isImmutable above. Usage is as per JsonObject.
  bool isExtendable;

  /// Returns a string representation of the underlying object data
  String toString() {
    return encoder.convert(_objectData);
  }

  /// Returns either the underlying parsed data as an iterable list (if the
  /// underlying data contains a list), or returns the map.values (if the
  /// underlying data contains a map).
  Iterable toIterable() {
    if (_objectData is Iterable) {
      return _objectData;
    }
    return _objectData.values;
  }

  /// noSuchMethod()
  /// If we try to access a property using dot notation (eg: o.wibble ), then
  /// noSuchMethod will be invoked, and identify the getter or setter name.
  /// It then looks up in the map contained in _objectData (represented using
  /// this (as this class implements [Map], and forwards it's calls to that
  /// class.
  /// If it finds the getter or setter then it either updates the value, or
  /// replaces the value.
  ///
  /// If isImmutable = true, then it will disallow the property access
  /// even if the property doesn't yet exist.
  dynamic noSuchMethod(Invocation mirror) {
    int positionalArgs = 0;
    if (mirror.positionalArguments != null)
      positionalArgs = mirror.positionalArguments.length;
    String property = "Not Found";

    if (mirror.isGetter && (positionalArgs == 0)) {
      // Synthetic getter
      property = _symbolToString(mirror.memberName);
      if (this.containsKey(property)) {
        return this[property];
      }
    } else if (mirror.isSetter && positionalArgs == 1) {
      // Synthetic setter
      // If the property doesn't exist, it will only be added
      // if isImmutable = false
      property = _symbolToString(mirror.memberName, true);
      if (!isImmutable) {
        this[property] = mirror.positionalArguments[0];
      }
      return this[property];
    }

    // If we get here, then we've not found it - throw.
    _log("noSuchMethod:: Not found: ${property}");
    _log("noSuchMethod:: IsGetter: ${mirror.isGetter}");
    _log("noSuchMethod:: IsSetter: ${mirror.isGetter}");
    _log("noSuchMethod:: isAccessor: ${mirror.isAccessor}");
    return super.noSuchMethod(mirror);
  }

  /// If the object passed in is a MAP, then we iterate through each of
  /// the values of the map, and if any value is a map, then we create a new
  /// [JsonObjectLite] replacing that map in the original data with that [JsonObjectLite]
  /// to a new [JsonObjectLite].  If the value is a Collection, then we call this
  /// function recursively.
  ///
  /// If the object passed in is a Collection, then we iterate through
  /// each item.  If that item is a map, then we replace the item with a
  /// [JsonObjectLite] created from the map.  If the item is a Collection, then we
  /// call this function recursively.
  ///
  void _extractElements(data) {
    if (data is Map) {
      // Iterate through each of the k,v pairs, replacing maps with jsonObjects
      data.forEach((key, value) {
        if (value is Map) {
          // Replace the existing Map with a JsonObject
          data[key] = new JsonObjectLite.fromMap(value);
        } else if (value is List) {
          // Recurse
          _extractElements(value);
        }
      });
    } else if (data is List) {
      // Iterate through each of the items
      // If any of them is a list, check to see if it contains a map

      for (int i = 0; i < data.length; i++) {
        // Use the for loop so that we can index the item to replace it if req'd
        final listItem = data[i];
        if (listItem is List) {
          // Recurse
          _extractElements(listItem);
        } else if (listItem is Map) {
          // Replace the existing Map with a JsonObject
          data[i] = new JsonObjectLite.fromMap(listItem);
        }
      }
    }
  }

  /// Convert the incoming method name(symbol) into a string, without using mirrors.
  String _symbolToString(dynamic value, [bool isSetter = false]) {
    String ret;
    if (value is Symbol) {
      // Brittle but we avoid mirrors
      final String name = value.toString();
      ret = name.substring((name.indexOf('"') + 1), name.lastIndexOf('"'));
      // Setters have an '=' on the end, remove it
      if (isSetter) {
        ret = ret.replaceFirst("=", "", ret.length - 1);
      }
    } else {
      ret = value.toString();
    }
    _log("_symbolToString:: Method name is: ${ret}");
    return ret;
  }

  ///
  /// Iterable implementation methods and properties
  ///

  bool any(bool f(dynamic element)) => this.toIterable().any(f);

  bool contains(dynamic element) => this.toIterable().contains(element);

  E elementAt(int index) => this.toIterable().elementAt(index);

  bool every(bool f(dynamic element)) => this.toIterable().every(f);

  Iterable<T> expand<T>(dynamic f(dynamic element)) =>
      this.toIterable().expand(f);

  dynamic firstWhere(bool test(dynamic value), {dynamic orElse}) =>
      this.toIterable().firstWhere(test, orElse: orElse);

  T fold<T>(T initialValue, T combine(T a, dynamic b)) =>
      this.toIterable().fold(initialValue, combine);

  String join([String separator = ""]) => this.toIterable().join(separator);

  dynamic lastWhere(bool test(dynamic value), {dynamic orElse}) =>
      this.toIterable().firstWhere(test, orElse: orElse);

  Iterable<T> map<T>(dynamic f(dynamic element)) => this.toIterable().map(f);

  dynamic reduce(dynamic combine(dynamic value, dynamic element)) =>
      this.toIterable().reduce(combine);

  dynamic singleWhere(bool test(dynamic value), {dynamic orElse}) =>
      this.toIterable().firstWhere(test, orElse: orElse);

  Iterable<E> skip(int n) => this.toIterable().skip(n);

  Iterable<E> skipWhile(bool test(dynamic value)) =>
      this.toIterable().skipWhile(test);

  Iterable<E> take(int n) => this.toIterable().take(n);

  Iterable<E> takeWhile(bool test(dynamic value)) =>
      this.toIterable().takeWhile(test);

  List<dynamic> toList({bool growable: true}) =>
      this.toIterable().toList(growable: growable);

  Set<dynamic> toSet() => this.toIterable().toSet();

  Iterable<E> where(bool f(dynamic element)) => this.toIterable().where(f);

  E get first => this.toIterable().first;

  Iterator<E> get iterator => this.toIterable().iterator;

  E get last => this.toIterable().last;

  E get single => this.toIterable().single;

  ///
  /// Map implementation methods and properties *
  ///

  // Pass through to the inner _objectData map.
  bool containsValue(dynamic value) => _objectData.containsValue(value);

  // Pass through to the inner _objectData map.
  bool containsKey(dynamic value) {
    return _objectData.containsKey(_symbolToString(value));
  }

  // Pass through to the inner _objectData map.
  bool get isNotEmpty => _objectData.isNotEmpty;

  // Pass through to the inner _objectData map.
  dynamic operator [](dynamic key) => _objectData[key];

  // Pass through to the inner _objectData map.
  void forEach(void func(dynamic key, dynamic value)) =>
      _objectData.forEach(func);

  // Pass through to the inner _objectData map.
  Iterable get keys => _objectData.keys;

  // Pass through to the inner _objectData map.
  Iterable get values => _objectData.values;

  // Pass through to the inner _objectData map.
  int get length => _objectData.length;

  // Pass through to the inner _objectData map.
  bool get isEmpty => _objectData.isEmpty;

  // Pass through to the inner _objectData map.
  void addAll(dynamic items) => _objectData.addAll(items);

  /// Specific implementations which check isImmtable to determine if an
  /// unknown key should be allowed.
  ///
  /// If [isImmutable] is false, or the key already exists,
  /// then allow the edit.
  /// Throw [JsonObjectLiteException] if we're not allowed to add a new
  /// key
  void operator []=(dynamic key, dynamic value) {
    // If the map is not immutable, or it already contains the key, then
    if (this.isImmutable == false || this.containsKey(key)) {
      //allow the edit, as we don't care if it's a new key or not
      return _objectData[key] = value;
    } else {
      throw new JsonObjectLiteException("JsonObject is not extendable");
    }
  }

  /// If [isImmutable] is false, or the key already exists,
  /// then allow the edit.
  /// Throw [JsonObjectLiteException] if we're not allowed to add a new
  /// key
  void putIfAbsent(dynamic key, ifAbsent()) {
    if (this.isImmutable == false || this.containsKey(key)) {
      return _objectData.putIfAbsent(key, ifAbsent);
    } else {
      throw new JsonObjectLiteException("JsonObject is not extendable");
    }
  }

  /// If [isImmutable] is false, or the key already exists,
  /// then allow the removal.
  /// Throw [JsonObjectLiteException] if we're not allowed to remove a
  /// key
  dynamic remove(dynamic key) {
    if (this.isImmutable == false || this.containsKey(key)) {
      return _objectData.remove(key);
    } else {
      throw new JsonObjectLiteException("JsonObject is not extendable");
    }
  }

  /// If [isImmutable] is false, then allow the map to be cleared
  /// Throw [JsonObjectLiteException] if we're not allowed to clear.
  void clear() {
    if (this.isImmutable == false) {
      _objectData.clear();
    } else {
      throw new JsonObjectLiteException("JsonObject is not extendable");
    }
  }
}

/// Exception class thrown by JsonObjectLite
class JsonObjectLiteException implements Exception {
  const JsonObjectLiteException([String message]) : this._message = message;
  String toString() => (this._message != null
      ? "JsonObjectException: $_message"
      : "JsonObjectException");
  final String _message;
}
