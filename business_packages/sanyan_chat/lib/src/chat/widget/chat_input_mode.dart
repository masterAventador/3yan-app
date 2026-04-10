enum ChatInputMode {
  keyboard,
  voice;

  String get storageValue => name;

  static ChatInputMode fromStorage(String? value) {
    if (value == ChatInputMode.voice.name) return ChatInputMode.voice;
    return ChatInputMode.keyboard;
  }
}
