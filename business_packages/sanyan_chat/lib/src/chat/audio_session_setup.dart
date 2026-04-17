import 'package:audioplayers/audioplayers.dart';

/// App 启动时调一次：把全局 AVAudioSession 默认 category 设成 playAndRecord。
///
/// 背景：audioplayers 在 iOS 插件注册时会立即把 AVAudioSession 设成 .playback
/// 分类（默认值），导致后续 record 包在 AAC 编码器初始化时失败
/// （"AudioCodecInitialize failed"），录音文件只有容器 header、没有采样数据。
///
/// 把默认 category 提升到 playAndRecord 能同时支持播放和录音，彻底消除冲突。
Future<void> initAudioSession() async {
  await AudioPlayer.global.setAudioContext(
    AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playAndRecord,
        options: const {
          AVAudioSessionOptions.defaultToSpeaker,
          AVAudioSessionOptions.allowBluetooth,
          AVAudioSessionOptions.allowBluetoothA2DP,
        },
      ),
      android: const AudioContextAndroid(),
    ),
  );
}
