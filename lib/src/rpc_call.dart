import 'dart:convert';

enum RpcCallType { unary, streaming }

enum RpcMessageDirection { request, response }

class RpcMessage {
  final String callId;
  final RpcMessageDirection direction;
  final DateTime timestamp;
  final Map<String, dynamic>? decoded;

  const RpcMessage({
    required this.callId,
    required this.direction,
    required this.timestamp,
    this.decoded,
  });

  Map<String, dynamic> toJson() => {
        'callId': callId,
        'direction': direction.name,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'decoded': decoded != null ? jsonEncode(decoded) : null,
      };
}

class RpcCall {
  final String id;
  final String method;
  final RpcCallType type;
  final DateTime startTime;
  DateTime? endTime;
  int? grpcStatusCode;
  String? grpcStatusMessage;
  Map<String, String>? requestMetadata;
  Map<String, String>? responseHeaders;
  Map<String, String>? trailerMetadata;
  String? requestDecoded;
  String? responseDecoded;

  RpcCall({
    required this.id,
    required this.method,
    required this.type,
    required this.startTime,
    this.requestMetadata,
  });

  Duration? get duration => endTime?.difference(startTime);

  bool get isCompleted => endTime != null;

  bool get isOk => grpcStatusCode == 0;

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
