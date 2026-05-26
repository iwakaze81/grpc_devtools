# grpc_devtools

[日本語](README.ja.md)

A Flutter DevTools extension for visualizing and debugging gRPC communication in real time.

## Features

- List of gRPC calls (method name, status, duration)
- Inspect request / response contents
- View metadata, headers, and trailers
- Message list for Streaming RPCs
- Resizable left/right panes via drag

## Installation

Add to `dependencies` in your `pubspec.yaml`.

```yaml
dependencies:
  grpc_devtools: ^0.2.0
```

## Setup

### 1. Add the Interceptor

Add `GrpcDevToolsInterceptor` to your gRPC channel.

```dart
import 'package:grpc_devtools/grpc_devtools.dart';

final channel = ClientChannel('localhost');
final stub = YourServiceClient(
  channel,
  options: CallOptions(
    // ...
  ),
  interceptors: [
    GrpcDevToolsInterceptor(
      // Mask sensitive metadata values from appearing in DevTools (opt-in).
      maskedMetadataKeys: {'authorization'},
    ),
  ],
);
```

### 2. Enable the DevTools Extension

Add the following to `devtools_options.yaml` (same directory as `pubspec.yaml`).

```yaml
description: This file stores settings for Dart & Flutter DevTools.
extensions:
  - grpc_devtools: true
```

### 3. Launch the App and Open DevTools

Run the app in debug mode and open the **grpc_devtools** tab in Flutter DevTools — gRPC calls will appear in real time.

## Usage

| Action | Description |
|--------|-------------|
| Click a call | Show request/response details |
| Drag the divider | Resize left/right panes |
| Trash icon | Clear all calls |

## Notes

- gRPC metadata (e.g. authorization tokens) is captured and displayed in DevTools. Use `maskedMetadataKeys` to hide sensitive values — they will appear as `***` instead.
- The interceptor is a transparent no-op in release builds — no data is collected or transmitted.

## Requirements

- Flutter 3.24.0 or later
- Dart 3.4.0 or later
- gRPC package (`grpc: >=3.2.4 <6.0.0`)

## License

MIT
