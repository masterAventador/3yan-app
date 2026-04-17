import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // 插件注册完再设置 AVAudioSession，覆盖 audioplayers 默认的 .playback；
    // 手动 setActive(true) 一次，让 record 包可以用 manageAudioSession=false 跳过重复 init。
    // 这样用户长按说话是毫秒级响应，不用再等 session 激活 1-2 秒。
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(
        .playAndRecord,
        options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
      try session.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      NSLog("[AppDelegate] AVAudioSession setup failed: \(error)")
    }
  }
}
