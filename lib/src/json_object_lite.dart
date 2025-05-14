// ignore_for_file: avoid-global-state

/*
 * Package : JsonObjectLite
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/09/2017
 * Copyright :  S.Hamblett
 * Based on json_object (C) 2013 Chris Buckett (chrisbuckett@gmail.com)
 */

// ignore_for_file: avoid_positional_boolean_parameters
// ignore_for_file: public_member_api_docs
part of '../json_object_lite.dart';

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
class JsonObjectLite<E> implements Map<dynamic, dynamic> {
  /// JSON encoder, use our encoder not the one from convert
  static const JsonEncoderLite encoder = JsonEncoderLite();

  /// JSON decoder
  static const JsonDecoder decoder = JsonDecoder();

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
  /// Set to true by default when a JsonObjectLite is created
  /// with [JsonObjectLite.fromJsonString()] or [JsonObjectLite.fromMap()].
  /// The default constructor [JsonObjectLite()], sets this value to
  /// false so properties can be added.
  bool? isImmutable;

  // Contains either a [List] or [Map]
  dynamic _objectData;

  E get first => toIterable()!.first;

  Iterator<E> get iterator => toIterable()!.iterator as Iterator<E>;

  E get last => toIterable()!.last;

  E get single => toIterable()!.single;

  // Pass through to the inner _objectData map.
  @override
  Iterable<dynamic> get keys => _objectData.keys;

  // Pass through to the inner _objectData map.
  @override
  Iterable<dynamic> get values => _objectData.values;

  // Pass through to the inner _objectData map.
  @override
  int get length => _objectData.length;

  // Pass through to the inner _objectData map.
  @override
  bool get isEmpty => _objectData.isEmpty;

  // Pass through to the inner _objectData map.
  @override
  bool get isNotEmpty => _objectData.isNotEmpty;

  /// Default constructor.
  /// Creates a new empty map.
  JsonObjectLite() {
    _objectData = <dynamic, dynamic>{};
    isImmutable = false;
  }

  /// Eager constructor parses [jsonString] using [JsonDecoder].
  ///
  /// If [t] is given, will replace [t]'s contents from the
  /// string and return [t].
  ///
  /// If [recursive] is true, replaces all maps recursively with JsonObjects.
  /// The default value is true.
  /// The object is set to immutable, the user must reset this
  /// to add more properties.
  factory JsonObjectLite.fromJsonString(
    String jsonString, [
    JsonObjectLite<dynamic>? t,
    bool recursive = true,
  ]) {
    t ??= JsonObjectLite<dynamic>();
    t._objectData = decoder.convert(jsonString);
    if (recursive) {
      t._extractElements(t._objectData);
    }
    t.isImmutable = true;
    return t as JsonObjectLite<E>;
  }

  /// Private fromMap constructor.
  /// The object is set to immutable, the user must reset this
  /// to add more properties.
  factory JsonObjectLite._fromMap(
    Map<dynamic, dynamic> map, [
    JsonObjectLite<dynamic>? t,
    bool recursive = true,
  ]) {
    t ??= JsonObjectLite<dynamic>();
    t._objectData = map;
    if (recursive) {
      t._extractElements(t._objectData);
    }
    t.isImmutable = true;
    return t as JsonObjectLite<E>;
  }

  /// Typed JsonObjectLite
  static JsonObjectLite<dynamic> toTypedJsonObjectLite(
    JsonObjectLite<dynamic> src,
    JsonObjectLite<dynamic> dest,
  ) {
    dest._objectData = src._objectData;
    if (src.isImmutable!) {
      dest.isImmutable = true;
    }
    return dest;
  }

  /// Returns a string representation of the underlying object data
  @override
  String toString() => encoder.convert(_objectData);

