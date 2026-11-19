import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/services/customer_api_service.dart';
import '../modules/call/voice_call_overlay.dart';
import '../modules/conversation/chat_input_bar.dart';
import '../modules/conversation/conversation_header.dart';
import '../modules/conversation/message_bubble.dart';
import '../modules/conversation/quick_replies_bar.dart';
import '../modules/inbox/inbox_view.dart';

/// Halaman Chat strictly based on Figma nodes [44:4665], [44:9043], and [44:9139]:
/// - chat.png: Chat Inbox / Conversation list with driver card
/// - chat-1.png: Direct message conversation room with driver
/// - TELEPON.png & TELEPON angkat.png: Full-screen calling overlay
class ChatScreen extends StatefulWidget {
  final bool showBackButton;
  final bool initialShowDetail;
  final bool isCustomerService;
  final String? orderId;
  final VoidCallback? onBack;

  const ChatScreen({
    super.key,
    this.showBackButton = false,
    this.initialShowDetail = true,
    this.isCustomerService = false,
    this.orderId,
    this.onBack,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late bool _showDetail;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final List<Map<String, dynamic>> _messages;
  late List<String> _quickReplies;
  bool _isWaitingAiReply = false;
  bool _isEscalatingTicket = false;
  bool _isLoadingQuickReplies = false;

  @override
  void initState() {
    super.initState();
    _showDetail = widget.initialShowDetail || widget.showBackButton;

    if (widget.isCustomerService) {
      _messages = [
        {
          'sender': 'driver',
          'text':
              'Halo kak! Selamat datang di Layanan Pelanggan RideOn. Ada yang bisa kami bantu terkait pesanan atau akun kakak hari ini?',
          'time': 'Sekarang',
        },
      ];
      _quickReplies = [
        'Kendala Pesanan',
        'Bantuan Akun',
        'Metode Pembayaran',
        'Hubungi Tim Teknis',
      ];
    } else {
      _messages = [
        {
          'sender': 'driver',
          'text':
              'Halo bu, saya sudah sampai di Pasar Sukaramai ya. Mulai carikan daging sapi.',
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
      _quickReplies = [
        'Boleh mas, sekalian aja',
        'Makasih ya mas',
        'Segera meluncur ya mas',
      ];
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? customText]) async {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'sender': 'user',
        'text': text,
        'time': 'Sekarang',
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

    if (widget.isCustomerService &&
        CustomerApiService().hasSession &&
        !CustomerApiService.enableLocalFallback) {
      setState(() => _isWaitingAiReply = true);
      final api = CustomerApiService();
      try {
        final reply = await api.aiChat(
          sessionId: 'cs_${api.cachedUserId ?? 'guest'}',
          message: text,
        );
        if (!mounted) return;
        setState(() {
          _isWaitingAiReply = false;
          _messages.add({
            'sender': 'driver',
            'text': reply.isNotEmpty
                ? reply
                : 'Baik kak, permintaan sudah kami catat. Ada detail order lagi?',
            'time': 'Sekarang',
          });
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isWaitingAiReply = false;
          _messages.add({
            'sender': 'driver',
            'text':
                'Asisten AI sedang sibuk. Kakak bisa tekan "Eskalasi ke Admin CS" untuk membuat tiket bantuan.',
            'time': 'Sekarang',
          });
        });
      }
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    }
  }

  Future<void> _escalateSupportTicket() async {
    if (_isEscalatingTicket) return;
    setState(() => _isEscalatingTicket = true);
    final lastUserMsg = _messages.lastWhere(
      (m) => m['sender'] == 'user',
      orElse: () => {'text': 'Butuh bantuan Customer Service melalui chat app'},
    )['text'].toString();
    try {
      await CustomerApiService().createSupportTicket(
        orderId: widget.orderId,
        subject: 'Bantuan CS In-App',
        bodyText: lastUserMsg,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tiket eskalasi ke Admin CS berhasil dibuat!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat tiket CS: $e')),
      );
    } finally {
      if (mounted) setState(() => _isEscalatingTicket = false);
    }
  }

  Future<void> _fetchAiQuickReplies() async {
    if (_isLoadingQuickReplies) return;
    setState(() => _isLoadingQuickReplies = true);
    try {
      final api = CustomerApiService();
      final reply = await api.aiChat(
        sessionId: 'qr_${api.cachedUserId ?? 'guest'}',
        message:
            'Berikan 3 balasan singkat Bahasa Indonesia (pisahkan dengan |) untuk customer menjawab driver ojol/kurir.',
      );
      final parsed = reply
          .split('|')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && s.length <= 45)
          .take(3)
          .toList();
      if (mounted && parsed.isNotEmpty) {
        setState(() => _quickReplies = parsed);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingQuickReplies = false);
    }
  }

  void _showCallModal() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'VoiceCall',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim1, anim2) {
        return VoiceCallOverlay(orderId: widget.orderId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_showDetail) {
      return ChatInboxView(
        onBack: widget.onBack,
        onOpenConversation: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                showBackButton: true,
                initialShowDetail: true,
                orderId: widget.orderId,
              ),
            ),
          );
        },
        onOpenCustomerService: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                showBackButton: true,
                initialShowDetail: true,
                isCustomerService: true,
                orderId: widget.orderId,
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          ConversationHeader(
            isCustomerService: widget.isCustomerService,
            onBack: () {
              if (widget.showBackButton) {
                Navigator.of(context).pop();
              } else {
                setState(() {
                  _showDetail = false;
                });
              }
            },
            onCall: _showCallModal,
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              children: [
                // 'Hari Ini' Date Pill
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
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
                ..._messages.map((msg) => MessageBubble(msg: msg)),
                if (_isWaitingAiReply)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'CS AI sedang mengetik...',
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF6B6680),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (widget.isCustomerService &&
              CustomerApiService().hasSession &&
              !CustomerApiService.enableLocalFallback)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ActionChip(
                  key: const ValueKey('btn_escalate_cs_ticket'),
                  onPressed:
                      _isEscalatingTicket ? null : _escalateSupportTicket,
                  avatar: const Icon(
                    Icons.support_agent_rounded,
                    size: 16,
                    color: Color(0xFF6B48FC),
                  ),
                  label: Text(
                    _isEscalatingTicket
                        ? 'Membuat Tiket...'
                        : 'Eskalasi ke Admin CS',
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B48FC),
                    ),
                  ),
                ),
              ),
            ),

          if (!widget.isCustomerService &&
              CustomerApiService().hasSession &&
              !CustomerApiService.enableLocalFallback)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const ValueKey('btn_ai_quick_replies'),
                  onPressed:
                      _isLoadingQuickReplies ? null : _fetchAiQuickReplies,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                  label: Text(
                    _isLoadingQuickReplies
                        ? 'Menyiapkan Saran...'
                        : 'Saran Balasan AI',
                    style: GoogleFonts.roboto(fontSize: 11),
                  ),
                ),
              ),
            ),

          // Quick replies
          QuickRepliesBar(
            quickReplies: _quickReplies,
            onSelectReply: _sendMessage,
          ),

          // Message input bar
          ChatInputBar(
            controller: _messageController,
            hintText: widget.isCustomerService
                ? 'Ketik pesan untuk Customer Service...'
                : 'Ketik pesan untuk driver...',
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}
