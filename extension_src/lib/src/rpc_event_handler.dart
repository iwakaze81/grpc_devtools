import 'dart:async';
import 'dart:convert';

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:vm_service/vm_service.dart';

import 'package:grpc_devtools_extension/src/rpc_call_model.dart';

const String _kCallStarted = 'ext.grpc_devtools.call_started';
const String _kCallMessage = 'ext.grpc_devtools.call_message';
const String _kCallHeaders = 'ext.grpc_devtools.call_headers';
const String _kCallEnded = 'ext.grpc_devtools.call_ended';

/// Listens to VM service extension events from the app and updates the
/// [calls] list accordingly.
///
/// Automatically re-subscribes when the VM service connection changes so that
/// events are captured even if DevTools was opened after the app started.
class RpcEventHandler extends ChangeNotifier {
  final List<RpcCallModel> _calls = [];
  StreamSubscription<Event>? _subscription;

  List<RpcCallModel> get calls => List.unmodifiable(_calls);

  void startListening() {
    // Subscribe immediately if already connected.
    _resubscribe();
    // Re-subscribe whenever the connection state changes.
    serviceManager.connectedState.addListener(_onConnectionChanged);
  }

  void stopListening() {
    serviceManager.connectedState.removeListener(_onConnectionChanged);
    _subscription?.cancel();
    _subscription = null;
  }

  void clear() {
    _calls.clear();
    notifyListeners();
  }

  void _onConnectionChanged() => _resubscribe();

  void _resubscribe() {
    _subscription?.cancel();
    _subscription = null;

    final service = serviceManager.service;
    if (service == null) {
      return;
    }

    // Explicitly ensure the Extension stream is subscribed on the VM side.
    service.streamListen('Extension').ignore();

    _subscription = service.onExtensionEvent.listen(_handleEvent);
  }

  void _handleEvent(Event event) {
    final kind = event.extensionKind;
    final data = event.extensionData?.data;
    if (kind == null || data == null) {
      return;
    }

    switch (kind) {
      case _kCallStarted:
        _onCallStarted(data);
      case _kCallMessage:
        _onCallMessage(data);
      case _kCallHeaders:
        _onCallHeaders(data);
      case _kCallEnded:
        _onCallEnded(data);
    }
  }

  void _onCallStarted(Map<String, dynamic> data) {
    final callId = data['callId'] as String?;
    if (callId == null) {
      return;
    }

    final ts = data['timestamp'] as int?;
    final call = RpcCallModel(
      id: callId,
      method: data['method'] as String? ?? '',
      type: data['type'] as String? ?? 'unary',
      startTime: ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : DateTime.now(),
      requestDecoded: data['request'] as String?,
      requestMetadata: _decodeMetadata(data['metadata']),
    );

    _calls.add(call);
    notifyListeners();
  }

  void _onCallMessage(Map<String, dynamic> data) {
    final callId = data['callId'] as String?;
    if (callId == null) {
      return;
    }

    final call = _findCall(callId);
    if (call == null) {
      return;
    }

    final direction = data['direction'] as String? ?? 'request';
    final message = RpcStreamMessage(
      direction: direction,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        data['timestamp'] as int? ?? 0,
      ),
      data: data['data'] as String? ?? '',
    );

    call.messages.add(message);
    notifyListeners();
  }

  void _onCallHeaders(Map<String, dynamic> data) {
    final callId = data['callId'] as String?;
    if (callId == null) {
      return;
    }

    final call = _findCall(callId);
    if (call == null) {
      return;
    }

    call.responseHeaders = _decodeMetadata(data['headers']);
    notifyListeners();
  }

  void _onCallEnded(Map<String, dynamic> data) {
    final callId = data['callId'] as String?;
    if (callId == null) {
      return;
    }

    final call = _findCall(callId);
    if (call == null) {
      return;
    }

    final endTs = data['endTime'] as int?;
    call
      ..endTime = endTs != null ? DateTime.fromMillisecondsSinceEpoch(endTs) : DateTime.now()
      ..grpcStatusCode = data['statusCode'] as int?
      ..grpcStatusMessage = data['statusMessage'] as String?
      ..responseDecoded = data['response'] as String?
      ..trailerMetadata = _decodeMetadata(data['trailers']);

    notifyListeners();
  }

  RpcCallModel? _findCall(String callId) {
    try {
      return _calls.lastWhere((c) => c.id == callId);
    } catch (_) {
      return null;
    }
  }

  Map<String, String>? _decodeMetadata(Object? raw) {
    if (raw is! String || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.cast<String, String>();
      }
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
