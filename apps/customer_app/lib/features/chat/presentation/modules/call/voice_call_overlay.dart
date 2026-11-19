import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';
import 'package:rideon/core/services/webrtc_call_service.dart';

class VoiceCallOverlay extends StatefulWidget {
  final String? orderId;
  final String? peerName;

  const VoiceCallOverlay({
    super.key,
    this.orderId,
    this.peerName,
  });

  @override
  State<VoiceCallOverlay> createState() => _VoiceCallOverlayState();
}

class _VoiceCallOverlayState extends State<VoiceCallOverlay> {
  bool _isConnected = false;
  int _secondsElapsed = 0;
  Timer? _timer;
  Timer? _connectTimer;
  bool _isMuted = false;
  bool _isSpeaker = false;
  WebRtcCallService? _rtc;
  String? _rtcStatus;

  @override
  void initState() {
    super.initState();
    final oid = widget.orderId ?? '';
    if (oid.isNotEmpty) {
      _rtc = WebRtcCallService(
        onStatusChanged: (status) {
          if (!mounted) return;
          setState(() {
            _rtcStatus = status;
            if (status == 'CONNECTED') {
              _isConnected = true;
              _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
                if (mounted) setState(() => _secondsElapsed++);
              });
            }
          });
        },
      );
      _rtc!.startCall(orderId: oid);
    }

    _connectTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && !_isConnected) {
        setState(() {
          _isConnected = true;
          _secondsElapsed = oid.isNotEmpty ? 0 : 92;
        });
        _timer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
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
    _connectTimer?.cancel();
    _timer?.cancel();
    _rtc?.endCall();
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
          // Translucent dark scrim with soft blur so chat bubbles remain softly visible behind call overlay matching Figma TELEPON.png
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: const Color(0x8A17152B),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
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
                              (widget.peerName ?? '').isNotEmpty
                                  ? widget.peerName!
                                  : 'Fikri haykal (Driver)',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isConnected
                                  ? _formatDuration(_secondsElapsed)
                                  : (_rtcStatus == 'LOCAL_ONLY' ||
                                          _rtcStatus == 'UNAVAILABLE')
                                      ? 'Menghubungkan (${_rtcStatus!})...'
                                      : 'Berdering...',
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

                // Center Circular Driver Avatar
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

                // Bottom Floating Pill Dock
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 32.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF2C273E).withValues(alpha: 0.85),
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
                          onTap: () {
                            setState(() => _isSpeaker = !_isSpeaker);
                            _rtc?.toggleSpeaker();
                          },
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
                              color: _isSpeaker
                                  ? const Color(0xFF17152B)
                                  : Colors.white,
                              size: 24,
                            ),
                          ),
                        ),

                        // Mic / Mute Toggle
                        GestureDetector(
                          onTap: () {
                            setState(() => _isMuted = !_isMuted);
                            _rtc?.toggleMute();
                          },
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
                              color: _isMuted
                                  ? const Color(0xFF17152B)
                                  : Colors.white,
                              size: 24,
                            ),
                          ),
                        ),

                        // End Call Red Button
                        GestureDetector(
                          onTap: () {
                            _rtc?.endCall();
                            Navigator.of(context).pop();
                          },
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
