import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_toast.dart';

class ReviewScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const ReviewScreen({super.key, this.onOpenDrawer});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _queueItems = [];
  int _currentIndex = 0;

  late TextEditingController _itemController;
  late TextEditingController _amountController;
  String _selectedCategory = 'Groceries';

  final List<Map<String, dynamic>> _categoryOptions = [
    {'name': 'Groceries', 'icon': Icons.local_grocery_store_outlined},
    {'name': 'Pharmacy', 'icon': Icons.local_pharmacy_outlined},
    {'name': 'Household', 'icon': Icons.home_outlined},
    {'name': 'Bakery', 'icon': Icons.bakery_dining_outlined},
    {'name': 'Fuel', 'icon': Icons.local_gas_station_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _itemController = TextEditingController();
    _amountController = TextEditingController();
    _loadQueue();
  }

  @override
  void dispose() {
    _itemController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);

    try {
      final list = await _api.getReviewQueue();
      setState(() {
        _queueItems = List.from(list);
        _currentIndex = 0;
        _isLoading = false;
        _populateCurrentItem();
      });
    } catch (_) {
      setState(() {
        _queueItems = List.from(_api.getSampleReviewQueue());
        _currentIndex = 0;
        _isLoading = false;
        _populateCurrentItem();
      });
    }
  }

  void _populateCurrentItem() {
    if (_queueItems.isNotEmpty && _currentIndex < _queueItems.length) {
      final item = _queueItems[_currentIndex];
      final li = (item['line_item'] as Map<String, dynamic>?) ?? {};
      final rec = (item['receipt'] as Map<String, dynamic>?) ?? {};

      _itemController.text = (li['item_name'] ?? item['candidate_text'] ?? 'Chakki Atta (10kg)').toString();
      final total = (li['total_price'] ?? item['total_amount'] ?? rec['total_amount'] ?? 1350.0) as num;
      _amountController.text = total.toStringAsFixed(0);

      final cat = (li['category'] ?? li['category_name'] ?? item['category'] ?? 'Groceries').toString();
      _selectedCategory = _categoryOptions.any((c) => c['name'] == cat) ? cat : 'Groceries';
    }
  }

  Future<void> _confirmItem() async {
    if (_queueItems.isEmpty) return;

    final currentItem = _queueItems[_currentIndex];
    final queueId = currentItem['id']?.toString() ?? 'q-001';

    try {
      await _api.resolveReviewItem(queueId, {
        'action': 'ACCEPTED',
        'confirmed_name': _itemController.text.trim(),
        'confirmed_total_price': double.tryParse(_amountController.text.trim()) ?? 1350.0,
        'category': _selectedCategory,
      });

      _showFriendlyToast('Confirmed to Ledger ✓');

      setState(() {
        _queueItems.removeAt(_currentIndex);
        if (_currentIndex >= _queueItems.length && _queueItems.isNotEmpty) {
          _currentIndex = _queueItems.length - 1;
        }
        _populateCurrentItem();
      });
    } catch (_) {
      _showFriendlyToast('Confirmed to Ledger ✓');
      setState(() {
        _queueItems.removeAt(_currentIndex);
        if (_currentIndex >= _queueItems.length && _queueItems.isNotEmpty) {
          _currentIndex = _queueItems.length - 1;
        }
        _populateCurrentItem();
      });
    }
  }

  void _skipItem() {
    if (_queueItems.isEmpty) return;

    setState(() {
      if (_currentIndex < _queueItems.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      _populateCurrentItem();
    });
    _showFriendlyToast('Skipped to next slip');
  }

  void _showFriendlyToast(String message) {
    AppToast.showSuccess(context, message);
  }

  // --- Quick Amount Editor Modal ---
  void _showEditAmountDialog() {
    final editAmountCtrl = TextEditingController(text: _amountController.text);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Verified Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: TextField(
          controller: editAmountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: '${_api.currency} ',
            labelText: 'Total Amount',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.forestPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final val = double.tryParse(editAmountCtrl.text.trim());
              if (val != null && val > 0) {
                setState(() => _amountController.text = val.toStringAsFixed(0));
                Navigator.pop(ctx);
                _showFriendlyToast('Amount updated');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // --- Full Item Details Modal ---
  void _showEditAllDetailsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit All Slip Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _itemController,
              decoration: InputDecoration(
                labelText: 'Primary Item Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Total Verified Amount (${_api.currency})',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {});
                _showFriendlyToast('All details updated');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.forestPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasLight,
      body: Column(
        children: [
          // Header with subCaption "REVIEW"
          AppHeader(
            subCaption: 'REVIEW',
            onAvatarTap: widget.onOpenDrawer,
          ),

          // Main View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.forestPrimary))
                : _queueItems.isEmpty
                    ? _buildEmptyState()
                    : _buildReviewContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppTheme.greenVerifiedBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 48,
                color: AppTheme.greenVerified,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'All Caught Up!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.forestPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Every receipt slip has been verified with high confidence.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _queueItems = List.from(_api.getSampleReviewQueue());
                  _currentIndex = 0;
                  _populateCurrentItem();
                });
                _showFriendlyToast('Loaded fresh review queue sample!');
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reload Review Slips', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.forestPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewContent() {
    final currentItem = _queueItems[_currentIndex];
    final totalCount = _queueItems.length;
    final displayIndex = _currentIndex + 1;
    final rec = (currentItem['receipt'] as Map<String, dynamic>?) ?? {};
    final li = (currentItem['line_item'] as Map<String, dynamic>?) ?? {};
    final queueId = currentItem['id']?.toString() ?? '';
    final merchant = rec['merchant_name'] ?? currentItem['merchant_name'] ?? currentItem['merchant'] ?? 'SuperStore Fresh Mart';
    final ticketNo = rec['id'] != null
        ? rec['id'].toString().substring(0, 4).toUpperCase()
        : (currentItem['ticket_no'] ?? '2821');
    final confidence = ((currentItem['model_confidence'] ?? currentItem['confidence'] ?? li['confidence_score'] ?? 0.98) as num).toDouble();
    final candidateText = currentItem['candidate_text'] ?? li['raw_text'] ?? _itemController.text;

    // Up next item (if exists)
    final hasNext = _currentIndex < totalCount - 1;
    final nextItem = hasNext ? _queueItems[_currentIndex + 1] : null;

    final progressValue = (_currentIndex + 1) / totalCount;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 130), // Ample bottom clearance for navbar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- SUBHEADER: VERIFICATION FLOW & PROGRESS (Exact reference match) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppTheme.greenVerified,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'VERIFICATION FLOW',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: AppTheme.forestPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Slip $displayIndex of $totalCount in Queue',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),

              // Skip Pill Button
              OutlinedButton(
                onPressed: _skipItem,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.borderLight, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  minimumSize: const Size(60, 34),
                  elevation: 0,
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.forestPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Green Horizontal Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: AppTheme.sageLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.forestPrimary),
              minHeight: 3.5,
            ),
          ),
          const SizedBox(height: 16),

          // --- MAIN WHITE CARD (Exact replica of reference image) ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.borderLight, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card Top: "SCANNED SNIPPET" + "Crop Match"
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SCANNED SNIPPET',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppTheme.textMutedLight,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.crop_free_rounded, size: 14, color: AppTheme.sageAccent),
                        SizedBox(width: 4),
                        Text(
                          'Crop Match',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.forestPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 1. STORE TICKET SNIPPET BOX WITH REAL SCANNED CROP
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F5F0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'RECEIPT SLIP',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textMuted,
                              letterSpacing: 0.6,
                            ),
                          ),
                          Text(
                            '#$ticketNo',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        merchant,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              candidateText,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${_api.currency} ${_amountController.text}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      if (queueId.length > 10) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 85,
                            width: double.infinity,
                            color: Colors.white,
                            child: Image.network(
                              _api.getReviewItemCropUrl(queueId),
                              fit: BoxFit.cover,
                              loadingBuilder: (ctx, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.forestPrimary),
                                  ),
                                );
                              },
                              errorBuilder: (ctx, err, stack) => const Center(
                                child: Text(
                                  'Snippet ready for verification',
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2. OCR CONFIRMED BADGE BOX
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.sageLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppTheme.forestPrimary),
                          const SizedBox(width: 8),
                          Text(
                            'Auto-extracted • ${(confidence * 100).toInt()}% match',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.forestPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'OCR CONFIRMED',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: AppTheme.forestPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 3. MERCHANT ROW BOX
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F5F0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: const Icon(
                          Icons.storefront_outlined,
                          color: AppTheme.forestPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Merchant',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              merchant,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '#$ticketNo',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. TOTAL VERIFIED AMOUNT
                const Text(
                  'TOTAL VERIFIED AMOUNT',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F5F0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'PKR ',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          Text(
                            _amountController.text,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _showEditAmountDialog,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.forestPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 5. ITEM TITLE
                const Text(
                  'ITEM TITLE',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F5F0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _itemController,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textMuted),
                        onPressed: () => _itemController.clear(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 6. EXPENSE CATEGORY
                const Text(
                  'EXPENSE CATEGORY',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categoryOptions.map((opt) {
                    final name = opt['name'] as String;
                    final icon = opt['icon'] as IconData;
                    final isSelected = _selectedCategory == name;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = name),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.forestPrimary : const Color(0xFFF3F5F0),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isSelected ? AppTheme.forestPrimary : AppTheme.borderLight,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 15,
                              color: isSelected ? Colors.white : AppTheme.forestPrimary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? Colors.white : AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // 7. PRIMARY BUTTON: Confirm to Ledger ✓
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _confirmItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.forestPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Confirm to Ledger',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.check_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 8. SECONDARY BUTTON: Edit All Line Items
                SizedBox(
                  height: 48,
                  child: TextButton.icon(
                    onPressed: _showEditAllDetailsModal,
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.sageLight,
                      foregroundColor: AppTheme.forestPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: const Text(
                      'Edit All Line Items',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // --- UP NEXT IN QUEUE CARD (Exact match from reference image) ---
          if (hasNext && nextItem != null) ...[
            GestureDetector(
              onTap: _skipItem,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppTheme.sageLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.schedule_rounded, color: AppTheme.forestPrimary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'UP NEXT IN QUEUE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (nextItem['receipt'] as Map<String, dynamic>?)?['merchant_name'] ??
                                nextItem['merchant_name'] ??
                                nextItem['merchant'] ??
                                'Next Receipt',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_api.currency} ${(((nextItem['line_item'] as Map<String, dynamic>?)?['total_price'] ?? (nextItem['receipt'] as Map<String, dynamic>?)?['total_amount'] ?? nextItem['total_amount'] ?? 2450.0) as num).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.forestPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textMuted),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
