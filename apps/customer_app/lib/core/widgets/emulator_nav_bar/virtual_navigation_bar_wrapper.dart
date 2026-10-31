import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Global navigator key agar tombol navigasi virtual emulator dapat mengontrol
/// perpindahan rute (Back, Home, Recent) dari level manapun.
final GlobalKey<NavigatorState> emulatorNavigatorKey = GlobalKey<NavigatorState>();

/// Widget wrapper emulator navigation bar (Back, Home, Recent)
/// yang hanya aktif dan muncul di platform Linux Desktop / Web (bukan HP fisik).
class VirtualNavigationBarWrapper extends StatefulWidget {
  final Widget child;

  const VirtualNavigationBarWrapper({
    super.key,
    required this.child,
  });

  @override
  State<VirtualNavigationBarWrapper> createState() => _VirtualNavigationBarWrapperState();
}

class _VirtualNavigationBarWrapperState extends State<VirtualNavigationBarWrapper> {
  bool _showRecentOverlay = false;

  bool get _isDesktopEmulator {
    if (kIsWeb) return true;
    return Platform.isLinux || Platform.isWindows || Platform.isMacOS;
  }

  void _handleBack() {
    final nav = emulatorNavigatorKey.currentState;
    if (_showRecentOverlay) {
      setState(() => _showRecentOverlay = false);
      return;
    }
    if (nav != null && nav.canPop()) {
      nav.maybePop();
    }
  }

  void _handleHome() {
    final nav = emulatorNavigatorKey.currentState;
    if (_showRecentOverlay) {
      setState(() => _showRecentOverlay = false);
    }
    if (nav != null) {
      // Pop semua route sampai halaman awal (Beranda)
      nav.popUntil((route) => route.isFirst);
    }
  }

  void _handleRecent() {
    setState(() {
      _showRecentOverlay = !_showRecentOverlay;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDesktopEmulator) {
      return widget.child;
    }

    return Stack(
      children: [
        // Main App Content + Bottom Navigation Bar ditaruh dalam Column vertikal
        // sehingga konten aplikasi TIDAK AKAN PERNAH tertutup oleh navigation bar
        Positioned.fill(
          child: Column(
            children: [
              Expanded(
                child: widget.child,
              ),

              // Bottom Android Virtual Navigation Bar (Back, Home, Recent)
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0C15), // Solid dark phone bezel
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 1. Back Button (Segitiga menghadap kiri)
                    _NavButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      iconSize: 18,
                      onTap: _handleBack,
                    ),

                    // 2. Home Button (Lingkaran)
                    _NavButton(
                      icon: Icons.circle_outlined,
                      iconSize: 19,
                      onTap: _handleHome,
                    ),

                    // 3. Recent / Overview Button (Kotak rounded)
                    _NavButton(
                      icon: Icons.crop_square_rounded,
                      iconSize: 21,
                      onTap: _handleRecent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Recent Task Switcher Overlay (Mock Android Overview)
        if (_showRecentOverlay)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _showRecentOverlay = false),
              child: Container(
                color: Colors.black.withValues(alpha: 0.85),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Aplikasi Terbuka (Recent Apps)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () => setState(() => _showRecentOverlay = false),
                        child: Container(
                          width: 220,
                          height: 380,
                          decoration: BoxDecoration(
                            color: const Color(0xFF17152B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF6B48FC), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6B48FC).withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  color: const Color(0xFF231E3D),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.directions_bike_rounded, color: Colors.white, size: 16),
                                      SizedBox(width: 8),
                                      Text(
                                        'RideOn Customer',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Expanded(
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.touch_app_rounded, color: Colors.white70, size: 36),
                                        SizedBox(height: 8),
                                        Text(
                                          'Sentuh untuk kembali',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: () => _handleHome(),
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                        label: const Text(
                          'Tutup Semua',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Center(
              child: Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.85),
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

