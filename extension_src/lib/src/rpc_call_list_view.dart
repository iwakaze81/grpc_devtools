import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';

import 'package:grpc_devtools_extension/src/rpc_call_model.dart';
import 'package:grpc_devtools_extension/src/status_code.dart';

class RpcCallListView extends StatelessWidget {
  const RpcCallListView({
    super.key,
    required this.calls,
    required this.selectedCallId,
    required this.onCallSelected,
  });

  final List<RpcCallModel> calls;
  final String? selectedCallId;
  final ValueChanged<RpcCallModel> onCallSelected;

  @override
  Widget build(BuildContext context) {
    if (calls.isEmpty) {
      return const Center(
        child: Text(
          'No gRPC calls yet.\nMake sure GrpcDevToolsInterceptor is added.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: calls.length,
      itemBuilder: (context, index) {
        final call = calls[calls.length - 1 - index];
        return _RpcCallTile(
          call: call,
          isSelected: call.id == selectedCallId,
          onTap: () => onCallSelected(call),
        );
      },
    );
  }
}

class _RpcCallTile extends StatelessWidget {
  const _RpcCallTile({
    required this.call,
    required this.isSelected,
    required this.onTap,
  });

  final RpcCallModel call;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusCode = call.grpcStatusCode;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isSelected ? theme.colorScheme.primaryContainer.withAlpha(100) : null,
        padding: const EdgeInsets.symmetric(
          horizontal: defaultSpacing,
          vertical: densePadding,
        ),
        child: Row(
          children: [
            _StatusBadge(code: statusCode),
            const SizedBox(width: denseSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    call.shortMethod,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    call.method,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: denseSpacing),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _DurationText(call: call),
                Text(
                  call.type,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.code});

  final int? code;

  @override
  Widget build(BuildContext context) {
    final color = GrpcStatusCode.color(code);
    final label = code != null ? GrpcStatusCode.name(code) : '...';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        border: Border.all(color: color.withAlpha(150)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _DurationText extends StatelessWidget {
  const _DurationText({required this.call});

  final RpcCallModel call;

  @override
  Widget build(BuildContext context) {
    final duration = call.duration;
    if (duration == null) {
      return const Text('...', style: TextStyle(fontSize: 12));
    }

    final ms = duration.inMilliseconds;
    final text = ms < 1000 ? '${ms}ms' : '${(ms / 1000).toStringAsFixed(1)}s';

    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: ms > 1000 ? Colors.orange : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
