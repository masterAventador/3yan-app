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
import 'widget/typing_indicator.dart';
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
    _warmupRecorder();
  }

  /// 进聊天页后台跑一次 start+cancel，触发 iOS AAC codec 首次初始化。
  /// 之后 codec 被缓存，真正按住说话的启动时间能从 ~1s 降到百毫秒。
  /// 只在已有权限时预热，避免静默触发系统权限弹窗。
  Future<void> _warmupRecorder() async {
    if (!await _recorder.isPermissionGranted()) return;
    final started = await _recorder.start();
    if (started) {
      await _recorder.cancel();
    }
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
    // 权限已授予 → 直接开始录音。
    // 权限未授予 → 弹系统弹窗询问，弹窗会打断长按手势，此时不应该继续开始录音
    //             （否则用户手指早已离开按钮，录音会卡死），而是提示用户再次按住。
    if (!await _recorder.isPermissionGranted()) {
      final granted = await _recorder.requestPermission();
      if (!granted) {
        _showToast('需要麦克风权限才能发送语音');
      } else {
        _showToast('麦克风权限已获取，请再次按住说话');
      }
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
      appBar: AppBar(
        title: Text(
          conversation.characterName ?? '',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AuraColors.primary,
          ),
        ),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AuraColors.glassBlur,
              sigmaY: AuraColors.glassBlur,
            ),
            child: Container(color: AuraColors.surface.withValues(alpha: 0.6)),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: AuraColors.primary),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: AuraColors.primary),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFD4FBFB)),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: Obx(() {
                    if (c.isLoading.value && c.messages.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(color: AuraColors.primary),
                      );
                    }
                    final showTyping = c.isAiTyping.value;
                    final itemCount =
                        c.messages.length + (showTyping ? 1 : 0);
                    return ListView.builder(
                      controller: c.scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        if (showTyping && index == c.messages.length) {
                          return const TypingIndicator();
                        }
                        return MessageBubble(message: c.messages[index]);
                      },
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
