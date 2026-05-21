import 'dart:convert';

import 'package:protobuf/protobuf.dart';

abstract final class ProtoDecoder {
  static Map<String, dynamic>? tryDecode(Object? message) {
    if (message is! GeneratedMessage) {
      return null;
    }
    try {
      final json = message.toProto3Json();
      if (json is Map) {
        return json.cast<String, dynamic>();
      }
      return {'value': json};
    } catch (_) {
      return null;
    }
  }

  static String toReadableString(Object? message) {
    if (message is GeneratedMessage) {
      try {
        return const JsonEncoder.withIndent('  ').convert(message.toProto3Json());
      } catch (_) {
        return message.toString();
      }
    }
    return message?.toString() ?? '';
  }
}
