import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantrypal/services/ai_service.dart';

http.Response _reply(String text) => http.Response(
      jsonEncode({'content': [{'type': 'text', 'text': text}]}), 200,
      headers: {'content-type': 'application/json'});

void main() {
  test('throws on non-200 responses', () {
    final ai = AiService(client: MockClient((_) async => http.Response('nope', 500)));
    expect(() => ai.parseReceipt(Uint8List.fromList([1])), throwsException);
  });

  test('parseReceipt sends the image and accepts an {"items": [...]} wrapper', () async {
    late Map<String, dynamic> sent;
    final ai = AiService(client: MockClient((req) async {
      sent = jsonDecode(req.body);
      return _reply('{"items":[{"name":"Whole milk","category":"Dairy","quantity":2,"shelf_life_days":7,"expiry":null},'
          '"junk",{"name":"Bananas","category":"Produce","quantity":1}]}');
    }));
    final items = await ai.parseReceipt(Uint8List.fromList([9, 9]));
    expect(items.map((i) => i['name']), ['Whole milk', 'Bananas']);
    expect(items.first['quantity'], 2);
    expect(sent['messages'][0]['content'][0]['source']['data'], base64Encode([9, 9]));
    expect(sent['system'], contains('receipt'));
  });

  test('non-English language asks for translated text but fixed enum values', () async {
    final systems = <String>[];
    final ai = AiService(client: MockClient((req) async {
      systems.add(jsonDecode(req.body)['system']);
      return _reply('[]');
    }));
    await ai.parseReceipt(Uint8List.fromList([1]), language: 'Spanish');
    await ai.parseReceipt(Uint8List.fromList([1]), language: 'English');
    expect(systems[0], contains('in Spanish'));
    expect(systems[0], contains('category and unit values exactly as listed'));
    expect(systems[1], isNot(contains('Write all names')));
  });

  test('an unreachable proxy fails with a timeout instead of hanging (default ${AiService.defaultTimeout.inSeconds} s)', () async {
    final ai = AiService(client: MockClient((_) => Completer<http.Response>().future), timeout: const Duration(milliseconds: 50)); // never answers
    await expectLater(
      Future.any([ai.parseReceipt(Uint8List.fromList([1])), Future.delayed(const Duration(seconds: 5), () => 'hung')]),
      throwsA(isA<TimeoutException>()),
    );
  });
}
