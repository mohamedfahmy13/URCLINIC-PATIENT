import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:nb_utils/nb_utils.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../components/app_scaffold.dart';
import '../../../main.dart';
import '../../../utils/colors.dart';

String get _geminiApiKey =>
    dotenv.env['GEMINI_API_KEY'] ??
    const String.fromEnvironment('GEMINI_API_KEY');

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final RxList<ChatMessage> _messages = <ChatMessage>[].obs;
  final RxBool _isTyping = false.obs;
  final RxBool _showSuggestions = true.obs;

  static const _modelCandidates = [
    'gemini-3.8-flash',
    'gemini-3.5-flash',
    'gemini-flash-lite-latest',
  ];

  List<String> get _suggestionChips => [
        locale.value.aiChatSuggestion1,
        locale.value.aiChatSuggestion2,
        locale.value.aiChatSuggestion3,
        locale.value.aiChatSuggestion4,
      ];

  GenerativeModel? _model;
  ChatSession? _chat;
  int _currentModelIndex = 0;
  final Rxn<String> _lastFailedMessage = Rxn<String>();

  @override
  void initState() {
    super.initState();
    if (_geminiApiKey.isNotEmpty) {
      _initModel(_currentModelIndex);
    }
    _messages.add(ChatMessage(
      text: locale.value.aiChatWelcomeMessage,
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  void _initModel(int index) {
    _currentModelIndex = index;
    _model = GenerativeModel(
      model: _modelCandidates[index],
      apiKey: _geminiApiKey,
      systemInstruction: Content.system(locale.value.aiChatSystemPrompt),
    );
    _chat = _model!.startChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<String> _sendWithFallback(String text) async {
    for (var i = _currentModelIndex; i < _modelCandidates.length; i++) {
      if (i != _currentModelIndex) _initModel(i);
      try {
        final response = await _chat!.sendMessage(Content.text(text));
        return response.text ?? locale.value.aiChatGenericError;
      } catch (e) {
        final lower = e.toString().toLowerCase();
        final isModelError = lower.contains('not found') ||
            lower.contains('404') ||
            lower.contains('not supported') ||
            lower.contains('deprecated');
        if (!isModelError || i == _modelCandidates.length - 1) rethrow;
      }
    }
    throw Exception('All models failed');
  }

  void _clearChat() {
    _messages.clear();
    _showSuggestions.value = true;
    _lastFailedMessage.value = null;
    if (_geminiApiKey.isNotEmpty) {
      _initModel(0);
    }
    _messages.add(ChatMessage(
      text: locale.value.aiChatWelcomeMessage,
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _sendMessage({String? overrideText}) async {
    final text = overrideText ?? _messageController.text.trim();
    if (text.isEmpty || _isTyping.value) return;

    _lastFailedMessage.value = null;

    if (_geminiApiKey.isEmpty) {
      _messages.add(ChatMessage(
        text: locale.value.aiChatMissingApiKey,
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      ));
      _scrollToBottom();
      return;
    }

    if (!await isNetworkAvailable()) {
      _messages.add(ChatMessage(
        text: locale.value.aiChatNoInternet,
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      ));
      _lastFailedMessage.value = text;
      _scrollToBottom();
      return;
    }

    _showSuggestions.value = false;
    _messages.add(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _messageController.clear();
    _scrollToBottom();

    _isTyping.value = true;

    try {
      final response = await _sendWithFallback(text);
      _messages.add(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('AI Chat Error: $e');
      _lastFailedMessage.value = text;

      final lowerError = e.toString().toLowerCase();
      final String errorMessage;

      if (lowerError.contains('api key') ||
          lowerError.contains('unauthorized') ||
          lowerError.contains('permission denied') ||
          lowerError.contains('403')) {
        errorMessage = locale.value.aiChatKeyPermissionError;
      } else if (lowerError.contains('socket') ||
          lowerError.contains('timeout') ||
          lowerError.contains('network')) {
        errorMessage = locale.value.aiChatNetworkError;
      } else {
        errorMessage = locale.value.aiChatGenericError;
      }

      _messages.add(ChatMessage(
        text: errorMessage,
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      ));
    } finally {
      _isTyping.value = false;
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      appBartitleText: locale.value.aiChatTitle,
      scaffoldBackgroundColor: context.scaffoldBackgroundColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 22),
          tooltip: locale.value.clearAll,
          onPressed: _clearChat,
        ),
      ],
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Obx(
              () => _messages.length <= 1 && _showSuggestions.value
                  ? _buildWelcomeView()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _MessageBubbleAnimated(
                          key: ValueKey(_messages[index]
                              .timestamp
                              .millisecondsSinceEpoch),
                          child: _buildMessageBubble(_messages[index]),
                        );
                      },
                    ),
            ),
          ),

          // Typing indicator
          Obx(
            () => _isTyping.value
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: boxDecorationDefault(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _TypingDot(delay: 0),
                          6.width,
                          _TypingDot(delay: 200),
                          6.width,
                          _TypingDot(delay: 400),
                          12.width,
                          Text(locale.value.aiChatTyping,
                              style: secondaryTextStyle(size: 12)),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Retry button
          Obx(
            () => _lastFailedMessage.value != null && !_isTyping.value
                ? Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final msg = _lastFailedMessage.value!;
                        _lastFailedMessage.value = null;
                        _sendMessage(overrideText: msg);
                      },
                      icon: const Icon(Icons.replay_rounded, size: 18),
                      label: Text(locale.value.reload),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: appColorPrimary,
                        side:
                            BorderSide(color: appColorPrimary.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Suggestion chips
          Obx(
            () => _showSuggestions.value && !_isTyping.value
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _suggestionChips.length,
                      separatorBuilder: (_, __) => 8.width,
                      itemBuilder: (context, index) {
                        return ActionChip(
                          label: Text(_suggestionChips[index],
                              style: secondaryTextStyle(
                                  size: 12, color: appColorPrimary)),
                          backgroundColor: appColorPrimary.withOpacity(0.08),
                          side: BorderSide(
                              color: appColorPrimary.withOpacity(0.2)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          onPressed: () => _sendMessage(
                              overrideText: _suggestionChips[index]),
                        );
                      },
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Input field
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
              color: context.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: locale.value.aiChatHint,
                        hintStyle: secondaryTextStyle(),
                        filled: true,
                        fillColor: context.scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  10.width,
                  Obx(
                    () => GestureDetector(
                      onTap: _isTyping.value ? null : () => _sendMessage(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: boxDecorationDefault(
                          color: _isTyping.value
                              ? appColorPrimary.withOpacity(0.5)
                              : appColorPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: boxDecorationDefault(
              color: appColorPrimary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.smart_toy_rounded, color: appColorPrimary, size: 48),
          ),
          20.height,
          Text(
            locale.value.aiChatTitle,
            style: boldTextStyle(size: 20),
          ),
          8.height,
          Text(
            locale.value.aiChatWelcomeMessage,
            style: secondaryTextStyle(size: 14),
            textAlign: TextAlign.center,
          ),
          32.height,
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _suggestionChips
                .map((chip) => ActionChip(
                      label: Text(chip, style: primaryTextStyle(size: 13)),
                      backgroundColor: appColorPrimary,
                      side:
                          BorderSide(color: appColorPrimary.withOpacity(0.15)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      onPressed: () => _sendMessage(overrideText: chip),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: boxDecorationDefault(
                color: message.isError
                    ? Colors.red.withOpacity(0.1)
                    : appColorPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                message.isError ? Icons.error_outline : Icons.smart_toy_rounded,
                color: message.isError ? Colors.red : appColorPrimary,
                size: 20,
              ),
            ),
            8.width,
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: message.text));
                toast(locale.value.aiChatCopiedMessage);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: boxDecorationDefault(
                  color: message.isError
                      ? Colors.red.withOpacity(0.08)
                      : message.isUser
                          ? appColorPrimary
                          : context.cardColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                    bottomRight: Radius.circular(message.isUser ? 4 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      message.text,
                      style: primaryTextStyle(
                        color: message.isError
                            ? Colors.red.shade700
                            : message.isUser
                                ? Colors.white
                                : null,
                        size: 14,
                      ),
                    ),
                    6.height,
                    Text(
                      _formatTime(message.timestamp),
                      style: secondaryTextStyle(
                        color: message.isUser
                            ? Colors.white70
                            : message.isError
                                ? Colors.red.shade300
                                : null,
                        size: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            8.width,
            Container(
              padding: const EdgeInsets.all(8),
              decoration: boxDecorationDefault(
                color: appColorPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_rounded,
                color: appColorPrimary,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// Slide + fade animation for each new message bubble.
class _MessageBubbleAnimated extends StatefulWidget {
  final Widget child;
  const _MessageBubbleAnimated({super.key, required this.child});

  @override
  State<_MessageBubbleAnimated> createState() => _MessageBubbleAnimatedState();
}

class _MessageBubbleAnimatedState extends State<_MessageBubbleAnimated>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Animated typing dot
class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: appColorPrimary.withOpacity(_animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}
