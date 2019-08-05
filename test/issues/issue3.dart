/*
 * Packge : json_object_lite
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/09/2017
 * Copyright :  S.Hamblett
 */

import 'package:json_object_lite/json_object_lite.dart';
import 'package:test/test.dart';

void main() {
  test('Issue 3', () {
    final dynamic obj = JsonObjectLite<dynamic>();
    obj.foo = JsonObjectLite<dynamic>.fromJsonString('[1,2,3]');
    print(obj);
  });

  test('Issue 3 fix 1', () {
    final JsonObjectLite<dynamic> obj = JsonObjectLite<dynamic>.fromJsonString('{"foo":[1,2,3]}');
    print(obj);
  });
}