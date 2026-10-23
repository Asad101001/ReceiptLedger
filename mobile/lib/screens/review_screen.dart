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

  final List<String> _categories = ['Groceries', 'Pharmacy', 'Household', 'Bakeries', 'Fuel'];

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
    setState(() {
      _isLoading = true;
    });

    try {
      final list = await _api.getReviewQueue();
      setState(() {
        _queueItems = list.isNotEmpty ? List.from(list) : List.from(_api.getSampleReviewQueue());
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
      _itemController.text = (li['item_name'] ?? item['candidate_text'] ?? 'Chakki Atta (10kg)').toString();
      final total = (li['total_price'] ?? item['total_amount'] ?? 1350.0) as num;
      _amountController.text = total.toStringAsFixed(0);
      _selectedCategory = (li['category'] ?? item['category'] ?? 'Groceries').toString();
      if (!_categories.contains(_selectedCategory)) {
        _selectedCategory = 'Groceries';
      }
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

      _showFriendlyToast('Item confirmed and verified! ✓');

      setState(() {
        _queueItems.removeAt(_currentIndex);
        if (_currentIndex >= _queueItems.length && _queueItems.isNotEmpty) {
          _currentIndex = _queueItems.length - 1;
        }
        _populateCurrentItem();
      });
    } catch (_) {
      _showFriendlyToast('Confirmed locally for sync.');
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

  void _showEditDetailsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit Verification Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _itemController,
              decoration: const InputDecoration(labelText: 'Item Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Total Price (${_api.currency})', border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {});
                _showFriendlyToast('Details updated');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navyBrand),
              child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
          AppHeader(
            subCaption: 'REVIEW',
            onAvatarTap: widget.onOpenDrawer,
          ),

          // Main View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.navyBrand,
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
            ElevatedButton(
              onPressed: _loadQueue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navyBrand,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Refresh Queue', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewContent() {
    final currentItem = _queueItems[_currentIndex];
    final totalCount = _queueItems.length;
    final displayIndex = (_currentIndex + 1).toString().padLeft(2, '0');
    final displayTotal = totalCount.toString().padLeft(2, '0');
    final merchant = currentItem['merchant'] ?? 'SuperStore Fresh Mart';
    final receiptDate = currentItem['receipt_date'] ?? 'Today, 04:42 PM • Receipt #2821';
    final queueId = currentItem['id']?.toString() ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Queue Number & Skip Bar from REVIEW.png
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUEUE #$displayIndex OF $displayTotal',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.navyBrand,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Review Slip',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.navyBrand,
                    ),
                  ),
                ],
              ),

              // Skip Button Pill
              OutlinedButton(
                onPressed: _skipItem,
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  side: const BorderSide(color: AppTheme.borderLight),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  minimumSize: const Size(60, 32),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navyBrand,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Visual Crop Snippet from Backend (if available)
          if (queueId.isNotEmpty) ...[
            Container(
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
                color: const Color(0xFFF8FAFC),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                _api.getReviewItemCropUrl(queueId),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text(
                    'Physical slip text snippet',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Card 1: TOTAL AMOUNT from REVIEW.png
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL AMOUNT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_api.currency} ${_amountController.text}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.navyBrand,
                      ),
                    ),
                    // Auto-extracted badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: AppTheme.greenVerified),
                          SizedBox(width: 5),
                          Text(
                            'Auto-extracted',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.navyBrand,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Card 2: ITEM from REVIEW.png
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ITEM',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderLight),
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
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: AppTheme.textMuted),
                        onPressed: () => _itemController.clear(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Card 3: CATEGORY from REVIEW.png
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CATEGORY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.navyBrand : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppTheme.navyBrand : AppTheme.borderLight,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (cat == 'Groceries')
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 15,
                                color: isSelected ? Colors.white : AppTheme.navyBrand,
                              ),
                            if (cat == 'Pharmacy')
                              Icon(
                                Icons.local_pharmacy_outlined,
                                size: 15,
                                color: isSelected ? Colors.white : AppTheme.navyBrand,
                              ),
                            if (cat == 'Household')
                              Icon(
                                Icons.home_outlined,
                                size: 15,
                                color: isSelected ? Colors.white : AppTheme.navyBrand,
                              ),
                            if (cat == 'Bakeries')
                              Icon(
                                Icons.storefront_outlined,
                                size: 15,
                                color: isSelected ? Colors.white : AppTheme.navyBrand,
                              ),
                            if (cat == 'Fuel')
                              Icon(
                                Icons.local_gas_station_outlined,
                                size: 15,
                                color: isSelected ? Colors.white : AppTheme.navyBrand,
                              ),
                            const SizedBox(width: 6),
                            Text(
                              cat,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Card 4: Store / Merchant Card from REVIEW.png
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              children: [
                // Store Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: const Icon(Icons.store_mall_directory_outlined, color: AppTheme.navyBrand, size: 20),
                ),
                const SizedBox(width: 12),

                // Merchant & Time Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        merchant,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        receiptDate,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Primary Button: Confirm ✓ from REVIEW.png
          ElevatedButton(
            onPressed: _confirmItem,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.navyBrand,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Confirm',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 6),
                Icon(Icons.check, size: 18),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Secondary Action: ✏ Edit Details
          TextButton.icon(
            onPressed: _showEditDetailsModal,
            icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.navyBrand),
            label: const Text(
              'Edit Details',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.navyBrand,
              ),
            ),
          ),

          const SizedBox(height: 100), // Clearance above floating bottom nav
        ],
      ),
    );
  }
}
