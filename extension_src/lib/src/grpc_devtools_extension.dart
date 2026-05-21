import 'package:devtools_app_shared/ui.dart';
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import 'package:grpc_devtools_extension/src/rpc_call_detail_view.dart';
import 'package:grpc_devtools_extension/src/rpc_call_list_view.dart';
import 'package:grpc_devtools_extension/src/rpc_call_model.dart';
import 'package:grpc_devtools_extension/src/rpc_event_handler.dart';

class GrpcDevToolsExtensionApp extends StatelessWidget {
  const GrpcDevToolsExtensionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevToolsExtension(
      child: GrpcDevToolsHome(),
    );
  }
}

class GrpcDevToolsHome extends StatefulWidget {
  const GrpcDevToolsHome({super.key});

  @override
  State<GrpcDevToolsHome> createState() => _GrpcDevToolsHomeState();
}

class _GrpcDevToolsHomeState extends State<GrpcDevToolsHome> {
  final _handler = RpcEventHandler();
  RpcCallModel? _selectedCall;

  @override
  void initState() {
    super.initState();
    _handler
      ..addListener(_onHandlerChanged)
      ..startListening();
  }

  void _onHandlerChanged() => setState(() {});

  @override
  void dispose() {
    _handler
      ..removeListener(_onHandlerChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calls = _handler.calls;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: defaultSpacing,
        title: const Text('gRPC DevTools'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear all',
            onPressed: () {
              _handler.clear();
              setState(() => _selectedCall = null);
            },
          ),
          const SizedBox(width: densePadding),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _selectedCall != null
                ? _SplitView(
                    calls: calls,
                    selectedCallId: _selectedCall!.id,
                    selectedCall: _selectedCall!,
                    onCallSelected: (c) => setState(() => _selectedCall = c),
                    onClose: () => setState(() => _selectedCall = null),
                  )
                : RpcCallListView(
                    calls: calls,
                    selectedCallId: null,
                    onCallSelected: (c) => setState(() => _selectedCall = c),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SplitView extends StatefulWidget {
  const _SplitView({
    required this.calls,
    required this.selectedCallId,
    required this.selectedCall,
    required this.onCallSelected,
    required this.onClose,
  });

  final List<RpcCallModel> calls;
  final String selectedCallId;
  final RpcCallModel selectedCall;
  final ValueChanged<RpcCallModel> onCallSelected;
  final VoidCallback onClose;

  @override
  State<_SplitView> createState() => _SplitViewState();
}

class _SplitViewState extends State<_SplitView> {
  static const double _minLeftWidth = 160;
  static const double _maxLeftWidth = 600;
  static const double _dividerHitWidth = 8;

  double _leftWidth = 320;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: _leftWidth,
          child: RpcCallListView(
            calls: widget.calls,
            selectedCallId: widget.selectedCallId,
            onCallSelected: widget.onCallSelected,
          ),
        ),
        MouseRegion(
          cursor: _isDragging ? SystemMouseCursors.resizeColumn : SystemMouseCursors.resizeColumn,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => setState(() => _isDragging = true),
            onPointerMove: (e) {
              if (!_isDragging) return;
              setState(() {
                _leftWidth = (_leftWidth + e.delta.dx).clamp(_minLeftWidth, _maxLeftWidth);
              });
            },
            onPointerUp: (_) => setState(() => _isDragging = false),
            onPointerCancel: (_) => setState(() => _isDragging = false),
            child: SizedBox(
              width: _dividerHitWidth,
              child: Center(
                child: VerticalDivider(
                  width: 1,
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: widget.onClose,
                  tooltip: 'Close details',
                ),
              ),
              Expanded(child: RpcCallDetailView(call: widget.selectedCall)),
            ],
          ),
        ),
      ],
    );
  }
}

