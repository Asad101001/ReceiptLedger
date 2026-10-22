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

class _UploadScreenState extends State<UploadScreen> {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  bool _isBatchMode = false;
  bool _isFlashOn = false;
  String _aspectRatio = '4:3 Crop';

  Uint8List? _selectedImageBytes;
  String? _selectedFileName;
  bool _isLoading = false;
  String? _errorMessage;

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
    } catch (e) {
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
              // Sheet Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Receipt Preview',
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

              // Thumbnail Card
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

              // Inspection Stats
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.headerBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
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

              // Primary Upload Action
              ElevatedButton(
                onPressed: _isLoading ? null : () async {
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
    final merchantCtrl = TextEditingController(text: 'Local Store');
    final amountCtrl = TextEditingController(text: '1200.0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
          // Persistent Header
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
                                                color: Colors.black.withOpacity(0.06),
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
                                                color: Colors.black.withOpacity(0.06),
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
                            _aspectRatio = _aspectRatio == '4:3 Crop' ? 'Full Crop' : '4:3 Crop';
                          });
                        },
                        icon: const Icon(Icons.crop_free, color: AppTheme.navyBrand),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Camera Viewfinder Card from CAPTURE.png
                  Container(
                    height: 400,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B), // Dark slate viewfinder background
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background textured paper receipt / user image / mock receipt slip
                        Positioned.fill(
                          child: _selectedImageBytes != null
                              ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                              : Container(
                                  color: const Color(0xFF0F172A),
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 200,
                                    height: 310,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'STORE RECEIPT',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF0F172A),
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(width: 70, height: 5, color: const Color(0xFFCBD5E1)),
                                            Container(width: 28, height: 5, color: const Color(0xFF94A3B8)),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(width: 85, height: 5, color: const Color(0xFFCBD5E1)),
                                            Container(width: 32, height: 5, color: const Color(0xFF94A3B8)),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(width: 60, height: 5, color: const Color(0xFFCBD5E1)),
                                            Container(width: 24, height: 5, color: const Color(0xFF94A3B8)),
                                          ],
                                        ),
                                        const Spacer(),
                                        // Barcode simulation
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            for (int j = 0; j < 22; j++)
                                              Container(
                                                width: j % 3 == 0 ? 3 : 1.5,
                                                height: 22,
                                                color: Colors.black,
                                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),

                        // Viewfinder 4 Corner Brackets
                        _buildViewfinderCorners(),

                        // Center guideline / scan line
                        Positioned(
                          left: 40,
                          right: 40,
                          child: Container(
                            height: 1.5,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),

                        // Top Overlay Badges
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

                        Positioned(
                          top: 14,
                          right: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
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

                        // Center Prompt Banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
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

                        // Bottom Guidance Pill
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
                              width: 56,
                              height: 56,
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

                      // Large Shutter Squircle Button from CAPTURE.png
                      GestureDetector(
                        onTap: () => _pickImage(ImageSource.camera),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.navyBrand,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.navyBrand.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.camera,
                                  color: Colors.white,
                                  size: 26,
                                ),
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
                              width: 56,
                              height: 56,
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

                  const SizedBox(height: 80), // Padding above bottom nav
                ],
              ),
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
      top: 60,
      bottom: 60,
      left: 36,
      right: 36,
      child: Stack(
        children: [
          // Top-left
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
          // Top-right
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
          // Bottom-left
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
          // Bottom-right
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
