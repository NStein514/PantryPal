import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../l10n/l10n.dart';

/// A short, translated message for a failed scan step instead of a raw exception.
String friendlyScanError(AppLocalizations l, Object error) {
  if (error is SocketException || error is TimeoutException || error is http.ClientException) {
    return l.offlineError;
  }
  final text = '$error';
  if (text.contains('AI error')) return l.aiUnavailable; // AiService: non-200 from the proxy
  return l.failed(text);
}
