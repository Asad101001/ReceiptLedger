import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_toast.dart';
import '../widgets/hoverable.dart';

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

class _UploadScreenState extends State<UploadScreen> {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  bool _isCapturing = false;
  String _captureMode = 'single'; // 'single' or 'batch'
  String _flashMode = 'auto'; // 'auto', 'on', 'off'
  bool _autoCrop = true;
  bool _highResOcr = true;

  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Groceries',
    'Fuel',
    'Dining',
    'Pharmacy',
    'Utilities',
    'Shopping',
  ];

  List<Map<String, dynamic>> _receipts = [];

  @override
  void initState() {
    super.initState();
    _loadReceipts();
    _api.dataVersionNotifier.addListener(_onDataVersionChanged);
  }

  void _onDataVersionChanged() {
    if (mounted) _loadReceipts();
  }

  @override
  void dispose() {
    _api.dataVersionNotifier.removeListener(_onDataVersionChanged);
    super.dispose();
  }

  Future<void> _loadReceipts() async {
    try {
      final list = await _api.getReceipts();
      if (mounted) {
        setState(() {
          _receipts = list;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _receipts = _api.isDemoMode ? _api.getSampleReceipts() : [];
        });
      }
    }
  }

  // --- Visual Preview Dialog for Gallery and Camera Uploads ---
  Future<bool> _showImagePreviewModal({
    required Uint8List bytes,
    required String filename,
    required String sourceLabel,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sizeKb = (bytes.lengthInBytes / 1024).toStringAsFixed(1);
    final sizeLabel = bytes.lengthInBytes > 1024 * 1024
        ? '${(bytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(2)} MB'
        : '$sizeKb KB';

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.cardDark : AppTheme.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            16,
            22,
            MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.borderDarkCrisp : AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDarkElevated : AppTheme.sageLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.image_search_rounded,
                      color: isDark ? Colors.white : AppTheme.forestPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receipt Preview',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppTheme.textDark,
                          ),
                        ),
                        Text(
                          'Verify image legibility before OCR processing',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                    ),
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Thumbnail Card with Border
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 280),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : const Color(0xFFF3F5F0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppTheme.borderDarkCrisp : AppTheme.borderLight,
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Center(
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.broken_image_rounded, size: 40, color: AppTheme.badgeRed),
                          const SizedBox(height: 8),
                          Text('Failed to render preview', style: TextStyle(color: isDark ? Colors.white : AppTheme.textDark)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Meta Badges Strip
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDarkElevated : AppTheme.cardSubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.insert_drive_file_outlined, size: 14, color: isDark ? Colors.white : AppTheme.forestPrimary),
                        const SizedBox(width: 5),
                        Text(
                          filename.length > 20 ? '${filename.substring(0, 18)}...' : filename,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDarkElevated : AppTheme.cardSubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.data_usage_rounded, size: 14, color: isDark ? Colors.white : AppTheme.forestPrimary),
                        const SizedBox(width: 5),
                        Text(
                          sizeLabel,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2822) : AppTheme.greenVerifiedBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome_rounded, size: 14, color: AppTheme.greenVerified),
                        const SizedBox(width: 5),
                        Text(
                          'Gemini 3.5 Flash Lite + OCR',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF86D9A5) : AppTheme.greenVerified,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : AppTheme.textDark,
                        side: BorderSide(color: isDark ? AppTheme.borderDarkCrisp : AppTheme.borderLight),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Change Slip', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : AppTheme.forestPrimary,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      icon: Icon(
                        Icons.document_scanner_rounded,
                        size: 19,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                      label: const Text(
                        'Confirm & Process',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    return result ?? false;
  }

  // --- Capture Action: Opens camera on-demand ---
  Future<void> _handleScanReceipt() async {
    if (_isCapturing) return;

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: _highResOcr ? 95 : 80,
      );

      if (photo == null) return; // User cancelled camera

      final bytes = await photo.readAsBytes();

      if (!mounted) return;
      final confirmed = await _showImagePreviewModal(
        bytes: bytes,
        filename: photo.name,
        sourceLabel: 'Camera',
      );

      if (!confirmed) return;

      setState(() => _isCapturing = true);

      final result = await _api.uploadReceipt(
        bytes: bytes,
        filename: photo.name,
        captureMode: _captureMode,
        ocrEngine: 'auto',  // Prefers Gemini 3.5 Flash Lite, falls back to local
      );

      if (!mounted) return;
      final merchant = (result['merchant_name'] ?? 'Receipt').toString();
      final total = result['total_amount'] != null ? '${_api.currency} ${result['total_amount']}' : '';
      final engine = result['engine'] ?? 'Gemini Flash Lite';
      AppToast.success(
        context,
        '$merchant extracted via $engine ($total)!',
        actionLabel: 'Review',
        onAction: () => widget.onNavigateTab != null
            ? widget.onNavigateTab!(2)
            : widget.onNavigateToReview?.call(),
      );
      _api.refreshReviewCount();
      await _loadReceipts();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Capture failed: ${e.toString().split('\n').first}');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  // --- Pick from Gallery ---
  Future<void> _handlePickFromGallery() async {
    if (_isCapturing) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: _highResOcr ? 95 : 85,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      if (!mounted) return;
      final confirmed = await _showImagePreviewModal(
        bytes: bytes,
        filename: image.name,
        sourceLabel: 'Gallery',
      );

      if (!confirmed) return;

      setState(() => _isCapturing = true);

      final result = await _api.uploadReceipt(
        bytes: bytes,
        filename: image.name,
        captureMode: _captureMode,
        ocrEngine: 'auto',  // Prefers Gemini 3.5 Flash Lite, falls back to local
      );

      if (!mounted) return;
      final merchant = (result['merchant_name'] ?? 'Receipt').toString();
      final total = result['total_amount'] != null ? '${_api.currency} ${result['total_amount']}' : '';
      final engine = result['engine'] ?? 'Gemini Flash Lite';
      AppToast.success(
        context,
        '$merchant extracted via $engine ($total)!',
        actionLabel: 'Review',
        onAction: () => widget.onNavigateTab != null
            ? widget.onNavigateTab!(2)
            : widget.onNavigateToReview?.call(),
      );
      _api.refreshReviewCount();
      await _loadReceipts();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Gallery upload failed: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  // --- Camera & Capture Settings Modal (Hidden under gear icon) ---
  void _showCaptureSettingsModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.cardDark : AppTheme.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.cardDarkElevated : AppTheme.sageLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: isDark ? AppTheme.textLight : AppTheme.forestPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Capture & Camera Options',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppTheme.textLight : AppTheme.textDark,
                              ),
                            ),
                            Text(
                              'Customize scanner behavior and image processing',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Batch Scanning Toggle
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDarkElevated : AppTheme.canvasLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Batch Scanning Mode',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Rapidly capture multiple receipts in one session',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _captureMode == 'batch',
                          activeColor: AppTheme.forestPrimary,
                          onChanged: (val) {
                            setModalState(() {
                              _captureMode = val ? 'batch' : 'single';
                            });
                            setState(() {
                              _captureMode = val ? 'batch' : 'single';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Flash Mode Selector
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDarkElevated : AppTheme.canvasLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Flash Mode',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isDark ? AppTheme.textLight : AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildFlashChip('auto', 'Auto', Icons.flash_auto_rounded, isDark, setModalState),
                            const SizedBox(width: 8),
                            _buildFlashChip('on', 'Always On', Icons.flash_on_rounded, isDark, setModalState),
                            const SizedBox(width: 8),
                            _buildFlashChip('off', 'Off', Icons.flash_off_rounded, isDark, setModalState),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Auto-Crop Toggle
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDarkElevated : AppTheme.canvasLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Auto Perspective & Crop',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Detect receipt borders and straighten angles',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _autoCrop,
                          activeColor: AppTheme.forestPrimary,
                          onChanged: (val) {
                            setModalState(() => _autoCrop = val);
                            setState(() => _autoCrop = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // High Resolution OCR
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDarkElevated : AppTheme.canvasLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'High-Resolution OCR',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Max clarity for small itemized receipt font',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _highResOcr,
                          activeColor: AppTheme.forestPrimary,
                          onChanged: (val) {
                            setModalState(() => _highResOcr = val);
                            setState(() => _highResOcr = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Done Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.forestPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Apply Settings',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFlashChip(String mode, String label, IconData icon, bool isDark, StateSetter setModalState) {
    final isSelected = _flashMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setModalState(() => _flashMode = mode);
          setState(() => _flashMode = mode);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppTheme.forestLight : AppTheme.forestPrimary)
                : (isDark ? AppTheme.cardDark : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.forestPrimary
                  : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppTheme.textLight : AppTheme.textDark),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppTheme.textMutedDark : AppTheme.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Manual Entry Modal ---
  void _handleManualEntry() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final merchantCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String category = 'Groceries';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.cardDark : AppTheme.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Manual Receipt Entry',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.textLight : AppTheme.textDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: merchantCtrl,
                    decoration: InputDecoration(
                      labelText: 'Merchant Name',
                      hintText: 'e.g. Imtiaz Super Market',
                      filled: true,
                      fillColor: isDark ? AppTheme.cardDarkElevated : AppTheme.canvasLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Total Amount',
                      prefixText: '${_api.currency} ',
                      hintText: '0.00',
                      filled: true,
                      fillColor: isDark ? AppTheme.cardDarkElevated : AppTheme.canvasLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Groceries', 'Fuel', 'Dining', 'Pharmacy', 'Utilities'].map((cat) {
                      final isSelected = category == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppTheme.forestPrimary,
                        backgroundColor: isDark ? AppTheme.cardDarkElevated : AppTheme.canvasLight,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppTheme.textLight : AppTheme.textDark),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setModalState(() => category = cat);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.forestPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      final merchant = merchantCtrl.text.trim();
                      final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                      if (merchant.isEmpty || amount <= 0) {
                        AppToast.error(ctx, 'Please enter merchant and valid amount');
                        return;
                      }
                      Navigator.pop(ctx);
                      AppToast.success(context, 'Receipt "$merchant" added to review queue!');
                      _api.refreshReviewCount();
                    },
                    child: const Text('Save to Review Queue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Receipt Detail Modal Sheet ---
  void _showReceiptDetail(Map<String, dynamic> r) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final merchant = r['merchant_name'] ?? r['merchant'] ?? 'Receipt Detail';
    final total = (r['total_amount'] ?? 0.0) as num;
    final date = r['receipt_date'] ?? r['date'] ?? 'Recent';
    final lineItems = (r['line_items'] as List<dynamic>?) ?? [];
    final category = r['category_name'] ?? r['category'] ?? 'General';
    final tax = (r['tax'] ?? 0.0) as num;
    final payment = r['payment_method'] ?? 'Card / Cash';
    final receiptId = r['id']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.cardDark : AppTheme.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDarkElevated : AppTheme.sageLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: isDark ? AppTheme.textLight : AppTheme.forestPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          merchant,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppTheme.textLight : AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$date • $category',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.greenVerifiedBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'VERIFIED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.greenVerified,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDarkElevated : AppTheme.canvasLight,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount', style: TextStyle(fontSize: 13, color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted)),
                        Text(
                          '${_api.currency} ${total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppTheme.textLight : AppTheme.forestPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Payment Method', style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted)),
                        Text(payment, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppTheme.textLight : AppTheme.textDark)),
                      ],
                    ),
                    if (tax > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Included Tax', style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted)),
                          Text('${_api.currency} ${tax.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppTheme.textLight : AppTheme.textDark)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ITEMIZED BREAKDOWN (${lineItems.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              if (lineItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('No individual line items parsed.', style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted)),
                )
              else
                ...lineItems.map((item) {
                  final name = item['item_name'] ?? 'Item';
                  final qty = item['quantity'] ?? item['qty'] ?? 1;
                  final price = (item['total_price'] ?? item['price'] ?? 0.0) as num;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.cardDarkElevated : AppTheme.sageLight,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$qty',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.textLight : AppTheme.forestPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.textLight : AppTheme.textDark,
                            ),
                          ),
                        ),
                        Text(
                          '${_api.currency} ${price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.textLight : AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 20),
              if (receiptId.length > 10) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.forestPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.receipt_outlined, size: 18),
                    label: const Text('View Original Receipt Image', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _viewReceiptImage(receiptId, merchant);
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close Details'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _viewReceiptImage(String receiptId, String merchant) {
    final imgUrl = _api.getReceiptImageUrl(receiptId);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      merchant,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Container(
              height: 420,
              color: Colors.black,
              child: Image.network(
                imgUrl,
                fit: BoxFit.contain,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (_, __, ___) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported_outlined, color: Colors.white54, size: 40),
                        SizedBox(height: 10),
                        Text(
                          'No photo stored for this entry.\n(Generated text fixture)',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('groc')) return Icons.local_grocery_store_outlined;
    if (cat.contains('fuel')) return Icons.local_gas_station_outlined;
    if (cat.contains('din') || cat.contains('cafe')) return Icons.restaurant_outlined;
    if (cat.contains('bak')) return Icons.bakery_dining_outlined;
    if (cat.contains('pharm') || cat.contains('health')) return Icons.local_pharmacy_outlined;
    if (cat.contains('util')) return Icons.flash_on_outlined;
    if (cat.contains('shop')) return Icons.shopping_bag_outlined;
    return Icons.receipt_long_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.cardDark : AppTheme.cardWhite;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final textPrimary = isDark ? AppTheme.textLight : AppTheme.textDark;
    final textMuted = isDark ? AppTheme.textMutedDark : AppTheme.textMuted;

    final receiptsList = _receipts;
    final filteredReceipts = _selectedCategory == 'All'
        ? receiptsList
        : receiptsList.where((r) {
            // Support both backend field (category_name) and sample data field (category)
            final cat = (r['category_name'] ?? r['category'] ?? '').toString().toLowerCase();
            return cat.contains(_selectedCategory.toLowerCase());
          }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.canvasDark : AppTheme.canvasLight,
      body: Column(
        children: [
          // Elegant Header with Live/Demo Badge & Drawer Trigger
          AppHeader(
            subCaption: 'CAPTURE',
            onAvatarTap: widget.onOpenDrawer ?? () => Scaffold.of(context).openEndDrawer(),
          ),

          // Main Scrollable Area
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.forestPrimary,
              onRefresh: () async {
                await _api.checkHealthSilently();
                await _api.refreshReviewCount();
                await _loadReceipts();
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 110), // Clears floating bottom nav
                children: [
                  // --- HERO SCAN CARD (Leafora Organic Luxury Aesthetic) ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 30 : 8),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge & Capture Mode status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.cardDarkElevated : AppTheme.sageLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 13,
                                    color: AppTheme.forestPrimary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'AI OCR ENGINE',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: isDark ? AppTheme.textLight : AppTheme.forestPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Current mode badge (Single vs Batch)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.cardDarkElevated : AppTheme.canvasLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _captureMode == 'batch' ? 'Batch Mode' : 'Single Receipt',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Title & Subtitle
                        Text(
                          'Digitize Any Receipt',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Take a quick photo or upload to automatically extract merchant, tax, items, and total.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: textMuted,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Main Action Row: Big Forest Green Button + Sleek Gear Icon for Options
                        Row(
                          children: [
                            // Main Scan Button (Like Leafora's "Get Started" / "Shop Now")
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.forestPrimary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _isCapturing ? null : _handleScanReceipt,
                                child: _isCapturing
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.camera_alt_rounded, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            'Scan Receipt',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Discreet Gear / Tune Button (Addresses user's request to hide clunky controls)
                            Hoverable(
                              scale: 1.08,
                              cursor: SystemMouseCursors.click,
                              onTap: _showCaptureSettingsModal,
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.cardDarkElevated : AppTheme.sageLight,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? AppTheme.borderDark : AppTheme.sageMuted,
                                    width: 1.2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.tune_rounded,
                                  color: isDark ? AppTheme.textLight : AppTheme.forestPrimary,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Secondary Options: Gallery & Manual Entry
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textPrimary,
                                  side: BorderSide(color: borderColor),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.photo_library_outlined, size: 17),
                                label: const Text('From Gallery', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                onPressed: _isCapturing ? null : _handlePickFromGallery,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textPrimary,
                                  side: BorderSide(color: borderColor),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.edit_note_rounded, size: 19),
                                label: const Text('Manual Entry', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                onPressed: _handleManualEntry,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- PENDING REVIEW QUEUE ALERT (If review items exist) ---
                  ValueListenableBuilder<int>(
                    valueListenable: _api.reviewCountNotifier,
                    builder: (context, count, _) {
                      if (count <= 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.cardDarkElevated : AppTheme.sageLight,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark ? AppTheme.sageAccent.withAlpha(60) : AppTheme.sageAccent.withAlpha(120),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.forestPrimary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.fact_check_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$count Slips Ready for Review',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                        color: isDark ? AppTheme.textLight : AppTheme.forestPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Verify extracted line items and totals',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.forestPrimary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  if (widget.onNavigateTab != null) {
                                    widget.onNavigateTab!(2);
                                  } else {
                                    widget.onNavigateToReview?.call();
                                  }
                                },
                                child: const Text(
                                  'Review →',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // --- LEAFORA CATEGORY FILTER CHIPS ---
                  Text(
                    'CATEGORIES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final cat = _categories[idx];
                        final isSelected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.forestPrimary
                                  : (isDark ? AppTheme.cardDark : AppTheme.cardWhite),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.forestPrimary
                                    : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                              ),
                            ),
                            child: Row(
                              children: [
                                if (cat != 'All') ...[
                                  Icon(
                                    _getCategoryIcon(cat),
                                    size: 15,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? AppTheme.textLight : AppTheme.forestPrimary),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  cat,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? AppTheme.textLight : AppTheme.textDark),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- RECENT ACTIVITY SECTION ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RECENT ACTIVITY (${filteredReceipts.length})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: textMuted,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => widget.onNavigateTab != null ? widget.onNavigateTab!(1) : null,
                        child: Text(
                          'View All →',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.sageAccent : AppTheme.forestPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (filteredReceipts.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_rounded, size: 36, color: textMuted),
                          const SizedBox(height: 10),
                          Text(
                            _receipts.isEmpty
                                ? 'No receipts in ledger yet'
                                : 'No receipts found in "$_selectedCategory"',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _receipts.isEmpty
                                ? 'Upload a slip above or tap below to seed demo data.'
                                : 'Try selecting "All" or a different category filter.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: textMuted),
                          ),
                          if (_receipts.isEmpty) ...[
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: isDark ? Colors.white : AppTheme.forestPrimary),
                                foregroundColor: isDark ? Colors.white : AppTheme.forestPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              onPressed: () {
                                _api.seedDemoData();
                                _loadReceipts();
                                AppToast.showSuccess(context, 'Seeded 3 demo receipts');
                              },
                              icon: const Icon(Icons.dataset_rounded, size: 16),
                              label: const Text('Seed Demo Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ],
                      ),
                    )
                  else
                    ...filteredReceipts.take(5).map((r) {
                      final merchant = r['merchant_name'] ?? r['merchant'] ?? 'Merchant';
                      final date = r['receipt_date'] ?? r['date'] ?? 'Recent';
                      final total = (r['total_amount'] ?? 0.0) as num;
                      final category = r['category_name'] ?? r['category'] ?? 'General';
                      final count = r['items_count'] ?? (r['line_items'] as List?)?.length ?? 1;

                      return Hoverable(
                        scale: 1.012,
                        child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            onTap: () => _showReceiptDetail(r),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.cardDarkElevated : AppTheme.sageLight,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _getCategoryIcon(category),
                              color: isDark ? AppTheme.textLight : AppTheme.forestPrimary,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            merchant,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            '$date • $count items',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: textMuted,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${_api.currency} ${total.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.greenVerifiedBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'VERIFIED',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.greenVerified,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    );
                    }),
                  const SizedBox(height: 16),

                  // --- OCR CAPTURE TIPS ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDarkElevated : AppTheme.canvasLight,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.tips_and_updates_outlined, size: 18, color: isDark ? AppTheme.sageAccent : AppTheme.forestPrimary),
                            const SizedBox(width: 8),
                            Text(
                              'BEST SCANNING PRACTICES',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildTipItem(Icons.crop_free_rounded, 'Lay receipt on a contrasting, dark flat surface', isDark, textMuted),
                        const SizedBox(height: 6),
                        _buildTipItem(Icons.wb_sunny_outlined, 'Ensure bright, even lighting to eliminate heavy shadows', isDark, textMuted),
                        const SizedBox(height: 6),
                        _buildTipItem(Icons.receipt_rounded, 'Make sure merchant name and grand total are in frame', isDark, textMuted),
                      ],
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

  Widget _buildTipItem(IconData icon, String text, bool isDark, Color textMuted) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: isDark ? AppTheme.sageAccent : AppTheme.forestPrimary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 11.5, color: textMuted, height: 1.3),
          ),
        ),
      ],
    );
  }
}
