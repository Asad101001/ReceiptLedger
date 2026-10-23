import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_toast.dart';

class LedgerScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const LedgerScreen({super.key, this.onOpenDrawer});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _receipts = [];
  Map<String, dynamic>? _monthlySummary;
  String _selectedPeriod = 'Monthly';

  String? _selectedCategoryFilter;
  int _selectedDayIndex = 2; // 0=Mon, 1=Wed, 2=Today, 3=Sun
  final Map<int, String> _dayAmounts = {
    0: '8,200',
    1: '14,350',
    2: '42,850',
    3: '42,850',
  };

  String? _expandedReceiptId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final summary = await _api.getMonthlySummary(year: now.year, month: now.month);
      final receipts = await _api.getReceipts();

      setState(() {
        _monthlySummary = summary;
        _receipts = receipts;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _receipts = _api.getSampleReceipts();
        _isLoading = false;
      });
    }
  }

  void _showReceiptDetailDialog(Map<String, dynamic> r) {
    final merchant = r['merchant'] ?? 'Receipt';
    final total = r['total_amount'] ?? 0.0;
    final date = r['date'] ?? 'Recent';
    final lineItems = (r['line_items'] as List<dynamic>?) ?? [];
    final receiptId = r['id']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                merchant,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.navyBrand),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.greenVerifiedBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Verified',
                style: TextStyle(color: AppTheme.greenVerified, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 6),
              const Text(
                'Purchased Items:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
              ),
              const SizedBox(height: 8),
              if (lineItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Summary slip recorded in ledger.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: lineItems.length,
                    separatorBuilder: (_, __) => const Divider(height: 10),
                    itemBuilder: (ctx, i) {
                      final item = lineItems[i] as Map<String, dynamic>;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item['qty'] ?? 1}x ${item['item_name'] ?? 'Item'}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            '${_api.currency} ${(item['price'] ?? 0.0).toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(
                    '${_api.currency} ${total.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.navyBrand),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (receiptId.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _viewReceiptImage(receiptId, merchant);
              },
              icon: const Icon(Icons.image_outlined, size: 16),
              label: const Text('View Slip Image'),
            ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.navyBrand,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _viewReceiptImage(String receiptId, String merchant) {
    final imgUrl = _api.getReceiptImageUrl(receiptId);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(merchant, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Container(
              height: 380,
              color: Colors.black,
              child: Image.network(
                imgUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text(
                    'Preview not stored on server.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPeriodPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Monthly (October 2023)', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: _selectedPeriod == 'Monthly' ? const Icon(Icons.check, color: AppTheme.navyBrand) : null,
              onTap: () {
                setState(() => _selectedPeriod = 'Monthly');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Weekly'),
              trailing: _selectedPeriod == 'Weekly' ? const Icon(Icons.check, color: AppTheme.navyBrand) : null,
              onTap: () {
                setState(() => _selectedPeriod = 'Weekly');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('All-Time Ledger'),
              trailing: _selectedPeriod == 'All-Time' ? const Icon(Icons.check, color: AppTheme.navyBrand) : null,
              onTap: () {
                setState(() => _selectedPeriod = 'All-Time');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSpend = _monthlySummary?['total_spend'] ?? 42850.0;

    // Filter receipts if a category chip is selected
    final filteredReceipts = _selectedCategoryFilter == null
        ? _receipts
        : _receipts.where((r) {
            final cat = (r['category'] ?? '').toString().toLowerCase();
            final filter = _selectedCategoryFilter!.toLowerCase();
            return cat.contains(filter) || filter.contains(cat);
          }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Persistent Header
          AppHeader(
            subCaption: 'LEDGER',
            onAvatarTap: widget.onOpenDrawer,
          ),

          // Main Scrollable Area matching LEDGER.png
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // OCTOBER TOTAL Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'OCTOBER TOTAL',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.navyBrand,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ValueListenableBuilder<String>(
                                    valueListenable: _api.currencyNotifier,
                                    builder: (ctx, curr, _) {
                                      return Text(
                                        '$curr ${totalSpend.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.textDark,
                                          letterSpacing: -0.5,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),

                              // Monthly Dropdown Pill
                              GestureDetector(
                                onTap: _showPeriodPicker,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.borderLight),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _selectedPeriod,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.navyBrand,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.navyBrand),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Weekly Activity Card with interactive day selectors
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.borderLight),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(8),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Weekly Activity',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '68% target • ${_api.currency} ${_dayAmounts[_selectedDayIndex]}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.navyBrand,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),

                                // Trend line & Sparkline Chart
                                SizedBox(
                                  height: 40,
                                  child: CustomPaint(
                                    painter: _WeeklyActivityTrendPainter(selectedDayIndex: _selectedDayIndex),
                                    size: Size.infinite,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Days of Week Row (Interactive)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildDayLabel('Mon', 0),
                                    _buildDayLabel('Wed', 1),
                                    _buildDayLabel('Today', 2, isBold: true),
                                    _buildDayLabel('Sun', 3),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Spending Categories Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Spending Categories',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              Text(
                                'Oct 2023',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textMuted.withAlpha(200),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 4 Category Cards Row from LEDGER.png (Interactive tap to filter)
                          Row(
                            children: [
                              Expanded(child: _buildCategoryCard(Icons.shopping_bag_outlined, 'Groceries', '18.4k')),
                              const SizedBox(width: 10),
                              Expanded(child: _buildCategoryCard(Icons.storefront_outlined, 'Bakeries', '9.2k')),
                              const SizedBox(width: 10),
                              Expanded(child: _buildCategoryCard(Icons.local_gas_station_outlined, 'Fuel', '7.5k')),
                              const SizedBox(width: 10),
                              Expanded(child: _buildCategoryCard(Icons.bolt_outlined, 'Utilities', '4.6k')),
                            ],
                          ),

                          // Active Filter Indicator (if any)
                          if (_selectedCategoryFilter != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  'Filtered by: $_selectedCategoryFilter',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.navyBrand),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => setState(() => _selectedCategoryFilter = null),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      children: [
                                        Text('Clear', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                        SizedBox(width: 3),
                                        Icon(Icons.close, size: 12),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 22),

                          // Recent Receipts Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Receipts',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  AppToast.showInfo(context, 'Showing all ${filteredReceipts.length} receipts recorded.');
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(50, 30),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'View All (${filteredReceipts.length})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.headerBlueDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Receipts List
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredReceipts.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (ctx, idx) {
                              final item = filteredReceipts[idx];
                              return _buildReceiptTile(item);
                            },
                          ),

                          const SizedBox(height: 84), // Padding above bottom nav
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayLabel(String label, int index, {bool isBold = false}) {
    final isSelected = _selectedDayIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedDayIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.headerBlue.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isSelected ? 12 : 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.navyBrand : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(IconData icon, String name, String amount) {
    final isSelected = _selectedCategoryFilter == name;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryFilter = isSelected ? null : name;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.navyBrand.withAlpha(15) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.navyBrand : AppTheme.borderLight,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.navyBrand : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppTheme.navyBrand,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppTheme.navyBrand : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              amount,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isSelected ? AppTheme.navyBrand : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptTile(Map<String, dynamic> r) {
    final id = r['id']?.toString() ?? '';
    final merchant = r['merchant'] ?? 'Merchant';
    final date = r['date'] ?? 'Recent';
    final itemsCount = r['items_count'] ?? 1;
    final total = (r['total_amount'] ?? 0.0) as num;
    final lineItems = (r['line_items'] as List<dynamic>?) ?? [];
    final isExpanded = _expandedReceiptId == id;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedReceiptId = isExpanded ? null : id;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      color: AppTheme.navyBrand,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          merchant,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$date • $itemsCount items',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '-${_api.currency} ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.greenVerifiedBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.greenVerified,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expandable in-line detail preview
          if (isExpanded) ...[
            const Divider(height: 1, indent: 14, endIndent: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFF8FAFC),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (lineItems.isNotEmpty)
                    ...lineItems.take(3).map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item['qty']}x ${item['item_name']}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
                            ),
                            Text(
                              '${_api.currency} ${(item['price'] ?? 0.0).toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showReceiptDetailDialog(r),
                        icon: const Icon(Icons.fullscreen, size: 16),
                        label: const Text('View Full Slip', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom painter for the subtle sparkline trend in Weekly Activity card
class _WeeklyActivityTrendPainter extends CustomPainter {
  final int selectedDayIndex;

  _WeeklyActivityTrendPainter({this.selectedDayIndex = 2});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = AppTheme.navyBrand
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.05, size.height * 0.75);
    path.lineTo(size.width * 0.35, size.height * 0.65);
    path.lineTo(size.width * 0.68, size.height * 0.45);
    path.lineTo(size.width * 0.95, size.height * 0.38);

    canvas.drawPath(path, linePaint);

    // Dynamic marker based on selected day
    Offset center;
    switch (selectedDayIndex) {
      case 0:
        center = Offset(size.width * 0.05, size.height * 0.75);
        break;
      case 1:
        center = Offset(size.width * 0.35, size.height * 0.65);
        break;
      case 2:
        center = Offset(size.width * 0.68, size.height * 0.45);
        break;
      case 3:
        center = Offset(size.width * 0.95, size.height * 0.38);
        break;
      default:
        center = Offset(size.width * 0.68, size.height * 0.45);
        break;
    }

    canvas.drawCircle(center, 5.5, dotPaint);
    canvas.drawCircle(center, 5.5, dotBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _WeeklyActivityTrendPainter oldDelegate) =>
      oldDelegate.selectedDayIndex != selectedDayIndex;
}
