import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../../../features/auth/presentation/cubit/auth_state.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../cubit/ai_chat_cubit.dart';
import '../cubit/ai_chat_state.dart';
import '../widgets/product_message_bubble.dart';

class CustomerChatScreen extends StatefulWidget {
  final int initialIndex;
  const CustomerChatScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _adminTextController = TextEditingController();
  final TextEditingController _aiTextController = TextEditingController();
  final ScrollController _aiScrollController = ScrollController();
  final ScrollController _adminScrollController = ScrollController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<ChatCubit>().loadMessages(authState.user.uid);
      context.read<ChatCubit>().markCustomerRead(authState.user.uid);
      context.read<AiChatCubit>().initializeChat(authState.user.fullName);
    }
  }

  @override
  void dispose() {
    _adminTextController.dispose();
    _aiTextController.dispose();
    _aiScrollController.dispose();
    _adminScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _sendAdminMessage() {
    final text = _adminTextController.text.trim();
    if (text.isEmpty) return;
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<ChatCubit>().sendMessage(
            customerId: authState.user.uid,
            customerName: authState.user.fullName,
            customerEmail: authState.user.email,
            text: text,
            senderId: authState.user.uid,
            senderName: authState.user.fullName,
            isAdmin: false,
          );
      _adminTextController.clear();
    }
  }

  void _sendAiMessage() {
    final text = _aiTextController.text.trim();
    if (text.isEmpty) return;
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<AiChatCubit>().sendMessage(
            customerId: authState.user.uid,
            customerName: authState.user.fullName,
            text: text,
          );
      _aiTextController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF0F2FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                  : [const Color(0xFF667EEA), const Color(0xFF764BA2)],
            ),
          ),
        ),
        title: const Text(
          'Tư vấn & Chăm sóc',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.support_agent_rounded, size: 18),
                  SizedBox(width: 6),
                  Text('Admin', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.smart_toy_rounded, size: 18),
                  SizedBox(width: 6),
                  Text('Trợ lý AI', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAdminChatView(isDark),
          _buildAiChatView(isDark),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Admin Chat View
  // ─────────────────────────────────────────────────────────────────
  Widget _buildAdminChatView(bool isDark) {
    return Column(
      children: [
        Expanded(
          child: BlocBuilder<ChatCubit, ChatState>(
            builder: (context, state) {
              if (state is ChatLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ChatError) {
                return Center(child: Text(state.message));
              }
              if (state is ChatMessagesLoaded) {
                final messages = state.messages;
                if (messages.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.support_agent_rounded,
                    title: 'Chưa có tin nhắn nào',
                    subtitle: 'Gửi tin nhắn để kết nối với Admin',
                    isDark: isDark,
                  );
                }
                return ListView.builder(
                  controller: _adminScrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[messages.length - 1 - index];
                    return _buildAdminBubble(msg, isDark);
                  },
                );
              }
              return _buildEmptyState(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Bắt đầu chat',
                subtitle: 'Admin sẽ phản hồi sớm nhất có thể',
                isDark: isDark,
              );
            },
          ),
        ),
        _buildInputBar(
          controller: _adminTextController,
          hint: 'Nhắn tin cho Admin...',
          onSend: _sendAdminMessage,
          isDark: isDark,
          gradientColors: isDark
              ? [const Color(0xFF2D3561), const Color(0xFF1A1A2E)]
              : [Colors.white, const Color(0xFFF0F2FF)],
          sendColor: const Color(0xFF667EEA),
        ),
      ],
    );
  }

  Widget _buildAdminBubble(dynamic msg, bool isDark) {
    final isMe = !msg.isAdmin;
    String timeStr = '';
    if (msg.timestamp != null) {
      timeStr = DateFormat('HH:mm').format(msg.timestamp!.toDate());
    }
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(isMe ? (1 - value) * 30 : (value - 1) * 30, 0),
          child: child,
        ),
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            left: isMe ? 60 : 12,
            right: isMe ? 12 : 60,
            top: 4,
            bottom: 4,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: isMe
                ? const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isMe ? null : (isDark ? const Color(0xFF1E1E30) : Colors.white),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF667EEA),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Admin',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: isDark ? Colors.white60 : const Color(0xFF667EEA),
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                msg.text,
                style: TextStyle(
                  color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                  fontSize: 14.5,
                  height: 1.4,
                ),
              ),
              if (msg.productPayload != null)
                ProductMessageBubble(productPayload: msg.productPayload!, isMe: isMe),
              const SizedBox(height: 3),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white54 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // AI Chat View
  // ─────────────────────────────────────────────────────────────────
  Widget _buildAiChatView(bool isDark) {
    return Column(
      children: [
        // AI Banner
        Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E1E35), const Color(0xFF252540)]
                  : [const Color(0xFFEEF2FF), const Color(0xFFF5F0FF)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF667EEA).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trợ lý ảo Shoes X',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Tư vấn dựa trên dữ liệu thực từ cửa hàng',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Online',
                style: TextStyle(fontSize: 11, color: Colors.green.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        Expanded(
          child: BlocBuilder<AiChatCubit, AiChatState>(
            builder: (context, state) {
              final messages = state.messages;

              if (messages.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.smart_toy_rounded,
                  title: 'Trợ lý ảo Shoes X',
                  subtitle: 'Đang khởi tạo trò chuyện...',
                  isDark: isDark,
                  showLoader: true,
                );
              }

              return ListView.builder(
                controller: _aiScrollController,
                reverse: true,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                itemCount: messages.length + (state.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  // Typing indicator
                  if (state.isLoading && index == 0) {
                    return _buildTypingIndicator(isDark);
                  }
                  final msgIndex = state.isLoading ? index - 1 : index;
                  final msg = messages[messages.length - 1 - msgIndex];
                  return _buildAiBubble(msg, isDark);
                },
              );
            },
          ),
        ),

        // Quick suggestions
        _buildQuickSuggestions(isDark),

        _buildInputBar(
          controller: _aiTextController,
          hint: 'Hỏi về sản phẩm, chi nhánh...',
          onSend: _sendAiMessage,
          isDark: isDark,
          gradientColors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF0F0F1A)]
              : [Colors.white, const Color(0xFFF0F2FF)],
          sendColor: const Color(0xFF764BA2),
        ),
      ],
    );
  }

  Widget _buildAiBubble(dynamic msg, bool isDark) {
    final isMe = !msg.isAdmin;
    String timeStr = '';
    if (msg.timestamp != null) {
      timeStr = DateFormat('HH:mm').format(msg.timestamp!.toDate());
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 350),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 15),
          child: child,
        ),
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 8, bottom: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.smart_toy_rounded,
                    color: Colors.white, size: 18),
              ),
            ],
            Flexible(
              child: Container(
                margin: EdgeInsets.only(
                  left: isMe ? 60 : 0,
                  right: isMe ? 0 : 60,
                  top: 3,
                  bottom: 3,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isMe
                      ? null
                      : (isDark ? const Color(0xFF1E1E30) : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isMe
                          ? const Color(0xFF667EEA).withOpacity(0.3)
                          : Colors.black.withOpacity(0.06),
                      blurRadius: isMe ? 12 : 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      msg.text,
                      style: TextStyle(
                        color: isMe
                            ? Colors.white
                            : (isDark ? const Color(0xDEFFFFFF) : Colors.black87),
                        fontSize: 14.5,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe ? Colors.white54 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(left: 12, right: 8, bottom: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 18),
          ),
          Container(
            margin: const EdgeInsets.only(top: 3, bottom: 3),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E30) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _TypingDots(isDark: isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions(bool isDark) {
    final suggestions = ['Giày Nike', 'Giày Adidas', 'Size 42', 'Chi nhánh'];
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: suggestions.length,
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () {
              _aiTextController.text = suggestions[i];
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF667EEA).withOpacity(0.15)
                    : const Color(0xFF667EEA).withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF667EEA).withOpacity(0.3),
                ),
              ),
              child: Text(
                suggestions[i],
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF667EEA),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar({
    required TextEditingController controller,
    required String hint,
    required VoidCallback onSend,
    required bool isDark,
    required List<Color> gradientColors,
    required Color sendColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1E35)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: sendColor.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: sendColor.withOpacity(0.05),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: controller,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => onSend(),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onSend,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [sendColor.withOpacity(0.9), sendColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: sendColor.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    bool showLoader = false,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          if (showLoader) ...[
            const SizedBox(height: 16),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


// ─── Typing Dots Animation ────────────────────────────────────────────────────
class _TypingDots extends StatefulWidget {
  final bool isDark;
  const _TypingDots({required this.isDark});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final t = (_controller.value - delay).clamp(0.0, 1.0);
            final bounce = (t < 0.5 ? t * 2 : (1 - t) * 2);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withOpacity(0.5 + bounce * 0.5),
                shape: BoxShape.circle,
              ),
              transform: Matrix4.translationValues(0, -bounce * 6, 0),
            );
          }),
        );
      },
    );
  }
}
