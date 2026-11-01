import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'chat_detail_screen.dart';

/// [CallScreen]
/// Implementasi Layar Panggilan Telepon Berlangsung Driver & Pelanggan
/// Sesuai Desain Figma:
/// - Figma/HalamanFlexSend/telpon berlangsung.png (Panggilan Telepon Aktif & Timer 01:23)
/// - Figma/HalamanFlexSend/chat-1.png (Panggilan sedang berlangsung)
class CallScreen extends StatefulWidget {
  final String customerName;
  final String avatarInitials;
  final String? avatarAsset;
  final bool isOnline;
  final int initialDurationSeconds;
  final VoidCallback? onEndCall;

  const CallScreen({
    super.key,
    this.customerName = 'M.topik',
    this.avatarInitials = 'MT',
    this.avatarAsset,
    this.isOnline = true,
    this.initialDurationSeconds = 83, // 01:23 sesuai Figma telpon berlangsung.png
    this.onEndCall,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late int _durationSeconds;
  Timer? _callTimer;
  bool _isSpeakerOn = false;
  bool _isMuted = false;
  bool _isEnded = false;

  @override
  void initState() {
    super.initState();
    _durationSeconds = widget.initialDurationSeconds;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isEnded) {
        setState(() {
          _durationSeconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    super.dispose();
  }

  void _endCall() {
    _callTimer?.cancel();
    setState(() {
      _isEnded = true;
    });
    widget.onEndCall?.call();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1A34),
      body: Stack(
        children: [
          // Background Dimmed Chat Messages sesuai Figma telpon berlangsung.png
          _buildBackgroundChatSimulation(),

          // Konten Utama Layar Panggilan Telepon
          SafeArea(
            child: Column(
              children: [
                // 1. Top Bar Panggilan
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Tombol Kembali
                      InkWell(
                        key: const Key('btn_call_back'),
                        onTap: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Avatar Kecil & Indikator Online
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFF6B48FC),
                            child: Text(
                              widget.avatarInitials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (widget.isOnline)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00C853),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF1E1A34),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Nama Pelanggan & Durasi Telepon
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.customerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isEnded
                                  ? 'Panggilan berakhir'
                                  : _formatDuration(_durationSeconds),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Pintasan ke Chat
                      InkWell(
                        key: const Key('btn_call_open_chat'),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(
                                customerName: widget.customerName,
                                avatarInitials: widget.avatarInitials,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // 2. Avatar Besar Tengah dengan Border Putih & Shadow (Figma telpon berlangsung.png)
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: widget.avatarAsset != null
                        ? Image.asset(widget.avatarAsset!, fit: BoxFit.cover)
                        : CircleAvatar(
                            backgroundColor: const Color(0xFF6B48FC),
                            child: Text(
                              widget.avatarInitials,
                              style: const TextStyle(
                                fontSize: 54,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ),

                const Spacer(),

                // 3. Dock Kontrol Telepon Bawah (Speaker, Mic, End Call)
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Tombol Speaker Audio
                      InkWell(
                        key: const Key('btn_call_speaker'),
                        onTap: () {
                          setState(() {
                            _isSpeakerOn = !_isSpeakerOn;
                          });
                        },
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isSpeakerOn
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.25),
                          ),
                          child: Icon(
                            _isSpeakerOn
                                ? Icons.volume_up_rounded
                                : Icons.volume_down_rounded,
                            color: _isSpeakerOn ? AppColors.dark : Colors.white,
                            size: 26,
                          ),
                        ),
                      ),

                      // Tombol Mute Mikrofon
                      InkWell(
                        key: const Key('btn_call_mute'),
                        onTap: () {
                          setState(() {
                            _isMuted = !_isMuted;
                          });
                        },
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isMuted
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.25),
                          ),
                          child: Icon(
                            _isMuted
                                ? Icons.mic_off_rounded
                                : Icons.mic_rounded,
                            color: _isMuted ? AppColors.dark : Colors.white,
                            size: 26,
                          ),
                        ),
                      ),

                      // Tombol Akhiri Panggilan Merah
                      InkWell(
                        key: const Key('btn_end_call'),
                        onTap: _endCall,
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFEB4335),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Simulasi Gelembung Chat Latar Belakang (sesuai Figma telpon berlangsung.png)
  Widget _buildBackgroundChatSimulation() {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.15,
        child: Padding(
          padding: const EdgeInsets.only(top: 100, left: 16, right: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B48FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Hari Ini',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildBackgroundBubble(
                  'Hi bang, saya sudah sesuai titik penjemputan', '10.11',
                  isMe: false),
              const SizedBox(height: 12),
              _buildBackgroundBubble(
                  'Bang dimana ya? saya sudah sesuai titik', '10.11',
                  isMe: false),
              const SizedBox(height: 12),
              _buildBackgroundBubble('BANGG', '10.11', isMe: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundBubble(String text, String time,
      {required bool isMe}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF6B48FC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
