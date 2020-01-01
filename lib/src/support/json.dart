/*
 * Package : JsonObjectLite
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/09/2017
 * Copyright :  S.Hamblett
 * Based on json_object (C) 2013 Chris Buckett (chrisbuckett@gmail.com)
 */

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of json_object_lite;

// ignore_for_file: omit_local_variable_types
// ignore_for_file: unnecessary_final
// ignore_for_file: cascade_invocations
// ignore_for_file: avoid_print
// ignore_for_file: avoid_annotating_with_dynamic
// ignore_for_file: prefer_mixin

/// Error thrown by JSON serialization if an object cannot be serialized.
///
/// The [unsupportedObject] field holds that object that failed
/// to be serialized.
///
/// If an object isn't directly serializable, the serializer calls the `toJson`
/// method on the object. If that call fails, the error will be stored in the
/// [cause] field. If the call returns an object that isn't directly
/// serializable, the [cause] is null.
class JsonUnsupportedObjectError extends Error {
  /// Default
  JsonUnsupportedObjectError(this.unsupportedObject,
      {this.cause, this.partialResult});

  /// The object that could not be serialized.
  final Object unsupportedObject;

  /// The exception thrown when trying to convert the object.
  final Object cause;

  /// The partial result of the conversion, up until the error happened.
  ///
  /// May be null.
  final String partialResult;

  @override
  String toString() {
    final String safeString = Error.safeToString(unsupportedObject);
    String prefix;
    if (cause != null) {
      prefix = 'Converting object to an encodable object failed:';
    } else {
      prefix = 'Converting object did not return an encodable object:';
    }
    return '$prefix $safeString';
  }
}

/// Reports that an object could not be stringified due to cyclic references.
/// When the cycle is detected, a [JsonCyclicError] is thrown.
class JsonCyclicError extends JsonUnsupportedObjectError {
  /// The first object that was detected as part of a cycle.
  JsonCyclicError(Object object) : super(object);
  @override
  String toString() => 'Cyclic error in JSON stringify';
}

/// This class converts JSON objects to strings.
class JsonEncoderLite {
  /// Creates a JSON encoder.
  ///
  /// The JSON encoder handles numbers, strings, booleans, null, lists and
  /// maps with string keys directly.
  ///
  /// Any other object is attempted converted by [toEncodable] to an
  /// object that is of one of the convertible types.
  ///
  /// If [toEncodable] is omitted, it defaults to calling `.toJson()` on
  /// the object.
  const JsonEncoderLite([Function(dynamic object) toEncodable])
      : indent = null,
        _toEncodable = toEncodable;

  /// Creates a JSON encoder that creates multi-line JSON.
  ///
  /// The encoding of elements of lists and maps are indented and
  /// put on separate lines. The [indent] string is prepended to these
  /// elements, once for each level of indentation.
  ///
  /// If [indent] is `null`, the output is encoded as a single line.
  ///
  /// The JSON encoder handles numbers, strings, booleans, null, lists and
  /// maps with string keys directly.
  ///
  /// Any other object is attempted converted by [toEncodable] to an
  /// object that is of one of the convertible types.
  ///
  /// If [toEncodable] is omitted, it defaults to calling `.toJson()` on
  /// the object.
  const JsonEncoderLite.withIndent(this.indent,
      [Function(dynamic object) toEncodable])
      : _toEncodable = toEncodable;

  /// The string used for indention.
  ///
  /// When generating multi-line output, this string is inserted once at the
  /// beginning of each indented line for each level of indentation.
  ///
  /// If `null`, the output is encoded as a single line.
  final String indent;

  /// Function called on non-encodable objects to return a replacement
  /// encodable object that will be encoded in the orignal's place.
  final Function(dynamic) _toEncodable;

