import 'package:flutter/foundation.dart';
import 'package:grpc/grpc.dart';

import 'package:grpc_devtools/src/event_bus.dart';
import 'package:grpc_devtools/src/rpc_call.dart';

/// A [ClientInterceptor] that captures gRPC calls and sends them to the
/// DevTools Extension via [dart:developer]'s [postEvent].
///
/// In release builds this interceptor is a transparent passthrough — no data
/// is collected or transmitted. You can therefore register it unconditionally:
///
/// ```dart
/// final stub = MyServiceClient(
///   channel,
///   interceptors: [GrpcDevToolsInterceptor()],
/// );
/// ```
///
/// To prevent sensitive metadata values (e.g. auth tokens) from appearing in
/// DevTools, specify the keys you want to hide:
///
/// ```dart
/// GrpcDevToolsInterceptor(
///   maskedMetadataKeys: {'authorization'},
/// )
/// ```
///
/// Matching is case-insensitive. Masked values are replaced with `'***'`.
class GrpcDevToolsInterceptor extends ClientInterceptor {
  final GrpcDevToolsEventBus _eventBus;

  /// Metadata keys whose values will be replaced with `'***'` in DevTools.
  ///
  /// Matching is case-insensitive. Defaults to no masking.
  final Set<String> maskedMetadataKeys;

  GrpcDevToolsInterceptor({
    GrpcDevToolsEventBus? eventBus,
    Set<String> maskedMetadataKeys = const {},
  })  : _eventBus = eventBus ?? GrpcDevToolsEventBus(),
        maskedMetadataKeys = {
          for (final k in maskedMetadataKeys) k.toLowerCase()
        };

  @visibleForTesting
  Map<String, String> maskMetadata(Map<String, String> metadata) {
    if (maskedMetadataKeys.isEmpty) {
      return metadata;
    }
    return {
      for (final entry in metadata.entries)
        entry.key: maskedMetadataKeys.contains(entry.key.toLowerCase())
            ? '***'
            : entry.value,
    };
  }

  @override
  ResponseFuture<R> interceptUnary<Q, R>(
    ClientMethod<Q, R> method,
    Q request,
    CallOptions options,
    ClientUnaryInvoker<Q, R> invoker,
  ) {
    if (kReleaseMode) {
      return invoker(method, request, options);
    }

    final callId = _eventBus.generateCallId();
    final startTime = DateTime.now();

    _eventBus.emitCallStarted(
      callId: callId,
      method: method.path,
      type: RpcCallType.unary,
      request: request,
      metadata: maskMetadata(options.metadata),
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
    if (kReleaseMode) {
      return invoker(method, requests, options);
    }

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
      metadata: maskMetadata(options.metadata),
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
