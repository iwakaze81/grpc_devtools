class RpcStreamMessage {
  final String direction;
  final DateTime timestamp;
  final String data;

  const RpcStreamMessage({
    required this.direction,
    required this.timestamp,
    required this.data,
  });
}

class RpcCallModel {
  final String id;
  final String method;
  final String type;
  final DateTime startTime;

  DateTime? endTime;
  int? grpcStatusCode;
  String? grpcStatusMessage;
  Map<String, String>? requestMetadata;
  Map<String, String>? responseHeaders;
  Map<String, String>? trailerMetadata;
  String? requestDecoded;
  String? responseDecoded;
  final List<RpcStreamMessage> messages = [];

  RpcCallModel({
    required this.id,
    required this.method,
    required this.type,
    required this.startTime,
    this.requestMetadata,
    this.requestDecoded,
  });

  Duration? get duration => endTime?.difference(startTime);

  bool get isCompleted => endTime != null;

  bool get isOk => grpcStatusCode == 0;

  String get shortMethod {
    final parts = method.split('/');
    return parts.length >= 3 ? '${parts[1]}/${parts[2]}' : method;
  }
}
