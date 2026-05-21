import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:grpc_devtools_extension/src/rpc_call_model.dart';
import 'package:grpc_devtools_extension/src/status_code.dart';

class RpcCallDetailView extends StatefulWidget {
  const RpcCallDetailView({super.key, required this.call});

  final RpcCallModel call;

  @override
  State<RpcCallDetailView> createState() => _RpcCallDetailViewState();
}

class _RpcCallDetailViewState extends State<RpcCallDetailView> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final call = widget.call;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailHeader(call: call),
        const Divider(height: 1),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Request'),
            Tab(text: 'Response'),
            Tab(text: 'Metadata'),
            Tab(text: 'Messages'),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _JsonPane(content: call.requestDecoded, label: 'Request body'),
              _JsonPane(content: call.responseDecoded, label: 'Response body'),
              _MetadataPane(call: call),
              _MessagesPane(messages: call.messages),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.call});

  final RpcCallModel call;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusCode = call.grpcStatusCode;
    final statusColor = GrpcStatusCode.color(statusCode);

    return Padding(
      padding: const EdgeInsets.all(defaultSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            call.method,
            style: theme.textTheme.titleSmall?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: densePadding),
          Wrap(
            spacing: denseSpacing,
            runSpacing: densePadding,
            children: [
              _Chip(
                label: GrpcStatusCode.name(statusCode),
                color: statusColor,
              ),
              if (call.type == 'streaming')
                const _Chip(
                  label: 'STREAMING',
                  color: Colors.blue,
                ),
              if (call.duration != null)
                _Chip(
                  label: _formatDuration(call.duration!),
                  color: call.duration!.inMilliseconds > 1000 ? Colors.orange : Colors.grey,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final ms = d.inMilliseconds;
    return ms < 1000 ? '${ms}ms' : '${(ms / 1000).toStringAsFixed(2)}s';
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
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

class _JsonPane extends StatelessWidget {
  const _JsonPane({required this.content, required this.label});

  final String? content;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (content == null || content!.isEmpty) {
      return Center(
        child: Text(
          'No $label',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return Stack(
      children: [
        Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(defaultSpacing),
            child: SelectableText(
              content!,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
        ),
        Positioned(
          top: densePadding,
          right: defaultSpacing,
          child: _CopyButton(content: content!),
        ),
      ],
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.copy, size: 16),
      tooltip: 'Copy',
      onPressed: () {
        Clipboard.setData(ClipboardData(text: content));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied to clipboard'),
            duration: Duration(seconds: 1),
          ),
        );
      },
    );
  }
}

class _MetadataPane extends StatelessWidget {
  const _MetadataPane({required this.call});

  final RpcCallModel call;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(defaultSpacing),
      children: [
        _MetadataSection(
          title: 'Request Metadata',
          metadata: call.requestMetadata,
        ),
        const SizedBox(height: defaultSpacing),
        _MetadataSection(
          title: 'Response Headers',
          metadata: call.responseHeaders,
        ),
        const SizedBox(height: defaultSpacing),
        _MetadataSection(
          title: 'Trailers',
          metadata: call.trailerMetadata,
        ),
      ],
    );
  }
}

class _MetadataSection extends StatelessWidget {
  const _MetadataSection({required this.title, required this.metadata});

  final String title;
  final Map<String, String>? metadata;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: densePadding),
        if (metadata == null || metadata!.isEmpty)
          Text(
            'None',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          )
        else
          ...metadata!.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 200,
                    child: SelectableText(
                      e.key,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: denseSpacing),
                  Expanded(
                    child: SelectableText(
                      e.value,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MessagesPane extends StatelessWidget {
  const _MessagesPane({required this.messages});

  final List<RpcStreamMessage> messages;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
        child: Text(
          'No stream messages captured.\n'
          'Response-side message interception is available in Phase 2.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(defaultSpacing),
      itemCount: messages.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isRequest = msg.direction == 'request';
        return ListTile(
          leading: Icon(
            isRequest ? Icons.arrow_upward : Icons.arrow_downward,
            color: isRequest ? Colors.blue : Colors.green,
            size: 16,
          ),
          title: Text(
            msg.data,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            msg.timestamp.toIso8601String(),
            style: const TextStyle(fontSize: 11),
          ),
        );
      },
    );
  }
}
