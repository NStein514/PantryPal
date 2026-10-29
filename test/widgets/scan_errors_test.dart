import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pantrypal/l10n/l10n.dart';
import 'package:pantrypal/widgets/scan_errors.dart';

void main() {
  final l = l10nFor(const Locale('en'));
  test('network problems read as "no connection"', () {
    for (final e in [const SocketException('down'), TimeoutException('slow'), http.ClientException('x')]) {
      expect(friendlyScanError(l, e), l.offlineError, reason: '$e');
    }
  });
  test('AI proxy failures and anything else', () {
    expect(friendlyScanError(l, Exception('AI error 503')), l.aiUnavailable);
    expect(friendlyScanError(l, StateError('odd')), startsWith('Failed:'));
  });
}
