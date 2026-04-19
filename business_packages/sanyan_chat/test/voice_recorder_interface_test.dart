import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_chat/sanyan_chat.dart';

void main() {
  test('VoiceRecorder implements IVoiceRecorder', () {
    final r = VoiceRecorder();
    expect(r, isA<IVoiceRecorder>());
  });
}
