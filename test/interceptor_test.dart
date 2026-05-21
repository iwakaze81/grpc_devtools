import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:grpc_devtools/src/event_bus.dart';
import 'package:grpc_devtools/src/rpc_call.dart';

// Records calls made to GrpcDevToolsEventBus for assertion in tests.
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
  group('GrpcDevToolsInterceptor', () {
    late FakeEventBus eventBus;

    setUp(() {
      eventBus = FakeEventBus();
    });

    group('interceptUnary', () {
      test('emits call_started and call_ended on success', () async {
        const method = '/test.Service/Hello';
        const options = <String, String>{};

        eventBus.emitCallStarted(
          callId: 'id1',
          method: method,
          type: RpcCallType.unary,
          request: 'hello',
          metadata: options,
        );

        expect(eventBus.events, contains('started:/test.Service/Hello:unary'));
      });

      test('emitCallEnded encodes GrpcError status code', () {
        eventBus.emitCallEnded(
          callId: 'id2',
          startTime: DateTime.now(),
          error: GrpcError.notFound('not found'),
        );
        expect(eventBus.events, contains('ended:${StatusCode.notFound}'));
      });

      test('emitCallEnded success has status 0', () {
        eventBus.emitCallEnded(
          callId: 'id3',
          startTime: DateTime.now(),
          response: 'response data',
        );
        expect(eventBus.events, contains('ended:0'));
      });
    });

    group('interceptStreaming', () {
      test('emits call_started with streaming type', () {
        eventBus.emitCallStarted(
          callId: 'sid1',
          method: '/stream.Service/Watch',
          type: RpcCallType.streaming,
          request: null,
          metadata: const {},
        );
        expect(
          eventBus.events,
          contains('started:/stream.Service/Watch:streaming'),
        );
      });

      test('emits message for each request in stream', () {
        eventBus.emitCallMessage(
          callId: 'sid2',
          direction: RpcMessageDirection.request,
          message: 'req1',
        );
        eventBus.emitCallMessage(
          callId: 'sid2',
          direction: RpcMessageDirection.request,
          message: 'req2',
        );
        expect(eventBus.events.where((e) => e == 'message:request'), hasLength(2));
      });
    });
  });
}
