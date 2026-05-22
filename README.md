# grpc_devtools

[English](README.en.md)

Flutter アプリの gRPC 通信をリアルタイムで可視化・デバッグするための DevTools 拡張機能です。

![grpc_devtools screenshot](https://raw.githubusercontent.com/iwakaze81/grpc_devtools/main/docs/screenshot.png)

## 機能

- gRPC calls の一覧表示（メソッド名・ステータス・所要時間）
- リクエスト / レスポンスの内容確認
- メタデータ・ヘッダー・トレーラーの確認
- Streaming RPC のメッセージ一覧
- 左右ペインのドラッグによるサイズ変更

## インストール

`pubspec.yaml` の `dependencies` に追加します。

```yaml
dependencies:
  grpc_devtools:
    git:
      url: https://github.com/iwakaze81/grpc_devtools.git
```

## セットアップ

### 1. Interceptor を追加

`GrpcDevToolsInterceptor` を gRPC チャンネルに追加します。

```dart
import 'package:grpc_devtools/grpc_devtools.dart';

final channel = ClientChannel('localhost');
final stub = YourServiceClient(
  channel,
  options: CallOptions(
    // ...
  ),
  interceptors: [
    GrpcDevToolsInterceptor(), // release ビルドでは自動的に no-op になります
  ],
);
```

### 2. DevTools Extension を有効化

アプリの `devtools_options.yaml`（`pubspec.yaml` と同じ階層）に追加します。

```yaml
description: This file stores settings for Dart & Flutter DevTools.
extensions:
  - grpc_devtools: true
```

### 3. アプリを起動して DevTools を開く

デバッグモードでアプリを起動し、Flutter DevTools の **grpc_devtools** タブを開くと gRPC コールがリアルタイムで表示されます。

## Usage

| 操作 | 内容 |
|------|------|
| コールをクリック | リクエスト・レスポンスの詳細を表示 |
| 分割線をドラッグ | 左右ペインのサイズ変更 |
| ゴミ箱アイコン | 全コールをクリア |

## Requirements

- Flutter 3.24.0 以上
- Dart 3.4.0 以上
- gRPC パッケージ (`grpc: ^3.2.4`)

## License

MIT
