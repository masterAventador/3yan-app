import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_network/sanyan_network.dart';

void main() {
  test('reconnect delay sequence: 1, 2, 5, 10, 30, 30, 30...', () {
    expect(WsClient.reconnectDelayForAttempt(0), const Duration(seconds: 1));
    expect(WsClient.reconnectDelayForAttempt(1), const Duration(seconds: 2));
    expect(WsClient.reconnectDelayForAttempt(2), const Duration(seconds: 5));
    expect(WsClient.reconnectDelayForAttempt(3), const Duration(seconds: 10));
    expect(WsClient.reconnectDelayForAttempt(4), const Duration(seconds: 30));
    expect(WsClient.reconnectDelayForAttempt(5), const Duration(seconds: 30));
    expect(WsClient.reconnectDelayForAttempt(99), const Duration(seconds: 30));
  });
}