  /// Returns either the underlying parsed data as an iterable list (if the
  /// underlying data contains a list), or returns the map.values (if the
  /// underlying data contains a map).
  Iterable<dynamic>? toIterable() {
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
  @override
  dynamic noSuchMethod(Invocation mirror) {
    int positionalArgs = 0;
    positionalArgs = mirror.positionalArguments.length;
    String property = 'Not Found';

    if (mirror.isGetter && (positionalArgs == 0)) {
      // Synthetic getter
      property = _symbolToString(mirror.memberName);
      if (containsKey(property)) {
        return this[property];
      }
    } else if (mirror.isSetter && positionalArgs == 1) {
      // Synthetic setter
      // If the property doesn't exist, it will only be added
      // if isImmutable = false
      property = _symbolToString(mirror.memberName, true);
      if (!isImmutable!) {
        this[property] = mirror.positionalArguments.first;
      }
      return this[property];
    }

    // If we get here, then we've not found it - throw.
    _log('noSuchMethod:: Not found: $property');
    _log('noSuchMethod:: IsGetter: ${mirror.isGetter}');
    _log('noSuchMethod:: IsSetter: ${mirror.isGetter}');
    _log('noSuchMethod:: isAccessor: ${mirror.isAccessor}');
    return super.noSuchMethod(mirror);
  }

  ///
  /// Iterable implementation methods and properties
  ///

  bool any(bool Function(dynamic element) f) => toIterable()!.any(f);

  bool contains(dynamic element) => toIterable()!.contains(element);

  E elementAt(int index) => toIterable()!.elementAt(index);

  bool every(bool Function(dynamic element) f) => toIterable()!.every(f);

  Iterable<T> expand<T>(dynamic Function(dynamic element) f) =>
      toIterable()!.expand(f as Iterable<T> Function(dynamic));

  dynamic firstWhere(bool Function(dynamic value) test, {dynamic orElse}) =>
      toIterable()!.firstWhere(test, orElse: orElse);

  T fold<T>(T initialValue, T Function(T a, dynamic b) combine) =>
      toIterable()!.fold(initialValue, combine);

  String join([String separator = '']) => toIterable()!.join(separator);

  dynamic lastWhere(bool Function(dynamic value) test, {dynamic orElse}) =>
      toIterable()!.firstWhere(test, orElse: orElse);

  dynamic reduce(dynamic Function(dynamic value, dynamic element) combine) =>
      toIterable()!.reduce(combine);

  dynamic singleWhere(bool Function(dynamic value) test, {dynamic orElse}) =>
      toIterable()!.firstWhere(test, orElse: orElse);

  Iterable<E> skip(int n) => toIterable()!.skip(n) as Iterable<E>;

  Iterable<E> take(int n) => toIterable()!.take(n) as Iterable<E>;

  List<dynamic> toList({bool growable = true}) =>
      toIterable()!.toList(growable: growable);

  Set<dynamic> toSet() => toIterable()!.toSet();

  Iterable<E> where(bool Function(dynamic element) f) =>
      toIterable()!.where(f) as Iterable<E>;

  ///
  /// Map implementation methods and properties *
  ///

  // Pass through to the inner _objectData map.
  @override
  bool containsValue(dynamic value) => _objectData.containsValue(value);

  // Pass through to the inner _objectData map.
  @override
  bool containsKey(dynamic value) =>
      _objectData.containsKey(_symbolToString(value));

  // Pass through to the inner _objectData map.
  @override
  dynamic operator [](dynamic key) => _objectData[key];

  // Pass through to the inner _objectData map.
  @override
  void forEach(void Function(dynamic key, dynamic value) func) {
    _objectData.forEach(func);
  }

  // Pass through to the inner _objectData map.
  @override
  void addAll(dynamic items) => _objectData.addAll(items);

  /// Specific implementations which check isImmtable to determine if an
  /// unknown key should be allowed.
  ///
  /// If [isImmutable] is false, or the key already exists,
  /// then allow the edit.
  /// Throw [JsonObjectLiteException] if we're not allowed to add a new
  /// key
  @override
  void operator []=(dynamic key, dynamic value) {
    // If the map is not immutable, or it already contains the key, then
    if (isImmutable == false || containsKey(key)) {
      //allow the edit, as we don't care if it's a new key or not
      _objectData[key] = value;
    } else {
      throw const JsonObjectLiteException('JsonObject is not extendable');
    }
  }

  /// If [isImmutable] is false, or the key already exists,
  /// then allow the edit.
  /// Throw [JsonObjectLiteException] if we're not allowed to add a new
  /// key
  @override
  void putIfAbsent(dynamic key, Function() ifAbsent) {
    if (isImmutable == false || containsKey(key)) {
      _objectData.putIfAbsent(key, ifAbsent);
    } else {
      throw const JsonObjectLiteException('JsonObject is not extendable');
    }
  }

  /// If [isImmutable] is false, or the key already exists,
  /// then allow the removal.
  /// Throw [JsonObjectLiteException] if we're not allowed to remove a
  /// key
  @override
  dynamic remove(dynamic key) {
    if (isImmutable == false || containsKey(key)) {
      return _objectData.remove(key);
    } else {
      throw const JsonObjectLiteException('JsonObject is not extendable');
    }
  }

  /// If [isImmutable] is false, then allow the map to be cleared
  /// Throw [JsonObjectLiteException] if we're not allowed to clear.
  @override
  void clear() {
    if (isImmutable == false) {
      _objectData.clear();
    } else {
      throw const JsonObjectLiteException('JsonObject is not extendable');
    }
  }

  // If the object passed in is a MAP, then we iterate through each of
  // the values of the map, and if any value is a map, then we create a new
  // [JsonObjectLite] replacing that map in the original data with
  // that [JsonObjectLite] to a new [JsonObjectLite].
  // If the value is a Collection, then we call this function recursively.
  //
  // If the object passed in is a Collection, then we iterate through
  // each item.  If that item is a map, then we replace the item with a
  // [JsonObjectLite] created from the map.  If the item is a
  // Collection, then we call this function recursively.
  //
  void _extractElements(dynamic data) {
    if (data is Map) {
      // Iterate through each of the k,v pairs, replacing maps with jsonObjects
      data.forEach((dynamic key, dynamic value) {
        if (value is Map) {
          // Replace the existing Map with a JsonObjectLite
          data[key] = JsonObjectLite<dynamic>._fromMap(value);
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
        final dynamic listItem = data[i];
        if (listItem is List) {
          // Recurse
          _extractElements(listItem);
        } else if (listItem is Map) {
          // Replace the existing Map with a JsonObject
          data[i] = JsonObjectLite<dynamic>._fromMap(listItem);
        }
      }
    }
  }

  // Convert the incoming method name(symbol) into a string,
  // without using mirrors.
  String _symbolToString(dynamic value, [bool isSetter = false]) {
    String ret;
    if (value is Symbol) {
      // Brittle but we avoid mirrors
      final String name = value.toString();
      ret =
          '${name.characters.getRange(name.indexOf('"') + 1, name.lastIndexOf('"'))}';
      // Setters have an '=' on the end, remove it
      if (isSetter) {
        ret = ret.replaceFirst('=', '', ret.length - 1);
      }
    } else {
      ret = value.toString();
    }
    _log('_symbolToString:: Method name is: $ret');
    return ret;
  }
}

/// Exception class thrown by JsonObjectLite
class JsonObjectLiteException implements Exception {
  final String? _message;

  const JsonObjectLiteException([String? message]) : _message = message;
  @override
  String toString() =>
      _message != null
          ? 'JsonObjectException: $_message'
          : 'JsonObjectException';
}
