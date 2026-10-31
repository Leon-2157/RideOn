import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    {'sender': 'user', 'text': 'Boleh mas, sekalian aja', 'time': '10.11'},
    {'sender': 'driver', 'text': 'Baik bukk', 'time': '10.11'},
    {'sender': 'user', 'text': 'Terima kasih banyak', 'time': '10.11'},
    {'sender': 'driver', 'text': 'Segera meluncur ya mas', 'time': '10.11'},
    {'sender': 'driver', 'text': 'Ditunggu ya buk', 'time': '10.11'},
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
      _messages.add({'sender': 'user', 'text': text, 'time': '10.12'});
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
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim1, anim2) {
        return const VoiceCallOverlay();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_showDetail) {
      return ChatInboxView(
        onOpenConversation: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ChatScreen(
                showBackButton: true,
                initialShowDetail: true,
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
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              children: [
                // 'Hari Ini' Date Pill
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
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
              ],
            ),
          ),

          // Quick replies
          QuickRepliesBar(
            quickReplies: _quickReplies,
            onSelectReply: _sendMessage,
          ),

          // Message input bar
          ChatInputBar(controller: _messageController, onSend: _sendMessage),
        ],
      ),
    );
  }
}
