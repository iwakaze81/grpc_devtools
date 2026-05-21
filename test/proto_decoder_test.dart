import 'package:grpc_devtools/src/proto_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProtoDecoder', () {
    group('tryDecode', () {
      test('non-GeneratedMessage returns null', () {
        expect(ProtoDecoder.tryDecode('hello'), isNull);
        expect(ProtoDecoder.tryDecode(42), isNull);
        expect(ProtoDecoder.tryDecode(null), isNull);
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
    });
  });
}
