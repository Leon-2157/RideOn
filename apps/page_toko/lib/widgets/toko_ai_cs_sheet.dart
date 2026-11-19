import 'package:flutter/material.dart';
import '../services/toko_api_service.dart';
import '../theme/app_colors.dart';

Future<void> showTokoAiCsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _TokoAiCsSheet(),
  );
}

class _TokoAiCsSheet extends StatefulWidget {
  const _TokoAiCsSheet();

  @override
  State<_TokoAiCsSheet> createState() => _TokoAiCsSheetState();
}

class _TokoAiCsSheetState extends State<_TokoAiCsSheet> {
  final TextEditingController _inputController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'sender': 'ai',
      'text': 'Halo Mitra Toko! Saya CS AI RideOn. Tanyakan status pesanan, pencairan saldo, atau ajukan tiket bantuan ke Admin.',
    },
  ];
  bool _sending = false;
  late final String _sessionId;

  @override
  void initState() {
    super.initState();
    _sessionId = 'toko-cs-${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _sending) return;
    _inputController.clear();
    setState(() {
      _messages.add({'sender': 'user', 'text': trimmed});
      _sending = true;
    });
    try {
      final reply = await TokoApiService().aiChat(sessionId: _sessionId, message: trimmed);
      if (!mounted) return;
      setState(() {
        _messages.add({
          'sender': 'ai',
          'text': reply.isNotEmpty ? reply : 'Silakan sampaikan detail kendala toko Anda agar kami bantu.',
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'sender': 'ai',
          'text': 'Asisten AI belum terhubung ke server ($e). Anda dapat langsung membuat Tiket Bantuan ke Admin di bawah ini.',
        });
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _escalateTicket() async {
    final lastUser = _messages.lastWhere(
      (m) => m['sender'] == 'user',
      orElse: () => {'text': 'Kendala operasional Mitra Toko'},
    );
    try {
      await TokoApiService().createSupportTicket(
        subject: 'Kendala Mitra Toko RideOn',
        message: lastUser['text'] ?? 'Butuh bantuan admin untuk toko saya.',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tiket Bantuan berhasil dikirim ke Admin RideOn.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim tiket: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      padding: EdgeInsets.fromLTRB(18, 12, 18, bottomInset + 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'CS AI Mitra Toko',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              TextButton.icon(
                key: const Key('btn_toko_create_ticket'),
                onPressed: _escalateTicket,
                icon: const Icon(Icons.confirmation_number_outlined, size: 16),
                label: const Text('Tiket Admin', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'Cek status pesanan hari ini',
                'Cara tarik saldo toko',
                'Kendala verifikasi toko',
              ].map((q) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(q, style: const TextStyle(fontSize: 11)),
                    onPressed: () => _send(q),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (_, idx) {
                final m = _messages[idx];
                final isUser = m['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 280),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primary : AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      m['text'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: isUser ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_sending) const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  decoration: InputDecoration(
                    hintText: 'Tulis pertanyaan Anda...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onSubmitted: _send,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sending ? null : () => _send(_inputController.text),
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

