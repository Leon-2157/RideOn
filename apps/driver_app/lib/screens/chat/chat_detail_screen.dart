import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Model pesan chat lokal untuk slicing UI
class ChatMessage {
  final String text;
  final String time;
  final bool isFromDriver;
  final bool isCallStatus;
  final String? callStatusText;

  const ChatMessage({
    required this.text,
    required this.time,
    this.isFromDriver = false,
    this.isCallStatus = false,
    this.callStatusText,
  });
}

/// [ChatDetailScreen]
/// Implementasi Layar Ruang Obrolan Driver & Pelanggan sesuai desain Figma:
/// - Figma/HalamanFlexSend/chat.png
/// - Figma/HalamanFlexSend/chat-1.png & telpon berlangsung.png (Panggilan Telepon Aktif)
/// - Figma/HalamanFlexSend/chat-2.png (Panggilan berakhir)
/// - Figma/HalamanFlexSend/chat-3.png & chat-4.png (Chat Melisa & Panggilan ditolak)
class ChatDetailScreen extends StatefulWidget {
  final String customerName;
  final String avatarInitials;
  final bool isOnline;
  final List<ChatMessage>? initialMessages;

  const ChatDetailScreen({
    super.key,
    this.customerName = 'M.topik',
    this.avatarInitials = 'MT',
    this.isOnline = true,
    this.initialMessages,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late List<ChatMessage> _messages;

  // State untuk overlay panggilan telepon
  bool _isInCall = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  int _callDurationSeconds = 83; // 01:23 sesuai Figma
  Timer? _callTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialMessages != null) {
      _messages = List.from(widget.initialMessages!);
    } else if (widget.customerName.toLowerCase().contains('melisa') ||
        widget.customerName.toLowerCase().contains('melissa')) {
      _messages = [
        const ChatMessage(
          text: 'Hi kak, saya sudah sesuai titik lokasi',
          time: '10.11',
          isFromDriver: false,
        ),
        const ChatMessage(
          text: 'Kak',
          time: '10.12',
          isFromDriver: false,
        ),
        const ChatMessage(
          text: '',
          time: '10.13',
          isCallStatus: true,
          callStatusText: 'Panggilan Ditolak',
        ),
        const ChatMessage(
          text: 'Bang gantung saja di pagar uang nya nanti saya tf',
          time: '10.14',
          isFromDriver: false,
        ),
        const ChatMessage(
          text: 'Baik',
          time: '10.15',
          isFromDriver: true,
        ),
      ];
    } else {
      // Default M.topik sesuai Figma
      _messages = [
        const ChatMessage(
          text: 'Hi bang, saya sudah sesuai titik penjemputan',
          time: '10.11',
          isFromDriver: false,
        ),
        const ChatMessage(
          text: 'Bang dimana ya? saya sudah sesuai titik',
          time: '10.15',
          isFromDriver: false,
        ),
        const ChatMessage(
          text: 'BANGG',
          time: '10.17',
          isFromDriver: false,
        ),
        const ChatMessage(
          text: '',
          time: '10.20',
          isCallStatus: true,
          callStatusText: 'Panggilan berakhir',
        ),
      ];
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _callTimer?.cancel();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          time: timeStr,
          isFromDriver: true,
        ),
      );
      _messageController.clear();
    });

    // Auto-scroll ke pesan terbaru
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startCall() {
    setState(() {
      _isInCall = true;
      _callDurationSeconds = 83; // 01:23
    });
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDurationSeconds++;
        });
      }
    });
  }

  void _endCall() {
    _callTimer?.cancel();
    setState(() {
      _isInCall = false;
      _messages.add(
        const ChatMessage(
          text: '',
          time: '10.20',
          isCallStatus: true,
          callStatusText: 'Panggilan berakhir',
        ),
      );
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // 1. Konten Utama Chat
          Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _buildMessagesList(),
              ),
              _buildInputBar(),
            ],
          ),

          // 2. Fullscreen Call Overlay sesuai Figma (telpon berlangsung.png)
          if (_isInCall)
            Positioned.fill(
              child: _buildCallOverlay(),
            ),
        ],
      ),
    );
  }

  /// Header Bar Atas sesuai Figma (chat.png)
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF9D84FC),
            Color(0xFFC7B7FC),
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          // Tombol Kembali
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.dark,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Avatar dengan Online Badge
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF6B48FC),
                child: Text(
                  widget.avatarInitials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              if (widget.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D26A),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Nama & Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.customerName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
                Text(
                  widget.isOnline ? 'Online' : 'Offline',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4A3E8A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Tombol Telepon Hijau
          InkWell(
            onTap: _startCall,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.phone_rounded,
                color: Color(0xFF00A859),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Daftar Pesan Chat
  Widget _buildMessagesList() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Pill Tanggal "Hari Ini"
        Center(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF6B48FC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Hari Ini',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        // Iterasi Gelembung Pesan
        ..._messages.map((msg) => _buildMessageBubble(msg)),
      ],
    );
  }

  /// Gelembung Pesan Tunggal Sesuai Figma
  Widget _buildMessageBubble(ChatMessage msg) {
    if (msg.isCallStatus) {
      // Bubble Notifikasi Telepon (chat-2.png & chat-4.png)
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF7C5CEE),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.phone_missed_rounded,
                color: Color(0xFFFF4D4F),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                msg.callStatusText ?? 'Panggilan berakhir',
                style: const TextStyle(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                msg.time,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bool isDriver = msg.isFromDriver;
    final alignment = isDriver ? Alignment.centerRight : Alignment.centerRight;
    final bubbleColor = isDriver
        ? const Color(0xFF7C5CEE)
        : const Color(0xFF7C5CEE);

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isDriver ? 16 : 4),
            bottomRight: Radius.circular(isDriver ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg.time,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Input Bar Bawah (Ketik pesan untuk driver... & Tombol Send)
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Input Teks Berbentuk Pill
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FB),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFD6E2EE),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _messageController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Ketik pesan untuk driver...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8C9BAE),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Tombol Kirim Ungu
          InkWell(
            onTap: _sendMessage,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF6B48FC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Overlay Panggilan Telepon Berlangsung (telpon berlangsung.png)
  Widget _buildCallOverlay() {
    return Container(
      color: const Color(0xFF1E1A34).withValues(alpha: 0.95),
      child: SafeArea(
        child: Column(
          children: [
            // Top Bar Panggilan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isInCall = false;
                      });
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
                  const SizedBox(width: 16),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF6B48FC),
                    child: Text(
                      widget.avatarInitials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
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
                      Text(
                        _formatDuration(_callDurationSeconds),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Avatar Besar Tengah dengan Border Putih
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CircleAvatar(
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

            const Spacer(),

            // Dock Kontrol Telepon Bawah
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                  // Speaker Button
                  InkWell(
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

                  // Mute Mic Button
                  InkWell(
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
                        _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        color: _isMuted ? AppColors.dark : Colors.white,
                        size: 26,
                      ),
                    ),
                  ),

                  // End Call Red Button
                  InkWell(
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
    );
  }
}