  /// Converts [object] to a JSON [String].
  ///
  /// Directly serializable values are [num], [String], [bool], and [Null], as
  /// well as some [List] and [Map] values. For [List], the elements must all be
  /// serializable. For [Map], the keys must be [String] and the values must be
  /// serializable.
  ///
  /// If a value of any other type is attempted to be serialized, the
  /// `toEncodable` function provided in the constructor is called
  /// with the value as argument.
  /// The result, which must be a directly serializable value, is
  /// serialized instead of the original value.
  ///
  /// If the conversion throws, or returns a value that is not directly
  /// serializable, a [JsonUnsupportedObjectError] exception is thrown.
  /// If the call throws, the error is caught and stored in the
  /// [JsonUnsupportedObjectError]'s [:cause:] field.
  ///
  /// If a [List] or [Map] contains a reference to itself, directly or through
  /// other lists or maps, it cannot be serialized and a [JsonCyclicError] is
  /// thrown.
  ///
  /// [object] should not change during serialization.
  ///
  /// If an object is serialized more than once, [convert] may cache the text
  /// for it. In other words, if the content of an object changes after it is
  /// first serialized, the new values may not be reflected in the result.
  String convert(Object object) =>
      _JsonStringStringifier.stringify(object, _toEncodable, indent);
}

/// Encoder that encodes a single object as a UTF-8 encoded JSON string.
///
/// This encoder works equivalently to first converting the object to
/// a JSON string, and then UTF-8 encoding the string, but without
/// creating an intermediate string.
class JsonUtf8Encoder extends Converter<Object, List<int>> {
  /// Create converter.
  ///
  /// If [indent] is non-`null`, the converter attempts to "pretty-print" the
  /// JSON, and uses `indent` as the indentation. Otherwise the result has no
  /// whitespace outside of string literals.
  /// If `indent` contains characters that are not valid JSON whitespace
  /// characters, the result will not be valid JSON. JSON whitespace characters
  /// are space (U+0020), tab (U+0009), line feed (U+000a) and carriage return
  /// (U+000d).
  ///
  /// The [bufferSize] is the size of the internal buffers used to collect
  /// UTF-8 code units.
  /// If using [startChunkedConversion], it will be the size of the chunks.
  ///
  /// The JSON encoder handles numbers, strings, booleans, null, lists and maps
  /// directly.
  ///
  /// Any other object is attempted converted by [toEncodable] to an object that
  /// is of one of the convertible types.
  ///
  /// If [toEncodable] is omitted, it defaults to calling `.toJson()` on the
  /// object.
  JsonUtf8Encoder(
      [String indent,
      Function(dynamic object) toEncodable,
      int bufferSize = _defaultBufferSize])
      : _indent = _utf8Encode(indent),
        _toEncodable = toEncodable,
        _bufferSize = bufferSize;

  static List<int> _utf8Encode(String string) {
    if (string == null) {
      return null;
    }
    if (string.isEmpty) {
      return Uint8List(0);
    }
    checkAscii:
    {
      for (int i = 0; i < string.length; i++) {
        if (string.codeUnitAt(i) >= 0x80) {
          break checkAscii;
        }
      }
      return string.codeUnits;
    }
    return utf8.encode(string);
  }

  /// Default buffer size used by the JSON-to-UTF-8 encoder.
  static const int _defaultBufferSize = 256;

  /// Indentation used in pretty-print mode, `null` if not pretty.
  final List<int> _indent;

  /// Function called with each un-encodable object encountered.
  final Function(dynamic) _toEncodable;

  /// UTF-8 buffer size.
  final int _bufferSize;

