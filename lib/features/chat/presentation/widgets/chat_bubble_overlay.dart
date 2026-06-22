import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../product/presentation/cubit/user_activity_cubit.dart';
import '../../../product/presentation/cubit/user_activity_state.dart';

class ChatBubbleOverlay extends StatefulWidget {
  const ChatBubbleOverlay({Key? key}) : super(key: key);

  @override
  State<ChatBubbleOverlay> createState() => _ChatBubbleOverlayState();
}

class _ChatBubbleOverlayState extends State<ChatBubbleOverlay>
    with TickerProviderStateMixin {
  // Position
  Offset _position = Offset.zero;
  bool _initialized = false;

  // State
  bool _isDragging = false;
  bool _isDismissed = false;
  bool _isNearCloseZone = false;

  // Animation controllers
  late AnimationController _entryController;
  late AnimationController _pulseController;
  late AnimationController _closeZoneController;
  late AnimationController _dismissController;

  late Animation<double> _entryScale;
  late Animation<double> _pulseScale;
  late Animation<double> _closeZoneScale;
  late Animation<double> _dismissScale;
  late Animation<double> _dismissOpacity;

  @override
  void initState() {
    super.initState();

    // Entry animation
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _entryScale = CurvedAnimation(
      parent: _entryController,
      curve: Curves.elasticOut,
    );

    // Pulse animation (breathing effect)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Close zone appear animation
    _closeZoneController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _closeZoneScale = CurvedAnimation(
      parent: _closeZoneController,
      curve: Curves.easeOutBack,
    );

    // Dismiss animation
    _dismissController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _dismissScale = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _dismissController, curve: Curves.easeInBack),
    );
    _dismissOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _dismissController, curve: Curves.easeIn),
    );

    _entryController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final size = MediaQuery.of(context).size;
      // Initial position higher to avoid overlapping FAB, size shrunk to ~80%
      _position = Offset(size.width - 65, size.height - 290);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    _closeZoneController.dispose();
    _dismissController.dispose();
    super.dispose();
  }

  void _handleDismiss() async {
    if (_isDismissed || _dismissController.isAnimating) return;
    _pulseController.stop();
    _closeZoneController.reverse();
    await _dismissController.forward();
    if (mounted) {
      setState(() => _isDismissed = true);
    }
  }

  Rect _getCloseZoneRect(Size size) {
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height - 110),
      width: 72,
      height: 72,
    );
  }

  bool _isBubbleInCloseZone(Size size) {
    final bubbleCenter = Offset(_position.dx + 30, _position.dy + 30);
    return _getCloseZoneRect(size).inflate(20).contains(bubbleCenter);
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    final authState = context.watch<AuthCubit>().state;
    final showChatbot = authState is AuthAuthenticated;
    final userActivityState = context.watch<UserActivityCubit>().state;
    final showCompare = userActivityState.compareList.isNotEmpty;

    if (!showChatbot && !showCompare) return const SizedBox.shrink();

    final size = MediaQuery.of(context).size;
    final closeZoneRect = _getCloseZoneRect(size);

    return Stack(
      children: [
        // ─── Close Zone ─────────────────────────────────────────────
        if (_isDragging)
          Positioned(
            left: closeZoneRect.left,
            top: closeZoneRect.top,
            child: ScaleTransition(
              scale: _closeZoneScale,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: closeZoneRect.width,
                height: closeZoneRect.height,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isNearCloseZone
                      ? Colors.red.shade600
                      : Colors.red.shade400.withOpacity(0.85),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(_isNearCloseZone ? 0.6 : 0.3),
                      blurRadius: _isNearCloseZone ? 20 : 10,
                      spreadRadius: _isNearCloseZone ? 6 : 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: _isNearCloseZone ? 36 : 30,
                ),
              ),
            ),
          ),

        // ─── Ripple ring around close zone when near ────────────────
        if (_isDragging && _isNearCloseZone)
          Positioned(
            left: closeZoneRect.left - 16,
            top: closeZoneRect.top - 16,
            child: IgnorePointer(
              child: Container(
                width: closeZoneRect.width + 32,
                height: closeZoneRect.height + 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.withOpacity(0.4),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

        // ─── Bubble ─────────────────────────────────────────────────
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: ScaleTransition(
            scale: _entryScale,
            child: FadeTransition(
              opacity: _dismissOpacity,
              child: ScaleTransition(
                scale: _dismissScale,
                child: GestureDetector(
                  onPanStart: (_) {
                    _pulseController.stop();
                    _closeZoneController.forward();
                    setState(() => _isDragging = true);
                  },
                  onPanUpdate: (details) {
                    if (_isDismissed || _dismissController.isAnimating) return;
                    final newPos = _position + details.delta;
                    final isNear = _isBubbleInCloseZone(size);
                    if (isNear) {
                      _handleDismiss();
                    } else {
                      setState(() {
                        _position = newPos;
                        _isNearCloseZone = false;
                      });
                    }
                  },
                  onPanEnd: (_) {
                    if (_isNearCloseZone) {
                      _handleDismiss();
                      return;
                    }

                    _closeZoneController.reverse();
                    _pulseController.repeat(reverse: true);

                    final snapX = _position.dx < size.width / 2
                        ? 16.0
                        : size.width - 65.0;
                    double snapY = _position.dy.clamp(
                      MediaQuery.of(context).padding.top + 20,
                      size.height - kBottomNavigationBarHeight - 170,
                    );

                    setState(() {
                      _isDragging = false;
                      _isNearCloseZone = false;
                      _position = Offset(snapX, snapY);
                    });
                  },
                  onTap: () {
                    if (showChatbot) context.go('/chat', extra: 1);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (showCompare) ...[
                        GestureDetector(
                          onTap: () {
                            if (userActivityState.compareList.length == 2) {
                              context.push('/compare', extra: {
                                'product1': userActivityState.compareList[0],
                                'product2': userActivityState.compareList[1],
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select one more product to compare.')),
                              );
                            }
                          },
                          child: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: userActivityState.compareList.length == 2 
                                ? Theme.of(context).primaryColor 
                                : Colors.orange,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(Icons.compare_arrows, color: Colors.white, size: 20),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      userActivityState.compareList.length.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (showChatbot) const SizedBox(height: 12),
                      ],
                      if (showChatbot)
                        AnimatedBuilder(
                          animation: Listenable.merge([_pulseScale]),
                          builder: (context, child) {
                            final scale = _isDragging ? 1.12 : _pulseScale.value;
                            return Transform.scale(
                              scale: scale,
                              child: child,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: _isNearCloseZone
                                    ? [Colors.red.shade400, Colors.red.shade700]
                                    : [
                                        const Color(0xFF667EEA),
                                        const Color(0xFF764BA2),
                                      ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isNearCloseZone
                                          ? Colors.red
                                          : const Color(0xFF667EEA))
                                      .withOpacity(_isDragging ? 0.6 : 0.4),
                                  blurRadius: _isDragging ? 20 : 12,
                                  spreadRadius: _isDragging ? 4 : 0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _isNearCloseZone
                                  ? const Icon(Icons.delete_outline_rounded,
                                      key: ValueKey('delete'),
                                      color: Colors.white,
                                      size: 20)
                                  : const Icon(Icons.smart_toy_rounded,
                                      key: ValueKey('bot'),
                                      color: Colors.white,
                                      size: 20),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
