import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_toast.dart';
import '../widgets/hoverable.dart';
import '../widgets/category_badge.dart';

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
  String _selectedPeriod = 'Monthly'; // 'Monthly', 'Weekly', 'All-Time'

  String? _selectedCategoryFilter;
  int? _selectedDayIndex; // null = all days of week, 0..6 = Monday..Sunday

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static const List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String? _expandedReceiptId;

  @override
  void initState() {
    super.initState();
    _loadData();
    _api.dataVersionNotifier.addListener(_onDataVersionChanged);
    _api.currencyNotifier.addListener(_onCurrencyChanged);
  }

  void _onDataVersionChanged() {
    if (mounted) _loadData();
  }

  void _onCurrencyChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _api.dataVersionNotifier.removeListener(_onDataVersionChanged);
    _api.currencyNotifier.removeListener(_onCurrencyChanged);
    super.dispose();
  }

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    return DateTime.tryParse(val.toString());
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final receipts = await _api.getReceipts();

      if (mounted) {
        setState(() {
          _receipts = receipts;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _receipts = [];
          _isLoading = false;
        });
      }
    }
  }

  void _showReceiptDetailDialog(Map<String, dynamic> r) {
    final merchant = r['merchant_name'] ?? r['merchant'] ?? 'Receipt';
    final total = ((r['total_amount'] ?? 0.0) as num).toDouble();
    final date = r['receipt_date'] ?? r['date'] ?? 'Recent';
    final category = r['category_name'] ?? r['category'] ?? 'Groceries';
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
              Row(
                children: [
                  Text(
                    date,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  CategoryBadge(
                    category: category,
                    size: CategoryBadgeSize.small,
                  ),
                ],
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
                      final qty = item['quantity'] ?? item['qty'] ?? 1;
                      final price = ((item['total_price'] ?? item['price'] ?? 0.0) as num).toDouble();
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${qty}x ${item['item_name'] ?? 'Item'}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            _api.formatCurrency(price),
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
                    _api.formatCurrency(total),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.navyBrand),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (receiptId.isNotEmpty) ...[
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
              onPressed: () async {
                final nav = Navigator.of(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('Delete Receipt'),
                    content: Text('Are you sure you want to delete "$merchant" from the ledger?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  nav.pop();
                  await _api.deleteReceipt(receiptId);
                  if (mounted) {
                    AppToast.success(context, 'Receipt "$merchant" deleted');
                    _loadData();
                  }
                }
              },
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Delete'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _viewReceiptImage(receiptId, merchant);
              },
              icon: const Icon(Icons.image_outlined, size: 16),
              label: const Text('View Slip Image'),
            ),
          ],
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

  void _showPeriodPicker() {
    final now = DateTime.now();
    final monthName = _months[now.month - 1];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Monthly ($monthName ${now.year})', style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: _selectedPeriod == 'Monthly' ? const Icon(Icons.check, color: AppTheme.navyBrand) : null,
              onTap: () {
                setState(() {
                  _selectedPeriod = 'Monthly';
                  _selectedDayIndex = null;
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Weekly (This Week)', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: _selectedPeriod == 'Weekly' ? const Icon(Icons.check, color: AppTheme.navyBrand) : null,
              onTap: () {
                setState(() {
                  _selectedPeriod = 'Weekly';
                  _selectedDayIndex = null;
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('All-Time Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: _selectedPeriod == 'All-Time' ? const Icon(Icons.check, color: AppTheme.navyBrand) : null,
              onTap: () {
                setState(() {
                  _selectedPeriod = 'All-Time';
                  _selectedDayIndex = null;
                });
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
    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1 = Monday, 7 = Sunday
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: currentWeekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    // Calculate weekly 7-day spending distribution
    final weeklyDayAmounts = List<double>.filled(7, 0.0);
    for (final r in _receipts) {
      final d = _parseDate(r['receipt_date'] ?? r['date']);
      if (d != null) {
        if (d.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && d.isBefore(endOfWeek)) {
          final dayIdx = (d.weekday - 1).clamp(0, 6);
          weeklyDayAmounts[dayIdx] += ((r['total_amount'] ?? 0.0) as num).toDouble();
        }
      }
    }
    final weekTotal = weeklyDayAmounts.fold(0.0, (sum, v) => sum + v);

    // Period filter
    List<Map<String, dynamic>> periodReceipts;
    String periodTitle;

    if (_selectedPeriod == 'Weekly') {
      periodTitle = "THIS WEEK'S TOTAL";
      periodReceipts = _receipts.where((r) {
        final d = _parseDate(r['receipt_date'] ?? r['date']);
        if (d == null) return false;
        return d.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && d.isBefore(endOfWeek);
      }).toList();
    } else if (_selectedPeriod == 'All-Time') {
      periodTitle = "ALL-TIME TOTAL";
      periodReceipts = List.from(_receipts);
    } else {
      // Monthly default
      final curMonth = now.month;
      final curYear = now.year;
      final monthName = _months[curMonth - 1].toUpperCase();
      periodTitle = "$monthName TOTAL";
      periodReceipts = _receipts.where((r) {
        final d = _parseDate(r['receipt_date'] ?? r['date']);
        if (d == null) return true;
        return d.year == curYear && d.month == curMonth;
      }).toList();
    }

    final periodTotal = periodReceipts.fold<double>(
      0.0,
      (sum, r) => sum + ((r['total_amount'] ?? 0.0) as num).toDouble(),
    );

    // Compute dynamic categories breakdown from period receipts
    final Map<String, double> categorySums = {};
    for (final r in periodReceipts) {
      final cat = (r['category_name'] ?? r['category'] ?? 'Other').toString();
      final amt = ((r['total_amount'] ?? 0.0) as num).toDouble();
      categorySums[cat] = (categorySums[cat] ?? 0.0) + amt;
    }
    final sortedCategories = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Filter by selected day (if selected from Weekly Activity)
    List<Map<String, dynamic>> displayReceipts = List.from(periodReceipts);
    if (_selectedDayIndex != null) {
      final targetDay = startOfWeek.add(Duration(days: _selectedDayIndex!));
      displayReceipts = displayReceipts.where((r) {
        final d = _parseDate(r['receipt_date'] ?? r['date']);
        if (d == null) return false;
        return d.year == targetDay.year && d.month == targetDay.month && d.day == targetDay.day;
      }).toList();
    }

    // Filter receipts if a category chip is selected
    if (_selectedCategoryFilter != null) {
      final filter = _selectedCategoryFilter!.toLowerCase();
      displayReceipts = displayReceipts.where((r) {
        final cat = (r['category_name'] ?? r['category'] ?? '').toString().toLowerCase();
        return cat.contains(filter) || filter.contains(cat);
      }).toList();
    }

    final double activeDayAmount = _selectedDayIndex != null ? weeklyDayAmounts[_selectedDayIndex!] : weekTotal;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Persistent Header
          AppHeader(
            subCaption: 'LEDGER',
            onAvatarTap: widget.onOpenDrawer,
          ),

          // Main Scrollable Area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TOTAL Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    periodTitle,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.navyBrand,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _api.formatCurrency(periodTotal),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.textDark,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),

                              // Period Dropdown Pill
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

                          // Weekly Activity Card with 7-day interactive selectors
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
                                        _selectedDayIndex != null
                                            ? '${_dayNames[_selectedDayIndex!]} • ${_api.formatCurrency(activeDayAmount)}'
                                            : 'This Week • ${_api.formatCurrency(activeDayAmount)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.navyBrand,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Dynamic Trend line Sparkline
                                SizedBox(
                                  height: 48,
                                  child: RepaintBoundary(
                                    child: CustomPaint(
                                      painter: _WeeklyActivityTrendPainter(
                                        dailyAmounts: weeklyDayAmounts,
                                        selectedDayIndex: _selectedDayIndex,
                                      ),
                                      size: Size.infinite,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // 7 Days of Week Interactive Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: List.generate(7, (idx) {
                                    final isToday = idx == (currentWeekday - 1);
                                    return _buildDayLabel(
                                      _dayNames[idx],
                                      idx,
                                      isToday: isToday,
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Dynamic Category Velocity Bar
                          _buildCategoryDistributionBar(categorySums),

                          const SizedBox(height: 18),

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
                                '${sortedCategories.length} Active',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textMuted.withAlpha(200),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Dynamic Category Cards Row
                          if (sortedCategories.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.borderLight),
                              ),
                              child: const Center(
                                child: Text('No spending categories in this period', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                              ),
                            )
                          else
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: sortedCategories.take(6).map((entry) {
                                  final catStyle = CategoryTheme.getStyle(entry.key);
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: SizedBox(
                                      width: 82,
                                      child: _buildCategoryCard(
                                        catStyle.icon,
                                        catStyle.label,
                                        _api.formatCurrency(entry.value),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                          // Active Filter Indicator (if any)
                          if (_selectedCategoryFilter != null || _selectedDayIndex != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                if (_selectedCategoryFilter != null) ...[
                                  Text(
                                    'Category: $_selectedCategoryFilter',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.navyBrand),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (_selectedDayIndex != null) ...[
                                  Text(
                                    'Day: ${_dayNames[_selectedDayIndex!]}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.navyBrand),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategoryFilter = null;
                                      _selectedDayIndex = null;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      children: [
                                        Text('Clear Filter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
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

                          // Receipts Section Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recorded Receipts',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              Text(
                                '${displayReceipts.length} slips',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.headerBlueDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Receipts List
                          if (displayReceipts.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.borderLight),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.receipt_long_outlined, size: 40, color: AppTheme.textMuted),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'No receipts found in this view',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedCategoryFilter != null || _selectedDayIndex != null
                                        ? 'Try clearing the active filters above.'
                                        : 'Scan a receipt or bill to add it to your ledger.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: displayReceipts.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (ctx, idx) {
                                final item = displayReceipts[idx];
                                return _buildReceiptTile(item);
                              },
                            ),

                          const SizedBox(height: 110), // Padding above bottom nav
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayLabel(String label, int index, {bool isToday = false}) {
    final isSelected = _selectedDayIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDayIndex = isSelected ? null : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.navyBrand
              : (isToday ? AppTheme.headerBlue.withAlpha(35) : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          isToday && !isSelected ? 'Today' : label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Colors.white
                : (isToday ? AppTheme.navyBrand : AppTheme.textMuted),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDistributionBar(Map<String, double> categories) {
    final double total = categories.values.fold<double>(0.0, (sum, val) => sum + val);
    if (total <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
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
                'SPENDING VELOCITY BREAKDOWN',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppTheme.textMuted,
                ),
              ),
              Text(
                '${categories.length} Streams',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navyBrand,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Multi-color segmented metric bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: Row(
                children: categories.entries.map((entry) {
                  final catStyle = CategoryTheme.getStyle(entry.key);
                  final amount = entry.value;
                  final double pct = amount / total;
                  final isSelected = _selectedCategoryFilter == catStyle.label ||
                      _selectedCategoryFilter == entry.key;

                  return Expanded(
                    flex: (pct * 1000).toInt().clamp(1, 1000),
                    child: Tooltip(
                      message: '${catStyle.label}: ${(pct * 100).toStringAsFixed(1)}%',
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategoryFilter = isSelected ? null : catStyle.label;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 0.8),
                          decoration: BoxDecoration(
                            color: catStyle.primary,
                            borderRadius: BorderRadius.circular(4),
                            border: isSelected ? Border.all(color: Colors.black, width: 1.5) : null,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Interactive category legend chips with colorful pill dots and percentage
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: categories.entries.map((entry) {
              final catStyle = CategoryTheme.getStyle(entry.key);
              final amount = entry.value;
              final double pct = amount / total;
              final isSelected = _selectedCategoryFilter == catStyle.label ||
                  _selectedCategoryFilter == entry.key;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategoryFilter = isSelected ? null : catStyle.label;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? catStyle.primary
                        : catStyle.backgroundColor(false),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? catStyle.primary : catStyle.borderColor(false),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.white : catStyle.primary,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${catStyle.label} ${(pct * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : catStyle.primary,
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
    );
  }

  Widget _buildCategoryCard(IconData icon, String name, String formattedAmount) {
    final isSelected = _selectedCategoryFilter == name;
    final catStyle = CategoryTheme.getStyle(name);

    return Hoverable(
      scale: 1.03,
      cursor: SystemMouseCursors.click,
      onTap: () {
        setState(() {
          _selectedCategoryFilter = isSelected ? null : name;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? catStyle.primary.withAlpha(22) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? catStyle.primary : AppTheme.borderLight,
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
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isSelected ? catStyle.primary : catStyle.backgroundColor(false),
                shape: BoxShape.circle,
              ),
              child: Icon(
                catStyle.icon,
                size: 16,
                color: isSelected ? Colors.white : catStyle.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 10.0,
                color: isSelected ? catStyle.primary : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              formattedAmount,
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w800,
                color: isSelected ? catStyle.primary : AppTheme.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptTile(Map<String, dynamic> r) {
    final id = r['id']?.toString() ?? '';
    final merchant = r['merchant_name'] ?? r['merchant'] ?? 'Merchant';
    final date = r['receipt_date'] ?? r['date'] ?? 'Recent';
    final itemsCount = r['items_count'] ?? (r['line_items'] as List?)?.length ?? 1;
    final total = ((r['total_amount'] ?? 0.0) as num).toDouble();
    final lineItems = (r['line_items'] as List<dynamic>?) ?? [];
    final category = r['category_name'] ?? r['category'] ?? 'Groceries';
    final isExpanded = _expandedReceiptId == id;

    return Hoverable(
      scale: 1.012,
      child: Container(
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
                    CategoryAvatar(category: category, size: 44, iconSize: 22),
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
                          Row(
                            children: [
                              Text(
                                '$date • $itemsCount items',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(width: 6),
                              CategoryBadge(
                                category: category,
                                size: CategoryBadgeSize.small,
                                showIcon: false,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '-${_api.formatCurrency(total)}',
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
                        final price = ((item['total_price'] ?? item['price'] ?? 0.0) as num).toDouble();
                        final qty = item['quantity'] ?? item['qty'] ?? 1;
                        final name = item['item_name'] ?? 'Item';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${qty}x $name',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
                              ),
                              Text(
                                _api.formatCurrency(price),
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
      ),
    );
  }
}

/// Custom painter for dynamic 7-day sparkline trend in Weekly Activity card
class _WeeklyActivityTrendPainter extends CustomPainter {
  final List<double> dailyAmounts;
  final int? selectedDayIndex;

  _WeeklyActivityTrendPainter({
    required this.dailyAmounts,
    this.selectedDayIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeColor = AppTheme.forestPrimary;
    final w = size.width;
    final h = size.height;

    final double maxAmt = dailyAmounts.fold(0.0, (m, v) => v > m ? v : m);

    // Compute coordinates for 7 points
    final List<Offset> points = [];
    for (int i = 0; i < 7; i++) {
      final double x = w * (0.04 + 0.92 * (i / 6.0));
      double norm = 0.0;
      if (maxAmt > 0) {
        norm = (dailyAmounts[i] / maxAmt).clamp(0.0, 1.0);
      }
      final double y = h * (0.85 - 0.70 * norm);
      points.add(Offset(x, y));
    }

    final linePath = Path();
    linePath.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final pCurrent = points[i];
      final pNext = points[i + 1];
      final midX = (pCurrent.dx + pNext.dx) / 2;
      linePath.cubicTo(
        midX, pCurrent.dy,
        midX, pNext.dy,
        pNext.dx, pNext.dy,
      );
    }

    // Gradient area below curve
    final fillPath = Path.from(linePath);
    fillPath.lineTo(points.last.dx, h);
    fillPath.lineTo(points.first.dx, h);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          strokeColor.withOpacity(0.20),
          strokeColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawPath(linePath, linePaint);

    // Determine dynamic marker offset based on selected day (or none)
    if (selectedDayIndex != null && selectedDayIndex! >= 0 && selectedDayIndex! < 7) {
      final center = points[selectedDayIndex!];

      // Outer glow halo
      final haloPaint = Paint()
        ..color = strokeColor.withOpacity(0.22)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 9.0, haloPaint);

      // Marker with white border
      final dotPaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.fill;
      final dotBorderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(center, 5.0, dotPaint);
      canvas.drawCircle(center, 5.0, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyActivityTrendPainter oldDelegate) =>
      oldDelegate.selectedDayIndex != selectedDayIndex ||
      oldDelegate.dailyAmounts != dailyAmounts;
}
