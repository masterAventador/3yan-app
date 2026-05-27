import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';
import 'chat_controller.dart';
import 'widget/chat_input_bar.dart';
import 'widget/message_bubble.dart';
import 'widget/typing_indicator.dart';
import 'widgets/chat_settings_drawer.dart';
import 'widgets/intimacy_progress_bar.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatController c;

  /// 左侧设置抽屉的开关控制器（UI 状态，随页面生命周期创建/释放）。
  final _drawerController = SlideDrawerController();

  @override
  void initState() {
    super.initState();
    c = Get.put(ChatController());
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideDrawerScaffold(
      controller: _drawerController,
      // TODO: 各设置项功能后续逐个接入，当前占位为点击后收起抽屉
      drawer: ChatSettingsDrawer(
        onProfile: _drawerController.close,
        onSubscribe: _drawerController.close,
        onProactiveSettings: _drawerController.close,
        onNotificationSettings: _drawerController.close,
        onAbout: _drawerController.close,
        onLogout: _drawerController.close,
      ),
      body: Scaffold(
        backgroundColor: AuraColors.surface,
        appBar: AppBar(
          title: const Text(
            '小婉',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AuraColors.primary,
            ),
          ),
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: AuraColors.glassBlur, sigmaY: AuraColors.glassBlur),
              child: Container(color: AuraColors.surface.withValues(alpha: 0.6)),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: AuraColors.primary),
              onPressed: _drawerController.toggle,
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFD4FBFB)),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Obx(() {
                final rel = c.relationship.value;
                if (rel == null) return const SizedBox.shrink();
                return IntimacyProgressBar(
                  relationship: rel,
                  onTap: () {/* 暂时不做详情弹窗，后续补 */},
                );
              }),
              Expanded(
                child: Obx(() {
                  if (c.isLoading.value && c.messages.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: AuraColors.primary),
                    );
                  }
                  final showTyping = c.isAiTyping.value;
                  final itemCount = c.messages.length + (showTyping ? 1 : 0);
                  return ListView.builder(
                    controller: c.scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (showTyping && index == c.messages.length) {
                        return const TypingIndicator();
                      }
                      return MessageBubble(
                        message: c.messages[index],
                        onRetry: () => c.retryMessage(c.messages[index]),
                      );
                    },
                  );
                }),
              ),
              ChatInputBar(controller: c.inputController, onSend: c.sendMessage),
            ],
          ),
        ),
      ),
    );
  }
}
