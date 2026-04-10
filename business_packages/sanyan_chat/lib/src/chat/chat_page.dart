import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';
import 'package:sanyan_user/sanyan_user.dart';
import '../models/conversation.dart';
import 'chat_controller.dart';
import 'voice_recorder.dart';
import 'widget/chat_input_bar.dart';
import 'widget/chat_input_mode.dart';
import 'widget/message_bubble.dart';
import 'widget/voice_record_overlay.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final Conversation conversation;
  late final ChatController c;
  late ChatInputMode _mode;
  final VoiceRecorder _recorder = VoiceRecorder();
  bool _isRecording = false;
  bool _isCancelling = false;
  Offset? _recordStartPosition;

  @override
  void initState() {
    super.initState();
    conversation = Get.arguments as Conversation;
    c = Get.put(ChatController(conversation));
    _mode = ChatInputMode.fromStorage(LocalStorage.lastInputMode);
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _mode = _mode == ChatInputMode.keyboard
          ? ChatInputMode.voice
          : ChatInputMode.keyboard;
      LocalStorage.lastInputMode = _mode.storageValue;
    });
  }

  Future<void> _onRecordStart(Offset globalPosition) async {
    final granted = await _recorder.ensurePermission();
    if (!granted) {
      _showToast('需要麦克风权限才能发送语音');
      return;
    }

    final started = await _recorder.start(onMaxDurationReached: () {
      if (_isRecording) _onRecordEnd();
    });
    if (!started) {
      _showToast('录音启动失败');
      return;
    }
    setState(() {
      _isRecording = true;
      _isCancelling = false;
      _recordStartPosition = globalPosition;
    });
  }

  void _onRecordMove(Offset globalPosition) {
    if (!_isRecording || _recordStartPosition == null) return;
    final dy = _recordStartPosition!.dy - globalPosition.dy;
    final cancelling = dy > 80;
    if (cancelling != _isCancelling) {
      setState(() {
        _isCancelling = cancelling;
      });
    }
  }

  Future<void> _onRecordEnd() async {
    if (!_isRecording) return;

    final cancelling = _isCancelling;
    setState(() {
      _isRecording = false;
      _isCancelling = false;
      _recordStartPosition = null;
    });

    if (cancelling) {
      await _recorder.cancel();
      return;
    }

    final result = await _recorder.stop();
    if (result == null) {
      _showToast('说话时间太短');
      return;
    }

    c.sendVoiceMessage(result.filePath, result.durationSeconds);
  }

  Future<void> _onRecordCancel() async {
    if (!_isRecording) return;
    setState(() {
      _isRecording = false;
      _isCancelling = false;
      _recordStartPosition = null;
    });
    await _recorder.cancel();
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.surface,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _TopBar(conversation: conversation),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFD4FBFB),
                ),
                Expanded(
                  child: Obx(() {
                    if (c.isLoading.value && c.messages.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(color: AuraColors.primary),
                      );
                    }
                    return ListView.builder(
                      controller: c.scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: c.messages.length,
                      itemBuilder: (context, index) =>
                          MessageBubble(message: c.messages[index]),
                    );
                  }),
                ),
                ChatInputBar(
                  controller: c.inputController,
                  mode: _mode,
                  onToggleMode: _toggleMode,
                  onSendText: c.sendMessage,
                  isRecording: _isRecording,
                  onRecordStart: _onRecordStart,
                  onRecordMove: _onRecordMove,
                  onRecordEnd: _onRecordEnd,
                  onRecordCancel: _onRecordCancel,
                ),
              ],
            ),
          ),
          if (_isRecording)
            VoiceRecordOverlay(isCancelling: _isCancelling),
        ],
      ),
    );
  }
}

// ─── Frosted glass top bar ────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final Conversation conversation;
  const _TopBar({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AuraColors.glassBlur,
          sigmaY: AuraColors.glassBlur,
        ),
        child: Container(
          color: AuraColors.surface.withValues(alpha: 0.6),
          padding: EdgeInsets.only(
            top: topPadding + 8,
            bottom: 12,
            left: 4,
            right: 8,
          ),
          child: Row(
            children: [
              // Back arrow
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back, color: AuraColors.primary),
                iconSize: 24,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),

              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AuraColors.mintAzureGradient,
                  border: Border.all(
                    color: AuraColors.primaryFixed,
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.favorite, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),

              // Name + online status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      conversation.characterName ?? '',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AuraColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ONLINE',
                          style: TextStyle(
                            fontFamily: AuraFonts.inter,
                            fontSize: 10,
                            letterSpacing: 0.8,
                            color: AuraColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search icon
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search, color: AuraColors.primary),
                iconSize: 22,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),

              // More icon
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert, color: AuraColors.primary),
                iconSize: 22,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
