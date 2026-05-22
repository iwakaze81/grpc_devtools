import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:grpc/grpc.dart';

import 'package:grpc_devtools/src/proto_decoder.dart';
import 'package:grpc_devtools/src/rpc_call.dart';

// Event kinds posted to dart:developer
const String kCallStarted = 'ext.grpc_devtools.call_started';
const String kCallMessage = 'ext.grpc_devtools.call_message';
const String kCallHeaders = 'ext.grpc_devtools.call_headers';
const String kCallEnded = 'ext.grpc_devtools.call_ended';

class GrpcDevToolsEventBus {
  final _random = Random.secure();

  String generateCallId() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final rand = _random.nextInt(0xFFFFFF);
    return '${ts.toRadixString(16)}-${rand.toRadixString(16)}';
  }

  void emitCallStarted({
    required String callId,
    required String method,
    required RpcCallType type,
    required Object? request,
    required Map<String, String> metadata,
  }) {
    if (kReleaseMode) {
      return;
    }
    developer.postEvent(kCallStarted, {
      'callId': callId,
      'method': method,
      'type': type.name,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'request': ProtoDecoder.toReadableString(request),
      'metadata': jsonEncode(metadata),
    });
  }

  void emitCallMessage({
    required String callId,
    required RpcMessageDirection direction,
    required Object? message,
  }) {
    if (kReleaseMode) {
      return;
    }
    developer.postEvent(kCallMessage, {
      'callId': callId,
      'direction': direction.name,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': ProtoDecoder.toReadableString(message),
    });
  }

  void emitCallHeaders({
    required String callId,
    required Map<String, String> headers,
  }) {
    if (kReleaseMode) {
      return;
    }
    developer.postEvent(kCallHeaders, {
      'callId': callId,
      'headers': jsonEncode(headers),
    });
  }

  void emitCallEnded({
    required String callId,
    required DateTime startTime,
    Object? response,
    Object? error,
    Map<String, String>? trailers,
  }) {
    if (kReleaseMode) {
      return;
    }

    int statusCode;
    String statusMessage;

    if (error is GrpcError) {
      statusCode = error.code;
      statusMessage = error.message ?? '';
    } else if (error != null) {
      statusCode = StatusCode.unknown;
      statusMessage = error.toString();
    } else {
      statusCode = StatusCode.ok;
      statusMessage = 'OK';
    }

    developer.postEvent(kCallEnded, {
      'callId': callId,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': DateTime.now().millisecondsSinceEpoch,
      'statusCode': statusCode,
      'statusMessage': statusMessage,
      'response': ProtoDecoder.toReadableString(response),
      'trailers': jsonEncode(trailers ?? const {}),
    });
  }
}
