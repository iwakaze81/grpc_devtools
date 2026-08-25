import 'package:grpc_devtools/src/proto_decoder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protobuf/protobuf.dart';

final class _TestMessage extends GeneratedMessage {
  static final BuilderInfo _i = BuilderInfo('_TestMessage')
    ..aOS(1, 'value')
    ..hasRequiredFields = false;

  _TestMessage._();

  factory _TestMessage({String? value}) {
    final result = _TestMessage._();
    if (value != null) {
      result.value = value;
    }
    return result;
  }

  @override
  BuilderInfo get info_ => _i;

  @override
  _TestMessage createEmptyInstance() => _TestMessage._();

  @override
  _TestMessage clone() => _TestMessage()..mergeFromMessage(this);

  String get value => $_getSZ(0);

  set value(String value) => $_setString(0, value);
}

void main() {
  group('ProtoDecoder', () {
    group('tryDecode', () {
      test('non-GeneratedMessage returns null', () {
        expect(ProtoDecoder.tryDecode('hello'), isNull);
        expect(ProtoDecoder.tryDecode(42), isNull);
        expect(ProtoDecoder.tryDecode(null), isNull);
      });

      test('GeneratedMessage returns its proto3 JSON representation', () {
        final message = _TestMessage(value: 'hello');

        expect(ProtoDecoder.tryDecode(message), {'value': 'hello'});
      });
    });

    group('toReadableString', () {
      test('null returns empty string', () {
        expect(ProtoDecoder.toReadableString(null), '');
      });

      test('plain object returns toString()', () {
        expect(ProtoDecoder.toReadableString('hello'), 'hello');
        expect(ProtoDecoder.toReadableString(42), '42');
      });

      test('GeneratedMessage returns indented proto3 JSON', () {
        final message = _TestMessage(value: 'hello');

        expect(
          ProtoDecoder.toReadableString(message),
          '{\n  "value": "hello"\n}',
        );
      });
    });
  });
}
