import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_network/sanyan_network.dart';

void main() {
  test('WsClient exposes onDisconnected stream', () {
    final client = WsClient();
    expect(client.onDisconnected, isA<Stream<void>>());
  });

  test('notifyDisconnectedForTest causes onDisconnected to emit', () async {
    final client = WsClient();
    final events = <void>[];
    final sub = client.onDisconnected.listen(events.add);

    client.notifyDisconnectedForTest();
    await Future.delayed(const Duration(milliseconds: 10));

    expect(events, hasLength(1));
    await sub.cancel();
  });
}
