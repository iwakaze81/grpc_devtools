import 'package:flutter/foundation.dart';

enum RpcCallType { unary, streaming }

enum RpcMessageDirection { request, response }

@immutable
class RpcCall {
  final String id;
  final String method;
  final RpcCallType type;
  final DateTime startTime;
  final DateTime? endTime;
  final int? grpcStatusCode;
  final String? grpcStatusMessage;
  final Map<String, String>? requestMetadata;
  final Map<String, String>? responseHeaders;
  final Map<String, String>? trailerMetadata;
  final String? requestDecoded;
  final String? responseDecoded;

  const RpcCall({
    required this.id,
    required this.method,
    required this.type,
    required this.startTime,
    this.endTime,
    this.grpcStatusCode,
    this.grpcStatusMessage,
    this.requestMetadata,
    this.responseHeaders,
    this.trailerMetadata,
    this.requestDecoded,
    this.responseDecoded,
  });

  Duration? get duration => endTime?.difference(startTime);

  bool get isCompleted => endTime != null;

  bool get isOk => grpcStatusCode == 0;

  RpcCall copyWith({
    DateTime? endTime,
    int? grpcStatusCode,
    String? grpcStatusMessage,
    Map<String, String>? requestMetadata,
    Map<String, String>? responseHeaders,
    Map<String, String>? trailerMetadata,
    String? requestDecoded,
    String? responseDecoded,
  }) =>
      RpcCall(
        id: id,
        method: method,
        type: type,
        startTime: startTime,
        endTime: endTime ?? this.endTime,
        grpcStatusCode: grpcStatusCode ?? this.grpcStatusCode,
        grpcStatusMessage: grpcStatusMessage ?? this.grpcStatusMessage,
        requestMetadata: requestMetadata ?? this.requestMetadata,
        responseHeaders: responseHeaders ?? this.responseHeaders,
        trailerMetadata: trailerMetadata ?? this.trailerMetadata,
        requestDecoded: requestDecoded ?? this.requestDecoded,
        responseDecoded: responseDecoded ?? this.responseDecoded,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method,
        'type': type.name,
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': endTime?.millisecondsSinceEpoch,
        'grpcStatusCode': grpcStatusCode,
        'grpcStatusMessage': grpcStatusMessage,
        'requestMetadata': requestMetadata,
        'responseHeaders': responseHeaders,
        'trailerMetadata': trailerMetadata,
        'requestDecoded': requestDecoded,
        'responseDecoded': responseDecoded,
      };
}
