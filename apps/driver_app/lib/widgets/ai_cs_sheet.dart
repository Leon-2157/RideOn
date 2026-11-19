import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/driver_api_service.dart';

class _ChatMessage {
  final String role;
  final String content;
  const _ChatMessage({required this.role, required this.content});
}

/// CS AI floating button untuk Driver — panggil showAiCsSheet() dari layar manapun.
class AiCsFloatingButton extends StatelessWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  const AiCsFloatingButton({super.key, this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'ai_cs_driver',
      backgroundColor: AppColors.primary,
      tooltip: 'Tanya CS AI',
      onPressed: () => showAiCsSheet(context),
      child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 20),
    );
  }
}

void showAiCsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AiCsSheet(),
  );
}

class _AiCsSheet extends StatefulWidget {
  const _AiCsSheet();
  @override
  State<_AiCsSheet> createState() => _AiCsSheetState();
}

class _AiCsSheetState extends State<_AiCsSheet> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatMessage> _msgs = [
    const _ChatMessage(
      role: 'assistant',
      content: 'Halo Mitra Driver! Saya CS AI RideOn. Ada yang bisa saya bantu seputar komisi, cara kerja aplikasi, atau kebijakan RideOn?',
    ),
  ];
  bool _loading = false;

  static const _systemPromptText =
      'Kamu adalah CS AI RideOn untuk mitra driver. Bantu pertanyaan seputar komisi, cara kerja aplikasi, proses klaim, dan kebijakan RideOn. Jawab singkat, ramah, dan dalam Bahasa Indonesia.';

  final String _sessionId =
      'driver-cs-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    _ctrl.clear();
    setState(() {
      _msgs.add(_ChatMessage(role: 'user', content: text));
      _loading = true;
    });
    _scrollDown();
    try {
      final reply = await DriverApiService().aiChat(
        sessionId: _sessionId,
        message: text,
        systemPrompt: _systemPromptText,
      );
      if (!mounted) return;
      setState(() { _msgs.add(_ChatMessage(role: 'assistant', content: reply)); });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _msgs.add(const _ChatMessage(
          role: 'assistant',
          content: 'Maaf, CS AI sedang tidak tersedia. Hubungi support@rideons.app.',
        ));
      });
    } finally {
      if (mounted) setState(() { _loading = false; });
      _scrollDown();
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('CS AI RideOn', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _msgs.length + (_loading ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _msgs.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
                      child: const SizedBox(width: 40, height: 16, child: LinearProgressIndicator()),
                    ),
                  );
                }
                final msg = _msgs[i];
                final isUser = msg.role == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primary : Colors.grey[100],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                    ),
                    child: Text(
                      msg.content,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 13),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(
                    hintText: 'Ketik pertanyaan...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