  /// Convert [object] into UTF-8 encoded JSON.
  @override
  List<int> convert(Object object) {
    final List<List<int>> bytes = <List<int>>[];
    // The `stringify` function always converts into chunks.
    // Collect the chunks into the `bytes` list, then combine them afterwards.
    void addChunk(Uint8List chunk, int start, int end) {
      Uint8List chunkTmp;
      if (start > 0 || end < chunk.length) {
        final int length = end - start;
        chunkTmp =
            Uint8List.view(chunk.buffer, chunk.offsetInBytes + start, length);
      }
      bytes.add(chunkTmp);
    }

    _JsonUtf8Stringifier.stringify(
        object, _indent, _toEncodable, _bufferSize, addChunk);
    if (bytes.length == 1) {
      return bytes[0];
    }
    int length = 0;
    for (int i = 0; i < bytes.length; i++) {
      length += bytes[i].length;
    }
    final Uint8List result = Uint8List(length);
    for (int i = 0, offset = 0; i < bytes.length; i++) {
      final Uint8List byteList = bytes[i];
      final int end = offset + byteList.length;
      result.setRange(offset, end, byteList);
      offset = end;
    }
    return result;
  }

  /// Start a chunked conversion.
  ///
  /// Only one object can be passed into the returned sink.
  ///
  /// The argument [sink] will receive byte lists in sizes depending on the
  /// `bufferSize` passed to the constructor when creating this encoder.
  @override
  ChunkedConversionSink<Object> startChunkedConversion(Sink<List<int>> sink) {
    ByteConversionSink byteSink;
    if (sink is ByteConversionSink) {
      byteSink = sink;
    } else {
      byteSink = ByteConversionSink.from(sink);
    }
    return _JsonUtf8EncoderSink(byteSink, _toEncodable, _indent, _bufferSize);
  }

  // Override the base class's bind, to provide a better type.
  @override
  Stream<List<int>> bind(Stream<Object> stream) => super.bind(stream);
}

/// Sink returned when starting a chunked conversion from object to bytes.
class _JsonUtf8EncoderSink extends ChunkedConversionSink<Object> {
  _JsonUtf8EncoderSink(
      this._sink, this._toEncodable, this._indent, this._bufferSize);

  /// The byte sink receiving the encoded chunks.
  final ByteConversionSink _sink;
  final List<int> _indent;
  final Function(dynamic) _toEncodable;
  final int _bufferSize;
  bool _isDone = false;

  /// Callback called for each slice of result bytes.
  void _addChunk(Uint8List chunk, int start, int end) {
    _sink.addSlice(chunk, start, end, false);
  }

  @override
  void add(Object object) {
    if (_isDone) {
      throw StateError('Only one call to add allowed');
    }
    _isDone = true;
    _JsonUtf8Stringifier.stringify(
        object, _indent, _toEncodable, _bufferSize, _addChunk);
    _sink.close();
  }

  @override
  void close() {
    if (!_isDone) {
      _isDone = true;
      _sink.close();
    }
  }
}

/// JSON encoder that traverses an object structure and writes JSON source.
///
/// This is an abstract implementation that doesn't decide on the output
/// format, but writes the JSON through abstract methods like [writeString].
abstract class _JsonStringifier {
  _JsonStringifier(Function(dynamic o) toEncodable)
      : _toEncodable = toEncodable;

  // Character code constants.
  static const int backspace = 0x08;
  static const int tab = 0x09;
  static const int newline = 0x0a;
  static const int carriageReturn = 0x0d;
  static const int formFeed = 0x0c;
  static const int quote = 0x22;
  static const int char0 = 0x30;
  static const int backslash = 0x5c;
  static const int charB = 0x62;
  static const int charF = 0x66;
  static const int charN = 0x6e;
  static const int charR = 0x72;
  static const int charT = 0x74;
  static const int charU = 0x75;
  static const String _typeMarker = 'JsonObjectLite';

  /// List of objects currently being traversed. Used to detect cycles.
  final List<Object> _seen = <Object>[];

  /// Function called for each un-encodable object encountered.
  final Function(dynamic) _toEncodable;

  String get _partialResult;

  /// Append a string to the JSON output.
  void writeString(String characters);

  /// Append part of a string to the JSON output.
  void writeStringSlice(String characters, int start, int end);

  /// Append a single character, given by its code point, to the JSON output.
  void writeCharCode(int charCode);

  /// Write a number to the JSON output.
  void writeNumber(num number);

