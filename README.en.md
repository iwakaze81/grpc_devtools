# grpc_devtools

[日本語](README.md)

A Flutter DevTools extension for visualizing and debugging gRPC communication in real time.

![grpc_devtools screenshot](https://raw.githubusercontent.com/iwakaze81/grpc_devtools/main/docs/screenshot.png)

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
  grpc_devtools:
    git:
      url: https://github.com/iwakaze81/grpc_devtools.git
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
    GrpcDevToolsInterceptor(), // automatically becomes a no-op in release builds
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

## Requirements

- Flutter 3.24.0 or later
- Dart 3.4.0 or later
- gRPC package (`grpc: ^3.2.4`)

## License

MIT
