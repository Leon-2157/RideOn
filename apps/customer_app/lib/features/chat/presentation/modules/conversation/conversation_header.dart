import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';

class ConversationHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onCall;
  final bool isCustomerService;
  final String? customTitle;
  final String? customSubtitle;

  const ConversationHeader({
    super.key,
    required this.onBack,
    required this.onCall,
    this.isCustomerService = false,
    this.customTitle,
    this.customSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF9F88FD),
            Color(0xFFBAA7FD),
            Color(0xFFEFEAFF),
            Color(0xFFFFFFFF),
          ],
          stops: [0.0, 0.45, 0.85, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              // Back button (Glassmorphism transparan lembut ikon putih)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onBack,
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

              // Avatar with Online Indicator (Driver vs CS)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCustomerService
                          ? const Color(0xFF6B48FC)
                          : null,
                      image: !isCustomerService
                          ? const DecorationImage(
                              image: AssetImage(AppAssets.driverPikri),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: isCustomerService
                        ? const Center(
                            child: Icon(
                              Icons.support_agent_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
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
                    Text(
                      customTitle ??
                          (isCustomerService
                              ? 'Customer Service RideOn'
                              : 'Fikri haykal (Driver)'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E143E),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      customSubtitle ??
                          (isCustomerService
                              ? 'Online ( Siap Membantu 24/7 )'
                              : 'Online ( Sedang di Toko )'),
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Voice Call Mint Button (Hanya untuk Driver, DIHAPUS untuk Customer Service)
              if (!isCustomerService)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onCall,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.call_rounded,
                      color: Color(0xFF16A34A),
                      size: 22,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
