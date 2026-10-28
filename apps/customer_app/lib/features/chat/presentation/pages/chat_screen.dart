import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';

/// Halaman Chat strictly based on Figma nodes [44:4665], [44:9043], and [44:9139]:
/// - chat.png: Chat Inbox / Conversation list with driver card
/// - chat-1.png: Direct message conversation room with driver
/// - TELEPON.png & TELEPON angkat.png: Full-screen calling overlay
class ChatScreen extends StatefulWidget {
  final bool showBackButton;
  final bool initialShowDetail;

  const ChatScreen({
    super.key,
    this.showBackButton = false,
    this.initialShowDetail = true,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late bool _showDetail;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'driver',
      'text': 'Halo bu, saya sudah sampai di Pasar Sukaramai ya. Mulai carikan daging sapi.',
      'time': '10.11',
    },
    {
      'sender': 'driver',
      'text': 'Sekalian, cabai merahnya juga mau yang keriting atau biasa?',
      'time': '10.11',
    },
    {
      'sender': 'user',
      'text': 'Boleh mas, sekalian aja',
      'time': '10.11',
    },
    {
      'sender': 'driver',
      'text': 'Baik bukk',
      'time': '10.11',
    },
    {
      'sender': 'user',
      'text': 'Terima kasih banyak',
      'time': '10.11',
    },
    {
      'sender': 'driver',
      'text': 'Segera meluncur ya mas',
      'time': '10.11',
    },
    {
      'sender': 'driver',
      'text': 'Ditunggu ya buk',
      'time': '10.11',
    },
  ];

  final List<String> _quickReplies = [
    'Boleh mas, sekalian aja',
    'Makasih ya mas',
    'Segera meluncur ya mas',
  ];

