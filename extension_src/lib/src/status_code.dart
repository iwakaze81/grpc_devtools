import 'package:flutter/material.dart';

abstract final class GrpcStatusCode {
  static const int ok = 0;
  static const int cancelled = 1;
  static const int unknown = 2;
  static const int invalidArgument = 3;
  static const int deadlineExceeded = 4;
  static const int notFound = 5;
  static const int alreadyExists = 6;
  static const int permissionDenied = 7;
  static const int resourceExhausted = 8;
  static const int failedPrecondition = 9;
  static const int aborted = 10;
  static const int outOfRange = 11;
  static const int unimplemented = 12;
  static const int internal = 13;
  static const int unavailable = 14;
  static const int dataLoss = 15;
  static const int unauthenticated = 16;

  static String name(int? code) => switch (code) {
        0 => 'OK',
        1 => 'CANCELLED',
        2 => 'UNKNOWN',
        3 => 'INVALID_ARGUMENT',
        4 => 'DEADLINE_EXCEEDED',
        5 => 'NOT_FOUND',
        6 => 'ALREADY_EXISTS',
        7 => 'PERMISSION_DENIED',
        8 => 'RESOURCE_EXHAUSTED',
        9 => 'FAILED_PRECONDITION',
        10 => 'ABORTED',
        11 => 'OUT_OF_RANGE',
        12 => 'UNIMPLEMENTED',
        13 => 'INTERNAL',
        14 => 'UNAVAILABLE',
        15 => 'DATA_LOSS',
        16 => 'UNAUTHENTICATED',
        _ => code != null ? 'CODE($code)' : 'IN_PROGRESS',
      };

  static Color color(int? code) => switch (code) {
        null => Colors.grey,
        0 => const Color(0xFF2E7D32), // green 800
        1 => Colors.orange, // cancelled
        4 => const Color(0xFFE65100), // deadline exceeded - orange dark
        14 => const Color(0xFFC62828), // unavailable - red
        _ => const Color(0xFFB71C1C), // other errors - red dark
      };
}
