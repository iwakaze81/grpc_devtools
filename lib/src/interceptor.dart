import 'package:grpc/grpc.dart';

import 'package:grpc_devtools/src/event_bus.dart';
import 'package:grpc_devtools/src/rpc_call.dart';

/// A [ClientInterceptor] that captures gRPC calls and sends them to the
/// DevTools Extension via [dart:developer]'s [postEvent].
///
/// Usage:
/// ```dart
/// final stub = MyServiceClient(
///   channel,
///   interceptors: [
///     if (kDebugMode) GrpcDevToolsInterceptor(),
///   ],
/// );
/// ```
class GrpcDevToolsInterceptor extends ClientInterceptor {
  final GrpcDevToolsEventBus _eventBus;

  GrpcDevToolsInterceptor({GrpcDevToolsEventBus? eventBus})
      : _eventBus = eventBus ?? GrpcDevToolsEventBus();

  @override
  ResponseFuture<R> interceptUnary<Q, R>(
    ClientMethod<Q, R> method,
    Q request,
    CallOptions options,
    ClientUnaryInvoker<Q, R> invoker,
  ) {
    final callId = _eventBus.generateCallId();
    final startTime = DateTime.now();

    _eventBus.emitCallStarted(
      callId: callId,
      method: method.path,
      type: RpcCallType.unary,
      request: request,
      metadata: options.metadata,
    );

    final response = invoker(method, request, options);

    response.headers.then(
      (headers) => _eventBus.emitCallHeaders(callId: callId, headers: headers),
      onError: (_) {},
    );

    response.then(
      (r) {
        response.trailers.then(
          (trailers) => _eventBus.emitCallEnded(
            callId: callId,
            startTime: startTime,
            response: r,
            trailers: trailers,
          ),
          onError: (_) => _eventBus.emitCallEnded(
            callId: callId,
            startTime: startTime,
            response: r,
          ),
        );
      },
      onError: (Object error) {
        _eventBus.emitCallEnded(
          callId: callId,
          startTime: startTime,
          error: error,
        );
      },
    );

    return response;
  }

  @override
  ResponseStream<R> interceptStreaming<Q, R>(
    ClientMethod<Q, R> method,
    Stream<Q> requests,
    CallOptions options,
    ClientStreamingInvoker<Q, R> invoker,
  ) {
    final callId = _eventBus.generateCallId();
    final startTime = DateTime.now();

    // Wrap request stream to record each outgoing message.
    final wrappedRequests = requests.map((req) {
      _eventBus.emitCallMessage(
        callId: callId,
        direction: RpcMessageDirection.request,
        message: req,
      );
      return req;
    });

    _eventBus.emitCallStarted(
      callId: callId,
      method: method.path,
      type: RpcCallType.streaming,
      request: null,
      metadata: options.metadata,
    );

    final response = invoker(method, wrappedRequests, options);

    response.headers.then(
      (headers) => _eventBus.emitCallHeaders(callId: callId, headers: headers),
      onError: (_) {},
    );

    // Record completion via trailers (resolves after all messages).
    response.trailers.then(
      (trailers) => _eventBus.emitCallEnded(
        callId: callId,
        startTime: startTime,
        trailers: trailers,
      ),
      onError: (Object error) => _eventBus.emitCallEnded(
        callId: callId,
        startTime: startTime,
        error: error,
      ),
    );

    return response;
  }
}