  @override
  void initState() {
    super.initState();
    _showDetail = widget.initialShowDetail || widget.showBackButton;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? customText]) {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'sender': 'user',
        'text': text,
        'time': '10.12',
      });
      _messageController.clear();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showCallModal() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'VoiceCall',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim1, anim2) {
        return const _VoiceCallOverlay();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_showDetail) {
      return _buildInboxView();
    }
    return _buildDetailView();
  }

  // ---------------------------------------------------------------------------
  // 1. Chat Inbox View (figma/HalamanChat/chat.png)
  // ---------------------------------------------------------------------------
  Widget _buildInboxView() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Purple gradient top header with white RideOn logo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 48, bottom: 20),
            decoration: const BoxDecoration(
              gradient: AppColors.splashGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Center(
              child: Image.asset(
                AppAssets.logoWhite,
                height: 38,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Inbox List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildConversationCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.7),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              _showDetail = true;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                // Driver Avatar with 4.9 rating badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 1.5),
                        image: const DecorationImage(
                          image: AssetImage(AppAssets.driverPikri),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -4,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: Color(0xFFF1C40F),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '4.9',
                              style: GoogleFonts.roboto(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.dark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Name, License Plate, and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pikri Haykal',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF17152B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF17152B),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'BG 4563 R',
                              style: GoogleFonts.roboto(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Honda Vario 160 Hitam',
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Chevron arrow
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: Color(0xFF17152B),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Chat Detail Room View (figma/HalamanChat/chat-1.png)
  // ---------------------------------------------------------------------------
  Widget _buildDetailView() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildDetailHeader(),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              children: [
                // 'Hari Ini' Date Pill
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B48FC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Hari Ini',
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Messages list
                ..._messages.map(_buildMessageBubble),
              ],
            ),
          ),

          // Quick replies
          _buildQuickRepliesBar(),

          // Message input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildDetailHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 48, bottom: 16, left: 16, right: 16),
      decoration: const BoxDecoration(
        gradient: AppColors.splashGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              if (widget.showBackButton) {
                Navigator.of(context).pop();
              } else {
                setState(() {
                  _showDetail = false;
                });
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Driver Avatar with Online Indicator
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage(AppAssets.driverPikri),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF27AE60),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Name and Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 0,
                  height: 0,
                  child: Text(
                    'Pikri Haykal',
                    style: TextStyle(fontSize: 0, color: Colors.transparent),
                  ),
                ),
                Text(
                  'Fikri haykal (Driver)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Honda Vario 160 Hitam • BG 4563 R',
                  style: GoogleFonts.roboto(
                    fontSize: 10.5,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                Text(
                  'Online ( Sedang di Toko )',
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          // Voice Call Green Button (Figma TELEPON prototype trigger)
          GestureDetector(
            onTap: _showCallModal,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF27AE60),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF27AE60).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.call_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isUser = msg['sender'] == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF6B48FC) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: AppColors.divider.withValues(alpha: 0.8),
                  width: 1,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg['text'] as String,
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: isUser ? Colors.white : const Color(0xFF17152B),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg['time'] as String,
              style: GoogleFonts.roboto(
                fontSize: 9.5,
                color: isUser
                    ? Colors.white.withValues(alpha: 0.75)
                    : const Color(0xFF6B48FC).withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRepliesBar() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickReplies.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final reply = _quickReplies[index];
          return ActionChip(
            label: Text(
              reply,
              style: GoogleFonts.roboto(
                fontSize: 11,
                color: const Color(0xFF6B48FC),
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFFEDE8FF),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onPressed: () => _sendMessage(reply),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: AppColors.divider.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F6FB),
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(
                    color: AppColors.divider.withValues(alpha: 0.7),
                    width: 0.8,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: const Color(0xFF17152B),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ketik pesan untuk driver...',
                    hintStyle: GoogleFonts.roboto(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendMessage(),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF6B48FC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. Full-Screen Voice Call Overlay (TELEPON.png & TELEPON angkat.png)
// -----------------------------------------------------------------------------
class _VoiceCallOverlay extends StatefulWidget {
  const _VoiceCallOverlay();

  @override
  State<_VoiceCallOverlay> createState() => _VoiceCallOverlayState();
}

class _VoiceCallOverlayState extends State<_VoiceCallOverlay> {
  bool _isConnected = false;
  int _secondsElapsed = 0;
  Timer? _timer;
  bool _isMuted = false;
  bool _isSpeaker = false;

  @override
  void initState() {
    super.initState();
    // Simulate connection after 2 seconds (matching TELEPON -> TELEPON angkat)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isConnected = true;
          _secondsElapsed = 92; // 01:32 matching Figma TELEPON angkat
        });
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _secondsElapsed++;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dark blur backdrop filter
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: const Color(0xD917152B),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Bar: Back button, Driver Name, Call Status / Timer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Fikri haykal (Driver)',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isConnected ? _formatDuration(_secondsElapsed) : 'Berdering...',
                              style: GoogleFonts.roboto(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 36),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Center Circular Driver Avatar with white border (Figma TELEPON.png)
                Center(
                  child: Container(
                    width: 154,
                    height: 154,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      image: const DecorationImage(
                        image: AssetImage(AppAssets.driverPikriHq),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // Bottom Floating Pill Dock with 3 buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C273E).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Speaker Toggle
                        GestureDetector(
                          onTap: () => setState(() => _isSpeaker = !_isSpeaker),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: _isSpeaker
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isSpeaker
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_down_rounded,
                              color: _isSpeaker ? const Color(0xFF17152B) : Colors.white,
                              size: 24,
                            ),
                          ),
                        ),

                        // Mic / Mute Toggle
                        GestureDetector(
                          onTap: () => setState(() => _isMuted = !_isMuted),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: _isMuted
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isMuted
                                  ? Icons.mic_off_rounded
                                  : Icons.mic_rounded,
                              color: _isMuted ? const Color(0xFF17152B) : Colors.white,
                              size: 24,
                            ),
                          ),
                        ),

                        // End Call Red Button
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEB5757),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x66EB5757),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.call_end_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
