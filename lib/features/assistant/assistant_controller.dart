import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hydronova_mobile/features/assistant/assistant_service.dart';
import 'package:hydronova_mobile/features/assistant/chat_message.dart';
import 'package:hydronova_mobile/features/assistant/session_id.dart';

class AssistantController extends GetxController {
  final AssistantService _service = AssistantService();

  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isSending = false.obs;
  final TextEditingController inputController = TextEditingController();
  final RxString inputText = ''.obs;

  @override
  void onInit() {
    super.onInit();
    inputController.addListener(() {
      inputText.value = inputController.text;
    });
  }

  Future<void> sendMessage() async {
    if (isSending.value) return;
    final raw = inputController.text.trim();
    if (raw.isEmpty) return;
    if (raw.length > 2000) {
      Get.snackbar(
        'Message too long',
        'Please keep messages under 2000 characters.',
      );
      return;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    messages.add(
      ChatMessage(
        role: ChatRole.user,
        text: raw,
        timestampMs: nowMs,
      ),
    );
    inputController.clear();

    isSending.value = true;
    try {
      final sessionId = await SessionId.getOrCreate();
      final reply = await _service.sendMessage(
        message: raw,
        sessionId: sessionId,
      );
      if (reply == null || reply.trim().isEmpty) {
        messages.add(
          ChatMessage(
            role: ChatRole.assistant,
            text: 'I couldn\'t parse the response.',
            timestampMs: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        return;
      }
      messages.add(
        ChatMessage(
          role: ChatRole.assistant,
          text: reply,
          timestampMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar('Assistant Error', message);
    } finally {
      isSending.value = false;
    }
  }

  @override
  void onClose() {
    inputController.dispose();
    super.onClose();
  }
}
