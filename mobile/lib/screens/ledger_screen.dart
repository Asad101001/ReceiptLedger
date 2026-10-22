import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

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
    final receiptsCount = _receipts.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
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
                            Text(
                              '${_api.currency} ${totalSpend.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textDark,
                                letterSpacing: -0.5,
                              ),
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

                    // Weekly Activity Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Weekly Activity',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              Text(
                                '68% target',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Trend line & Sparkline Chart
                          SizedBox(
                            height: 36,
                            child: CustomPaint(
                              painter: _WeeklyActivityTrendPainter(),
                              size: Size.infinite,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Days of Week Row
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Mon', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              Text('Wed', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              Text(
                                'Today',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.navyBrand,
                                ),
                              ),
                              Text('Sun', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
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
                            color: AppTheme.textMuted.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 4 Category Cards Row from LEDGER.png
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Showing all $receiptsCount receipts recorded.')),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'View All ($receiptsCount)',
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
                      itemCount: _receipts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final item = _receipts[idx];
                        return _buildReceiptTile(item);
                      },
                    ),

                    const SizedBox(height: 80), // Padding above bottom nav
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(IconData icon, String name, String amount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppTheme.navyBrand),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptTile(Map<String, dynamic> r) {
    final merchant = r['merchant'] ?? 'Merchant';
    final date = r['date'] ?? 'Recent';
    final itemsCount = r['items_count'] ?? 1;
    final total = (r['total_amount'] ?? 0.0) as num;

    return GestureDetector(
      onTap: () => _showReceiptDetailDialog(r),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Clipboard Icon inside rounded squircle
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

            // Store Title & Items Subtitle
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

            // Amount & Verified Pill on right
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
    );
  }
}

/// Custom painter for the subtle sparkline trend in Weekly Activity card
class _WeeklyActivityTrendPainter extends CustomPainter {
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
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    // Gentle ascending curve from left to right
    path.moveTo(size.width * 0.05, size.height * 0.75);
    path.lineTo(size.width * 0.35, size.height * 0.65);
    path.lineTo(size.width * 0.68, size.height * 0.45); // Today's coordinate
    path.lineTo(size.width * 0.95, size.height * 0.38);

    canvas.drawPath(path, linePaint);

    // Marker on Today (around 68% width)
    final center = Offset(size.width * 0.68, size.height * 0.45);
    canvas.drawCircle(center, 5.0, dotPaint);
    canvas.drawCircle(center, 5.0, dotBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