  // ('0' + x) or ('a' + x - 10)
  static int hexDigit(int x) => x < 10 ? 48 + x : 87 + x;

  /// Write, and suitably escape, a string's content as a JSON string literal.
  void writeStringContent(String s) {
    int offset = 0;
    final int length = s.length;
    for (int i = 0; i < length; i++) {
      final int charCode = s.codeUnitAt(i);
      if (charCode > backslash) {
        continue;
      }
      if (charCode < 32) {
        if (i > offset) {
          writeStringSlice(s, offset, i);
        }
        offset = i + 1;
        writeCharCode(backslash);
        switch (charCode) {
          case backspace:
            writeCharCode(charB);
            break;
          case tab:
            writeCharCode(charT);
            break;
          case newline:
            writeCharCode(charN);
            break;
          case formFeed:
            writeCharCode(charF);
            break;
          case carriageReturn:
            writeCharCode(charR);
            break;
          default:
            writeCharCode(charU);
            writeCharCode(char0);
            writeCharCode(char0);
            writeCharCode(hexDigit((charCode >> 4) & 0xf));
            writeCharCode(hexDigit(charCode & 0xf));
            break;
        }
      } else if (charCode == quote || charCode == backslash) {
        if (i > offset) {
          writeStringSlice(s, offset, i);
        }
        offset = i + 1;
        writeCharCode(backslash);
        writeCharCode(charCode);
      }
    }
    if (offset == 0) {
      writeString(s);
    } else if (offset < length) {
      writeStringSlice(s, offset, length);
    }
  }

  /// Check if an encountered object is already being traversed.
  ///
  /// Records the object if it isn't already seen. Should have a
  /// matching call to [_removeSeen] when the object is no longer
  /// being traversed.
  void _checkCycle(Object object) {
    for (int i = 0; i < _seen.length; i++) {
      if (identical(object, _seen[i])) {
        throw JsonCyclicError(object);
      }
    }
    _seen.add(object);
  }

  /// Remove [object] from the list of currently traversed objects.
  ///
  /// Should be called in the opposite order of the matching [_checkCycle]
  /// calls.
  void _removeSeen(Object object) {
    assert(_seen.isNotEmpty, 'seem must not be empty');
    assert(identical(_seen.last, object),
        'seen.last must be identical to the passed in object');
    _seen.removeLast();
  }

  /// Write an object.
  ///
  /// If [object] isn't directly encodable, the [_toEncodable] function gets one
  /// chance to return a replacement which is encodable.
  void writeObject(Object object) {
    // Tries stringifying object directly. If it's not a simple value, List or
    // Map, call toJson() to get a custom representation and try serializing
    // that.
    if (writeJsonValue(object)) {
      return;
    }
    _checkCycle(object);
    try {
      final dynamic customJson = _toEncodable(object);
      if (!writeJsonValue(customJson)) {
        throw JsonUnsupportedObjectError(object, partialResult: _partialResult);
      }
      _removeSeen(object);
    } on Exception catch (e) {
      throw JsonUnsupportedObjectError(object,
          cause: e, partialResult: _partialResult);
    }
  }

