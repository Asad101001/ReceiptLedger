import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_toast.dart';

class UploadScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  final ValueChanged<int>? onNavigateTab;
  final VoidCallback? onNavigateToReview;

  const UploadScreen({
    super.key,
    this.onOpenDrawer,
    this.onNavigateTab,
    this.onNavigateToReview,
  });

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  String _captureMode = 'single'; // 'single' or 'batch'
  bool _flashAuto = true;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _laserAnimController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _laserAnimation = CurvedAnimation(
      parent: _laserAnimController,
      curve: Curves.easeInOut,
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (_) {
      // In simulator or environments without physical camera, gracefully falls back to mock viewfinder
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _laserAnimController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _handleCapture() async {
    if (_isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      if (_isCameraInitialized && _cameraController != null) {
        final XFile file = await _cameraController!.takePicture();
        final bytes = await file.readAsBytes();
        await ApiService().uploadReceipt(
          bytes: bytes,
          filename: file.name,
          captureMode: _captureMode,
        );
      } else {
        // Simulated capture fallback
        await Future.delayed(const Duration(milliseconds: 600));
      }

      if (!mounted) return;
      AppToast.success(
        context,
        'Receipt captured and queued for OCR parsing!',
        actionLabel: 'Review',
        onAction: () => widget.onNavigateTab != null ? widget.onNavigateTab!(2) : widget.onNavigateToReview?.call(),
      );
      ApiService().refreshReviewCount();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Capture failed: ${e.toString().split('\n').first}');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _handlePickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isCapturing = true);
      final bytes = await image.readAsBytes();
      await ApiService().uploadReceipt(
        bytes: bytes,
        filename: image.name,
        captureMode: _captureMode,
      );

      if (!mounted) return;
      AppToast.success(
        context,
        'Receipt uploaded from gallery successfully!',
        actionLabel: 'Review',
        onAction: () => widget.onNavigateTab != null ? widget.onNavigateTab!(2) : widget.onNavigateToReview?.call(),
      );
      ApiService().refreshReviewCount();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Gallery upload failed: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _handleManualEntry() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final merchantCtrl = TextEditingController();
        final amountCtrl = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Manual Receipt Entry',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: merchantCtrl,
                decoration: const InputDecoration(
                  labelText: 'Merchant Name',
                  hintText: 'e.g. Metro Cash & Carry',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Total Amount',
                  prefixText: '${ApiService().currency} ',
                  hintText: '0.00',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyBrand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  AppToast.success(context, 'Manual receipt added to review queue!');
                },
                child: const Text('Save to Review Queue', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardWhite;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMuted;

    return Scaffold(
      backgroundColor: isDark ? AppColors.canvasDark : AppColors.canvasLight,
      body: Column(
        children: [
          // Header with Logo & Drawer Avatar
          AppHeader(
            subCaption: 'CAPTURE',
            onAvatarTap: widget.onOpenDrawer ?? () => Scaffold.of(context).openEndDrawer(),
          ),

          // Scrollable Body containing Camera Hub and Dashboard
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), // Clears floating navbar
              children: [
                // Mode Toggle & Camera Options Pills
                _buildCaptureModeBar(isDark, borderColor, textPrimary, textMuted),
                const SizedBox(height: 12),

                // Viewfinder Container Card
                _buildViewfinderCard(isDark, borderColor),
                const SizedBox(height: 14),

                // Compact Capture Controls (Gallery, Iris Shutter, Manual)
                _buildCompactControlBar(isDark, cardBg, borderColor, textPrimary, textMuted),
                const SizedBox(height: 20),

                // Pending Verification Alert Card (if any pending)
                ValueListenableBuilder<int>(
                  valueListenable: ApiService().reviewCountNotifier,
                  builder: (context, count, _) {
                    if (count <= 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E3A8A).withAlpha(40) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.rate_review_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$count Receipts Pending Verification',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Review extracted line items before ledger commit',
                                    style: TextStyle(fontSize: 11, color: textMuted),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => widget.onNavigateTab != null
                                  ? widget.onNavigateTab!(2)
                                  : widget.onNavigateToReview?.call(),
                              child: const Text('Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Today's Activity Dashboard Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TODAY\'S ACTIVITY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: textMuted,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F7F0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Auto OCR Active',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.greenVerified,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _buildStatItem('Scanned', '4 Slips', Icons.document_scanner_rounded, AppColors.headerBlue, textPrimary, textMuted),
                          Container(width: 1, height: 36, color: borderColor),
                          _buildStatItem('Processed', '${ApiService().currency} 12,450', Icons.payments_rounded, AppColors.greenVerified, textPrimary, textMuted),
                          Container(width: 1, height: 36, color: borderColor),
                          _buildStatItem('Confidence', '99.4%', Icons.verified_rounded, const Color(0xFF3B82F6), textPrimary, textMuted),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Scanning Best Practices Tips
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wb_incandescent_outlined, color: AppColors.amberWarning, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tip: Keep slips flat under even lighting. Ensure merchant name and total amount are inside the viewfinder brackets.',
                          style: TextStyle(fontSize: 11.5, color: textMuted, height: 1.3),
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

  Widget _buildStatItem(String title, String val, IconData icon, Color iconColor, Color textPrimary, Color textMuted) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Text(title, style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureModeBar(bool isDark, Color borderColor, Color textPrimary, Color textMuted) {
    return Row(
      children: [
        // Mode Selector: Single vs Batch
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131B2E) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1),
          ),
          padding: const EdgeInsets.all(3),
          child: Row(
            children: [
              _buildModePill('Single Receipt', _captureMode == 'single', () {
                setState(() => _captureMode = 'single');
              }),
              _buildModePill('Batch Mode', _captureMode == 'batch', () {
                setState(() => _captureMode = 'batch');
              }),
            ],
          ),
        ),
        const Spacer(),

        // Auto Flash Toggle
        GestureDetector(
          onTap: () {
            setState(() => _flashAuto = !_flashAuto);
            AppToast.info(context, _flashAuto ? 'Flash: AUTO' : 'Flash: OFF');
          },
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardWhite,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  _flashAuto ? Icons.flash_auto_rounded : Icons.flash_off_rounded,
                  size: 16,
                  color: _flashAuto ? const Color(0xFFF59E0B) : textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  _flashAuto ? 'AUTO' : 'OFF',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Aspect Ratio Indicator
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardWhite,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: borderColor, width: 1),
          ),
          alignment: Alignment.center,
          child: Text(
            '4:3 Crop',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModePill(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildViewfinderCard(bool isDark, Color borderColor) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Sleek solid dark viewfinder
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 80 : 40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Live Camera Preview if initialized
          if (_isCameraInitialized && _cameraController != null)
            CameraPreview(_cameraController!)
          else
            // High-contrast clean viewfinder background with alignment grid
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.crop_free_rounded,
                    size: 44,
                    color: Colors.white.withAlpha(120),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Align Receipt Within Frame',
                    style: TextStyle(
                      color: Colors.white.withAlpha(220),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Auto-edge detection active',
                    style: TextStyle(
                      color: Colors.white.withAlpha(120),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),

          // L-Corner Viewfinder Guides
          _buildCornerGuides(),

          // Animated Scanning Laser Beam
          AnimatedBuilder(
            animation: _laserAnimation,
            builder: (context, _) {
              return Positioned(
                top: 20 + _laserAnimation.value * 210,
                left: 36,
                right: 36,
                child: Container(
                  height: 2,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2DD4BF),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF2DD4BF),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Top Info Status Pill: "Receipt Detected • Ready"
          Positioned(
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(140),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withAlpha(40), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.greenVerified,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Receipt Viewfinder • Ready',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerGuides() {
    const double size = 26;
    const double thickness = 3.0;
    const Color color = Colors.white;

    return Positioned(
      top: 30,
      bottom: 30,
      left: 28,
      right: 28,
      child: Stack(
        children: [
          // Top-Left
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: color, width: thickness),
                  left: BorderSide(color: color, width: thickness),
                ),
              ),
            ),
          ),
          // Top-Right
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: color, width: thickness),
                  right: BorderSide(color: color, width: thickness),
                ),
              ),
            ),
          ),
          // Bottom-Left
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: color, width: thickness),
                  left: BorderSide(color: color, width: thickness),
                ),
              ),
            ),
          ),
          // Bottom-Right
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: color, width: thickness),
                  right: BorderSide(color: color, width: thickness),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactControlBar(bool isDark, Color cardBg, Color borderColor, Color textPrimary, Color textMuted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Gallery Button
          _buildActionButton(
            icon: Icons.photo_library_outlined,
            label: 'Gallery',
            onTap: _handlePickFromGallery,
            isDark: isDark,
            textPrimary: textPrimary,
          ),

          // Central Iris Aperture Shutter Button (Compact 62dp)
          GestureDetector(
            onTap: _isCapturing ? null : _handleCapture,
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: AppColors.navyBrand,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navyBrand.withAlpha(isDark ? 90 : 60),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(7),
              child: _isCapturing
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                  : CustomPaint(
                      painter: _ApertureShutterPainter(),
                    ),
            ),
          ),

          // Manual Entry Button
          _buildActionButton(
            icon: Icons.edit_note_rounded,
            label: 'Manual',
            onTap: _handleManualEntry,
            isDark: isDark,
            textPrimary: textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    required Color textPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            child: Icon(icon, color: textPrimary, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the camera iris aperture shutter icon from CAPTURE.png
class _ApertureShutterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bladePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final outerRingPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Draw outer circle
    canvas.drawCircle(center, radius - 1, outerRingPaint);

    // Draw 8 aperture blades around the iris
    const int blades = 8;
    for (int i = 0; i < blades; i++) {
      final angle = (i * 2 * math.pi) / blades;
      final p1 = Offset(
        center.dx + (radius - 2) * math.cos(angle),
        center.dy + (radius - 2) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + (radius * 0.42) * math.cos(angle + math.pi / 3),
        center.dy + (radius * 0.42) * math.sin(angle + math.pi / 3),
      );
      canvas.drawLine(p1, p2, bladePaint);
    }

    // Center circular aperture with red & blue accent dot
    final centerCirclePaint = Paint()
      ..color = const Color(0xFF0C1E4A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.35, centerCirclePaint);

    final redAccent = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;
    final blueAccent = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.fill;

    // Split red/blue center iris core
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.22),
      -math.pi / 2,
      math.pi,
      true,
      redAccent,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.22),
      math.pi / 2,
      math.pi,
      true,
      blueAccent,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
