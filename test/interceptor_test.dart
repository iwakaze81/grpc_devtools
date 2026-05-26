import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:grpc_devtools/src/event_bus.dart';
import 'package:grpc_devtools/src/rpc_call.dart';

class FakeEventBus extends GrpcDevToolsEventBus {
  final List<String> events = [];

  @override
  void emitCallStarted({
    required String callId,
    required String method,
    required RpcCallType type,
    required Object? request,
    required Map<String, String> metadata,
  }) {
    events.add('started:$method:${type.name}');
  }

  @override
  void emitCallHeaders({
    required String callId,
    required Map<String, String> headers,
  }) {
    events.add('headers');
  }

  @override
  void emitCallEnded({
    required String callId,
    required DateTime startTime,
    Object? response,
    Object? error,
    Map<String, String>? trailers,
  }) {
    final status = error is GrpcError ? error.code : 0;
    events.add('ended:$status');
  }

  @override
  void emitCallMessage({
    required String callId,
    required RpcMessageDirection direction,
    required Object? message,
  }) {
    events.add('message:${direction.name}');
  }
}

void main() {
  group('GrpcDevToolsEventBus', () {
    test('generateCallId produces unique IDs', () {
      final bus = GrpcDevToolsEventBus();
      final ids = List.generate(100, (_) => bus.generateCallId());
      expect(ids.toSet().length, 100);
    });

    test('generateCallId has hex-timestamp format', () {
      final id = GrpcDevToolsEventBus().generateCallId();
      expect(id, matches(RegExp(r'^[0-9a-f]+-[0-9a-f]+$')));
    });

    test('emitCallEnded encodes GrpcError status code', () {
      final bus = FakeEventBus();
      bus.emitCallEnded(
        callId: 'id1',
        startTime: DateTime.now(),
        error: GrpcError.notFound('not found'),
      );
      expect(bus.events, contains('ended:${StatusCode.notFound}'));
    });

    test('emitCallEnded encodes success as status 0', () {
      final bus = FakeEventBus();
      bus.emitCallEnded(
        callId: 'id2',
        startTime: DateTime.now(),
        response: 'response data',
      );
      expect(bus.events, contains('ended:0'));
    });

    test('emitCallStarted records method and type', () {
      final bus = FakeEventBus();
      bus.emitCallStarted(
        callId: 'id3',
        method: '/test.Service/Hello',
        type: RpcCallType.unary,
        request: null,
        metadata: const {},
      );
      expect(bus.events, contains('started:/test.Service/Hello:unary'));
    });

    test('emitCallMessage records direction', () {
      final bus = FakeEventBus();
      bus.emitCallMessage(
        callId: 'id4',
        direction: RpcMessageDirection.request,
        message: 'req',
      );
      bus.emitCallMessage(
        callId: 'id4',
        direction: RpcMessageDirection.response,
        message: 'res',
      );
      expect(bus.events, containsAll(['message:request', 'message:response']));
    });
  });

  group('RpcCall', () {
    final baseCall = RpcCall(
      id: 'id1',
      method: '/test.Service/Hello',
      type: RpcCallType.unary,
      startTime: DateTime(2024),
    );

    test('isCompleted is false when endTime is null', () {
      expect(baseCall.isCompleted, isFalse);
    });

    test('duration is null when endTime is null', () {
      expect(baseCall.duration, isNull);
    });

    test('copyWith creates new instance with updated fields', () {
      final endTime = DateTime(2024, 1, 1, 0, 0, 1);
      final updated = baseCall.copyWith(
        endTime: endTime,
        grpcStatusCode: 0,
        grpcStatusMessage: 'OK',
      );

      expect(updated.id, 'id1');
      expect(updated.method, '/test.Service/Hello');
      expect(updated.endTime, endTime);
      expect(updated.grpcStatusCode, 0);
      expect(updated.grpcStatusMessage, 'OK');
      expect(updated.isCompleted, isTrue);
      expect(updated.isOk, isTrue);
    });

    test('copyWith does not mutate original', () {
      baseCall.copyWith(
        endTime: DateTime(2024, 1, 1, 0, 0, 1),
        grpcStatusCode: 0,
      );
      expect(baseCall.endTime, isNull);
      expect(baseCall.grpcStatusCode, isNull);
    });

    test('duration returns correct value after copyWith', () {
      final end = baseCall.startTime.add(const Duration(milliseconds: 250));
      final updated = baseCall.copyWith(endTime: end);
      expect(updated.duration, const Duration(milliseconds: 250));
    });

    test('toJson includes all fields', () {
      final updated = baseCall.copyWith(
        endTime: DateTime(2024, 1, 1, 0, 0, 1),
        grpcStatusCode: 0,
        grpcStatusMessage: 'OK',
      );
      final json = updated.toJson();

      expect(json['id'], 'id1');
      expect(json['method'], '/test.Service/Hello');
      expect(json['type'], 'unary');
      expect(json['grpcStatusCode'], 0);
    });
  });
}