  /// Serialize a [num], [String], [bool], [Null], [List] or [Map] value.
  ///
  /// Returns true if the value is one of these types, and false if not.
  /// If a value is both a [List] and a [Map], it's serialized as a [List].
  bool writeJsonValue(Object object) {
    // Check for json object lite type, we must process this differently
    // as the 'is' operator returns this as a Map type
    bool isMap = false;
    bool isList = false;
    bool isLite = false;
    JsonObjectLite<dynamic> liteObject;
    if (object.runtimeType.toString().contains(_typeMarker)) {
      liteObject = object;
      isLite = true;
      if (liteObject._objectData is Map) {
        isMap = true;
      } else if (liteObject._objectData is List) {
        isList = true;
      }
    } else {
      if (object is Map) {
        isMap = true;
      } else if (object is List) {
        isList = true;
      }
    }
    if (object is num) {
      if (!object.isFinite) {
        return false;
      }
      writeNumber(object);
      return true;
    } else if (identical(object, true)) {
      writeString('true');
      return true;
    } else if (identical(object, false)) {
      writeString('false');
      return true;
    } else if (object == null) {
      writeString('null');
      return true;
    } else if (object is String) {
      writeString('"');
      writeStringContent(object);
      writeString('"');
      return true;
    } else if (isList) {
      _checkCycle(object);
      if (isLite) {
        writeList(liteObject._objectData);
      } else {
        writeList(object);
      }
      _removeSeen(object);
      return true;
    } else if (isMap) {
      _checkCycle(object);
      bool success = false;
      if (isLite) {
        // writeMap can fail if keys are not all strings.
        success = writeMap(liteObject._objectData);
      } else {
        success = writeMap(object);
      }
      _removeSeen(object);
      return success;
    } else {
      return false;
    }
  }

  /// Serialize a [List].
  void writeList(List<dynamic> list) {
    writeString('[');
    if (list.isNotEmpty) {
      writeObject(list[0]);
      for (int i = 1; i < list.length; i++) {
        writeString(',');
        writeObject(list[i]);
      }
    }
    writeString(']');
  }

  /// Serialize a [Map].
  bool writeMap(Map<dynamic, dynamic> map) {
    if (map.isEmpty) {
      writeString('{}');
      return true;
    }
    final List<dynamic> keyValueList = List<dynamic>(map.length * 2);
    int i = 0;
    bool allStringKeys = true;
    map.forEach((dynamic key, dynamic value) {
      if (key is! String) {
        allStringKeys = false;
      }
      keyValueList[i++] = key;
      keyValueList[i++] = value;
    });
    if (!allStringKeys) {
      return false;
    }
    writeString('{');
    String separator = '"';
    for (int i = 0; i < keyValueList.length; i += 2) {
      writeString(separator);
      separator = ',"';
      writeStringContent(keyValueList[i]);
      writeString('":');
      writeObject(keyValueList[i + 1]);
    }
    writeString('}');
    return true;
  }
}

/// A modification of [_JsonStringifier] which indents the
/// contents of [List] and [Map] objects using the specified indent value.
///
/// Subclasses should implement [writeIndentation].
abstract class _JsonPrettyPrintMixin implements _JsonStringifier {
  int _indentLevel = 0;

  /// Add [indentLevel] indentations to the JSON output.
  void writeIndentation(int indentLevel);

  @override
  void writeList(List<dynamic> list) {
    if (list.isEmpty) {
      writeString('[]');
    } else {
      writeString('[\n');
      _indentLevel++;
      writeIndentation(_indentLevel);
      writeObject(list[0]);
      for (int i = 1; i < list.length; i++) {
        writeString(',\n');
        writeIndentation(_indentLevel);
        writeObject(list[i]);
      }
      writeString('\n');
      _indentLevel--;
      writeIndentation(_indentLevel);
      writeString(']');
    }
  }

  @override
  bool writeMap(Map<dynamic, dynamic> map) {
    if (map.isEmpty) {
      writeString('{}');
      return true;
    }
    final List<dynamic> keyValueList = List<dynamic>(map.length * 2);
    int i = 0;
    bool allStringKeys = true;
    map.forEach((dynamic key, dynamic value) {
      if (key is! String) {
        allStringKeys = false;
      }
      keyValueList[i++] = key;
      keyValueList[i++] = value;
    });
    if (!allStringKeys) {
      return false;
    }
    writeString('{\n');
    _indentLevel++;
    String separator = '';
    for (int i = 0; i < keyValueList.length; i += 2) {
      writeString(separator);
      separator = ',\n';
      writeIndentation(_indentLevel);
      writeString('"');
      writeStringContent(keyValueList[i]);
      writeString('": ');
      writeObject(keyValueList[i + 1]);
    }
    writeString('\n');
    _indentLevel--;
    writeIndentation(_indentLevel);
    writeString('}');
    return true;
  }
}

