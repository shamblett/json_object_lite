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
    test("Default constructor", ()
    {
      final JsonObjectLite jsonObject = new JsonObjectLite();
      expect(jsonObject.isImmutable, true);
    });
  });
}