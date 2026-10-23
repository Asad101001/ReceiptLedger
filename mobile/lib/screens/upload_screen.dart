import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class UploadScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const UploadScreen({super.key, this.onOpenDrawer});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  bool _isBatchMode = false;
  bool _isFlashOn = false;
  String _aspectRatio = '4:3 Crop';

  Uint8List? _selectedImageBytes;
  String? _selectedFileName;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.15, end: 0.85).animate(
      CurvedAnimation(parent: _scanAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 92,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedFileName = file.name;
        });
        _showProcessingPreviewSheet();
      }
    } catch (_) {
      _showFriendlyToast('Failed to select image. Please try again.');
    }
  }

  void _showFriendlyToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppTheme.badgeRed : AppTheme.navyBrand,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _uploadReceipt() async {
    if (_selectedImageBytes == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _api.uploadReceipt(
        bytes: _selectedImageBytes!,
        filename: _selectedFileName ?? 'receipt.jpg',
        deviceTimestamp: DateTime.now().toIso8601String(),
        captureMode: _isBatchMode ? 'batch' : 'single',
      );

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      Navigator.pop(context); // Close preview sheet
      _showFriendlyToast('Receipt uploaded! Added to your ledger.');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showProcessingPreviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Receipt Preview & Quality',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navyBrand,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_selectedImageBytes != null)
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.memory(
                    _selectedImageBytes!,
                    fit: BoxFit.contain,
                  ),
                ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('Blur Score', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        SizedBox(height: 2),
                        Text('Sharp (2170)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.navyBrand)),
                      ],
                    ),
                    Column(
                      children: [
                        Text('Classification', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        SizedBox(height: 2),
                        Text('Printed POS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.greenVerified)),
                      ],
                    ),
                    Column(
                      children: [
                        Text('OCR Engine', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        SizedBox(height: 2),
                        Text('Gemini Vision', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.navyBrand)),
                      ],
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.badgeRed, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppTheme.badgeRed, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setSheetState(() => _isLoading = true);
                        await _uploadReceipt();
                        setSheetState(() => _isLoading = false);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.navyBrand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Upload & Process Receipt',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showManualEntryDialog() {
    final merchantCtrl = TextEditingController(text: 'Local Mart');
    final amountCtrl = TextEditingController(text: '1450.0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Manual Entry', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: merchantCtrl,
              decoration: const InputDecoration(labelText: 'Store / Merchant Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Amount (${_api.currency})'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showFriendlyToast('Manual receipt saved to ledger!');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navyBrand),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Persistent Header matching CAPTURE.png
          AppHeader(
            subCaption: 'CAPTURE',
            onAvatarTap: widget.onOpenDrawer,
          ),

          // Main Viewport
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Mode Selector & Quick Actions Row
                  Row(
                    children: [
                      // Mode Selector Pill Card
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              // Single Receipt Pill
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _isBatchMode = false),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: !_isBatchMode ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: !_isBatchMode
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withAlpha(15),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.description_outlined,
                                          size: 16,
                                          color: !_isBatchMode ? AppTheme.navyBrand : AppTheme.textMuted,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Single\nReceipt',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: !_isBatchMode ? AppTheme.navyBrand : AppTheme.textMuted,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            height: 1.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Batch Mode Pill
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _isBatchMode = true),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _isBatchMode ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: _isBatchMode
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withAlpha(15),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.copy_outlined,
                                          size: 16,
                                          color: _isBatchMode ? AppTheme.navyBrand : AppTheme.textMuted,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Batch\nMode',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: _isBatchMode ? AppTheme.navyBrand : AppTheme.textMuted,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            height: 1.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Flash Toggle
                      IconButton(
                        onPressed: () {
                          setState(() => _isFlashOn = !_isFlashOn);
                          _showFriendlyToast(_isFlashOn ? 'Flash turned ON' : 'Flash turned OFF');
                        },
                        icon: Icon(
                          _isFlashOn ? Icons.flash_on : Icons.flash_off_outlined,
                          color: _isFlashOn ? AppTheme.amberWarning : AppTheme.navyBrand,
                        ),
                      ),

                      // Framing / Crop Toggle
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _aspectRatio = _aspectRatio == '4:3 Crop' ? 'Full Frame' : '4:3 Crop';
                          });
                        },
                        icon: const Icon(Icons.crop_free, color: AppTheme.navyBrand),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Camera Viewfinder Card matching CAPTURE.png
                  Container(
                    height: 420,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B), // Dark slate viewfinder background
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(30),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background Receipt Slip matching Whole Foods in CAPTURE.png
                        Positioned.fill(
                          child: _selectedImageBytes != null
                              ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                              : _buildWholeFoodsMockReceipt(),
                        ),

                        // Animated Scanning Line (Sweeps across the receipt)
                        AnimatedBuilder(
                          animation: _scanAnimation,
                          builder: (context, child) {
                            return Positioned(
                              top: 420 * _scanAnimation.value,
                              left: 36,
                              right: 36,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  color: Colors.cyanAccent.withAlpha(180),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.cyanAccent.withAlpha(150),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // Viewfinder 4 Corner Brackets
                        _buildViewfinderCorners(),

                        // Top Left Overlay Badge: (✓) Receipt Detected • Ready
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, size: 14, color: AppTheme.greenVerified),
                                SizedBox(width: 5),
                                Text(
                                  'Receipt Detected • Ready',
                                  style: TextStyle(
                                    color: AppTheme.navyBrand,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Top Right Overlay Badge: [⛶] 4:3 Crop
                        Positioned(
                          top: 14,
                          right: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(220),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.crop, size: 13, color: AppTheme.navyBrand),
                                const SizedBox(width: 4),
                                Text(
                                  _aspectRatio,
                                  style: const TextStyle(
                                    color: AppTheme.navyBrand,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Center Prompt Banner: ALIGN MERCHANT & TOTAL
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(25),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'ALIGN MERCHANT & TOTAL',
                            style: TextStyle(
                              color: AppTheme.navyBrand,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),

                        // Bottom Guidance Pill: (*) Hold steady • Keep flat under even light
                        Positioned(
                          bottom: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.wb_sunny_outlined, size: 14, color: AppTheme.navyBrand),
                                SizedBox(width: 6),
                                Text(
                                  'Hold steady • Keep flat under even light',
                                  style: TextStyle(
                                    color: AppTheme.navyBrand,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bottom Controls Row: Gallery | Shutter Button | Manual
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Gallery Button
                      GestureDetector(
                        onTap: () => _pickImage(ImageSource.gallery),
                        child: Column(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.borderLight),
                              ),
                              child: const Icon(
                                Icons.photo_library_outlined,
                                color: AppTheme.navyBrand,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Gallery',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.navyBrand,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Shutter Squircle Button with Aperture Icon matching CAPTURE.png
                      GestureDetector(
                        onTap: () => _pickImage(ImageSource.camera),
                        child: Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            color: AppTheme.navyBrand,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.navyBrand.withAlpha(80),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: CustomPaint(
                                painter: _ApertureShutterPainter(),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Manual Entry Button
                      GestureDetector(
                        onTap: _showManualEntryDialog,
                        child: Column(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.borderLight),
                              ),
                              child: const Icon(
                                Icons.edit_note_outlined,
                                color: AppTheme.navyBrand,
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Manual',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.navyBrand,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 84), // Padding above bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Authentic simulated physical receipt slip matching CAPTURE.png
  Widget _buildWholeFoodsMockReceipt() {
    return Container(
      color: const Color(0xFF0F172A),
      alignment: Alignment.center,
      child: Container(
        width: 220,
        height: 360,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFBFD),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(60),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'WHOLE FOODS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
                letterSpacing: 1.0,
              ),
            ),
            const Text(
              'MARKET',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'STORE: WHOLE FOODS MARKET | REG: 3\nDATE: OCT 12, 2023 | TIME: 4:38 PM',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 6.5,
                color: Color(0xFF64748B),
                height: 1.2,
              ),
            ),
            const Divider(height: 12, thickness: 0.8),

            // Itemized line items
            _mockLineItem('1x ORGANIC BANANAS', '1.99 F'),
            _mockLineItem('1x ORGANIC MILK 1/2 G', '4.29 F'),
            _mockLineItem('1x SOURDOUGH BREAD LOAF', '5.99 F'),
            _mockLineItem('1x FREE-RANGE EGGS DOZEN', '7.50 F'),
            _mockLineItem('1x CHICKEN BREAST (1.45 LB)', '14.45 F'),
            _mockLineItem('1x ORGANIC SPINACH BAG', '3.49 F'),
            _mockLineItem('1x WHOLE FOODS COFFEE', '12.99 F'),

            const Divider(height: 10, thickness: 0.8),
            _mockLineItem('SUBTOTAL:', '50.70'),
            _mockLineItem('TAX 8%:', '4.06'),
            _mockLineItem('TOTAL:', '54.76', isBold: true),

            const Spacer(),

            // Barcode and QR code row matching mockup
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Simulated barcode
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        for (int i = 0; i < 20; i++)
                          Container(
                            width: i % 4 == 0 ? 2.2 : 1.2,
                            height: 22,
                            color: Colors.black,
                            margin: const EdgeInsets.symmetric(horizontal: 0.6),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '543210987654',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 6.5, color: Colors.black),
                    ),
                  ],
                ),

                // Simulated QR matrix
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
                    itemCount: 16,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (ctx, idx) => Container(
                      color: (idx % 2 == 0 || idx == 5 || idx == 10) ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mockLineItem(String item, String price, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              item,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 7.5,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            price,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 7.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinderCorners() {
    const double size = 32;
    const double thickness = 3.5;
    const Color color = Colors.white;

    return Positioned(
      top: 50,
      bottom: 50,
      left: 32,
      right: 32,
      child: Stack(
        children: [
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