/// A specialization of [_JsonStringifier] that writes its JSON to a string.
class _JsonStringStringifier extends _JsonStringifier {
  _JsonStringStringifier(this._sink, dynamic Function(dynamic) _toEncodable)
      : super(_toEncodable);

  final StringSink _sink;

  /// Convert object to a string.
  ///
  /// The [toEncodable] function is used to convert non-encodable objects
  /// to encodable ones.
  ///
  /// If [indent] is not `null`, the resulting JSON will be "pretty-printed"
  /// with newlines and indentation. The `indent` string is added as indentation
  /// for each indentation level. It should only contain valid JSON whitespace
  /// characters (space, tab, carriage return or line feed).
  static String stringify(
      Object object, Function(dynamic o) toEncodable, String indent) {
    final StringBuffer output = StringBuffer();
    printOn(object, output, toEncodable, indent);
    return output.toString();
  }

  /// Convert object to a string, and write the result to the [output] sink.
  ///
  /// The result is written piecemally to the sink.
  static void printOn(Object object, StringSink output,
      Function(dynamic o) toEncodable, String indent) {
    _JsonStringifier stringifier;
    if (indent == null) {
      stringifier = _JsonStringStringifier(output, toEncodable);
    } else {
      stringifier = _JsonStringStringifierPretty(output, toEncodable, indent);
    }
    stringifier.writeObject(object);
  }

  @override
  String get _partialResult => _sink is StringBuffer ? _sink.toString() : null;

  @override
  void writeNumber(num number) {
    _sink.write(number.toString());
  }

  @override
  void writeString(String string) {
    _sink.write(string);
  }

  @override
  void writeStringSlice(String string, int start, int end) {
    _sink.write(string.substring(start, end));
  }

  @override
  void writeCharCode(int charCode) {
    _sink.writeCharCode(charCode);
  }
}

class _JsonStringStringifierPretty extends _JsonStringStringifier
    with _JsonPrettyPrintMixin {
  _JsonStringStringifierPretty(
      StringSink sink, Function(dynamic o) toEncodable, this._indent)
      : super(sink, toEncodable);

  final String _indent;

  @override
  void writeIndentation(int count) {
    for (int i = 0; i < count; i++) {
      writeString(_indent);
    }
  }
}

/// Specialization of [_JsonStringifier] that writes the JSON as UTF-8.
///
/// The JSON text is UTF-8 encoded and written to [Uint8List] buffers.
/// The buffers are then passed back to a user provided callback method.
class _JsonUtf8Stringifier extends _JsonStringifier {
  _JsonUtf8Stringifier(
      Function(dynamic o) toEncodable, this.bufferSize, this.addChunk)
      : buffer = Uint8List(bufferSize),
        super(toEncodable);

  final int bufferSize;
  final void Function(Uint8List list, int start, int end) addChunk;
  Uint8List buffer;
  int index = 0;

  /// Convert [object] to UTF-8 encoded JSON.
  ///
  /// Calls [addChunk] with slices of UTF-8 code units.
  /// These will typically have size [bufferSize], but may be shorter.
  /// The buffers are not reused, so the [addChunk] call may keep and reuse the
  /// chunks.
  ///
  /// If [indent] is non-`null`, the result will be "pretty-printed" with extra
  /// newlines and indentation, using [indent] as the indentation.
  static void stringify(
      Object object,
      List<int> indent,
      Function(dynamic o) toEncodable,
      int bufferSize,
      void Function(Uint8List chunk, int start, int end) addChunk) {
    _JsonUtf8Stringifier stringifier;
    if (indent != null) {
      stringifier =
          _JsonUtf8StringifierPretty(toEncodable, indent, bufferSize, addChunk);
    } else {
      stringifier = _JsonUtf8Stringifier(toEncodable, bufferSize, addChunk);
    }
    stringifier.writeObject(object);
    stringifier.flush();
  }

  /// Must be called at the end to push the last chunk to the [addChunk]
  /// callback.
  void flush() {
    if (index > 0) {
      addChunk(buffer, 0, index);
    }
    buffer = null;
    index = 0;
  }

  @override
  String get _partialResult => null;

  @override
  void writeNumber(num number) {
    writeAsciiString(number.toString());
  }

  /// Write a string that is known to not have non-ASCII characters.
  void writeAsciiString(String string) {
    for (int i = 0; i < string.length; i++) {
      final int char = string.codeUnitAt(i);
      assert(char <= 0x7f, 'char must be <= 0x7f');
      writeByte(char);
    }
  }

  @override
  void writeString(String string) {
    writeStringSlice(string, 0, string.length);
  }

  @override
  void writeStringSlice(String string, int start, int end) {
    for (int i = start; i < end; i++) {
      int char = string.codeUnitAt(i);
      if (char <= 0x7f) {
        writeByte(char);
      } else {
        if ((char & 0xFC00) == 0xD800 && i + 1 < end) {
          // Lead surrogate.
          final int nextChar = string.codeUnitAt(i + 1);
          if ((nextChar & 0xFC00) == 0xDC00) {
            // Tail surrogate.
            char = 0x10000 + ((char & 0x3ff) << 10) + (nextChar & 0x3ff);
            writeFourByteCharCode(char);
            i++;
            continue;
          }
        }
        writeMultiByteCharCode(char);
      }
    }
  }

  @override
  void writeCharCode(int charCode) {
    if (charCode <= 0x7f) {
      writeByte(charCode);
      return;
    }
    writeMultiByteCharCode(charCode);
  }

  void writeMultiByteCharCode(int charCode) {
    if (charCode <= 0x7ff) {
      writeByte(0xC0 | (charCode >> 6));
      writeByte(0x80 | (charCode & 0x3f));
      return;
    }
    if (charCode <= 0xffff) {
      writeByte(0xE0 | (charCode >> 12));
      writeByte(0x80 | ((charCode >> 6) & 0x3f));
      writeByte(0x80 | (charCode & 0x3f));
      return;
    }
    writeFourByteCharCode(charCode);
  }

  void writeFourByteCharCode(int charCode) {
    assert(charCode <= 0x10ffff, 'char code must be <= 0x10ffff');
    writeByte(0xF0 | (charCode >> 18));
    writeByte(0x80 | ((charCode >> 12) & 0x3f));
    writeByte(0x80 | ((charCode >> 6) & 0x3f));
    writeByte(0x80 | (charCode & 0x3f));
  }

  void writeByte(int byte) {
    assert(byte <= 0xff, 'byte must be <= 0xff');
    if (index == buffer.length) {
      addChunk(buffer, 0, index);
      buffer = Uint8List(bufferSize);
      index = 0;
    }
    buffer[index++] = byte;
  }
}

/// Pretty-printing version of [_JsonUtf8Stringifier].
class _JsonUtf8StringifierPretty extends _JsonUtf8Stringifier
    // ignore: prefer_mixin
    with
        _JsonPrettyPrintMixin {
  _JsonUtf8StringifierPretty(
      Function(dynamic o) toEncodable,
      this.indent,
      int bufferSize,
      void Function(Uint8List buffer, int start, int end) addChunk)
      : super(toEncodable, bufferSize, addChunk);

  final List<int> indent;

  @override
  void writeIndentation(int countParam) {
    int count = countParam;
    final List<int> indent = this.indent;
    final int indentLength = indent.length;
    if (indentLength == 1) {
      final int char = indent[0];
      while (count > 0) {
        writeByte(char);
        count -= 1;
      }
      return;
    }
    while (count > 0) {
      count--;
      final int end = index + indentLength;
      if (end <= buffer.length) {
        buffer.setRange(index, end, indent);
        index = end;
      } else {
        for (int i = 0; i < indentLength; i++) {
          writeByte(indent[i]);
        }
      }
    }
  }
}
