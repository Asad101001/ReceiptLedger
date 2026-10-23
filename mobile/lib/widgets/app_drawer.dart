import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'app_toast.dart';

/// Improved Sidebar Drawer with Theme Toggle & Integrated Settings
class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final ApiService _api = ApiService();
  bool _biometricsEnabled = true;

  void _showCurrencySelector() {
    final currencies = [
      {'code': 'PKR', 'symbol': 'Rs.', 'name': 'Pakistani Rupee'},
      {'code': 'USD', 'symbol': r'$', 'name': 'US Dollar'},
      {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
      {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
      {'code': 'AED', 'symbol': 'AED', 'name': 'UAE Dirham'},
      {'code': 'SAR', 'symbol': 'SAR', 'name': 'Saudi Riyal'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Currency',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppTheme.textDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ...currencies.map((curr) {
                  final isSelected = _api.currency == curr['code'] || _api.currency == curr['symbol'];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 2),
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xFF22352A) : AppTheme.sageLight)
                            : (isDark ? AppTheme.cardDarkElevated : const Color(0xFFF3F5F0)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        curr['symbol']!,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: isSelected
                              ? (isDark ? const Color(0xFF86AB93) : AppTheme.forestPrimary)
                              : AppTheme.textMuted,
                        ),
                      ),
                    ),
                    title: Text(
                      curr['name']!,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 15,
                        color: isDark ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                    subtitle: Text(
                      curr['code']!,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: AppTheme.forestPrimary, size: 22)
                        : null,
                    onTap: () {
                      _api.setCurrency(curr['code']!);
                      Navigator.pop(ctx);
                      setState(() {});
                      AppToast.showSuccess(context, 'Currency updated to ${curr['code']}');
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showServerConfigDialog() {
    final serverCtrl = TextEditingController(text: _api.baseUrl);
    bool isTesting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.sageLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.dns_rounded, color: AppTheme.forestPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Backend Server',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.textDark,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FastAPI server endpoint running on your laptop:',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: serverCtrl,
                  decoration: InputDecoration(
                    labelText: 'Server URL',
                    hintText: 'http://192.168.100.78:8000',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.wifi_tethering_rounded),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Preset: 192.168.100.78:8000', style: TextStyle(fontSize: 11)),
                      backgroundColor: isDark ? AppTheme.cardDarkElevated : AppTheme.sageLight,
                      onPressed: () {
                        serverCtrl.text = 'http://192.168.100.78:8000';
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: isTesting
                      ? null
                      : () async {
                          setDialogState(() => isTesting = true);
                          try {
                            _api.setBaseUrl(serverCtrl.text);
                            final health = await _api.checkHealth();
                            if (!mounted) return;
                            setDialogState(() => isTesting = false);
                            AppToast.showSuccess(
                              context,
                              'Server online! OCR: ${health['ocr_engine'] ?? 'Ready'}',
                            );
                          } catch (e) {
                            if (!mounted) return;
                            setDialogState(() => isTesting = false);
                            AppToast.showError(context, 'Connection failed: ${e.toString()}');
                          }
                        },
                  icon: isTesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.speed_rounded, size: 16),
                  label: Text(isTesting ? 'Pinging...' : 'Test Connection'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
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
                  _api.setBaseUrl(serverCtrl.text);
                  Navigator.pop(ctx);
                  setState(() {});
                  AppToast.showSuccess(context, 'Server endpoint saved.');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.forestPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showExportDataDialog() {
    final exportUrl = _api.getExportCsvUrl();
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.sageLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.file_download_rounded, color: AppTheme.forestPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Export Reports',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.textDark,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Download all categorized receipts, merchant data, and line items:',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDarkElevated : const Color(0xFFF3F5F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                ),
                child: SelectableText(
                  exportUrl,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppTheme.forestPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Compatible with Excel, Google Sheets, QuickBooks, and Xero.',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                AppToast.showSuccess(context, 'Export generated! Preparing download...');
              },
              icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
              label: const Text('Download CSV', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.forestPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of your current session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // close drawer
              AppToast.showInfo(context, 'Logged out of local session.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.badgeRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final drawerBg = isDark ? AppTheme.canvasDark : AppTheme.canvasLight;
    final cardBg = isDark ? AppTheme.cardDark : Colors.white;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final primaryText = isDark ? Colors.white : AppTheme.textDark;

    return Drawer(
      backgroundColor: drawerBg,
      child: SafeArea(
        child: Column(
          children: [
            // User Profile Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.forestPrimary,
                      border: Border.all(
                        color: isDark ? const Color(0xFF3B5646) : Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'AK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Asad Khan',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: primaryText,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'user@receiptledger.com',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ValueListenableBuilder<bool>(
                          valueListenable: _api.backendOnlineNotifier,
                          builder: (ctx, isOnline, _) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? (isDark ? const Color(0xFF142C1F) : AppTheme.greenVerifiedBg)
                                  : (isDark ? const Color(0xFF241F1A) : const Color(0xFFFBF4EB)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                                  size: 12,
                                  color: isOnline ? AppTheme.greenVerified : AppTheme.amberWarning,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOnline ? 'Backend Online' : 'Local Demo',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isOnline ? AppTheme.greenVerified : AppTheme.amberWarning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Quick Stats Strip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Receipts', '24', primaryText),
                    Container(height: 24, width: 1, color: borderColor),
                    ValueListenableBuilder<String>(
                      valueListenable: _api.currencyNotifier,
                      builder: (ctx, curr, _) => _buildStatItem('Spend', '$curr 42,850', primaryText),
                    ),
                    Container(height: 24, width: 1, color: borderColor),
                    ValueListenableBuilder<int>(
                      valueListenable: _api.reviewCountNotifier,
                      builder: (ctx, count, _) => _buildStatItem('Pending', '$count', primaryText, isAlert: count > 0),
                    ),
                  ],
                ),
              ),
            ),

            // Settings Menu List (Full Settings migrated into Sidebar)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 12, top: 8, bottom: 4),
                    child: Text(
                      'PREFERENCES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),

                  // Currency
                  ValueListenableBuilder<String>(
                    valueListenable: _api.currencyNotifier,
                    builder: (ctx, curr, _) => _buildDrawerTile(
                      icon: Icons.payments_rounded,
                      title: 'Currency',
                      subtitle: 'Active: $curr',
                      value: curr,
                      onTap: _showCurrencySelector,
                      isDark: isDark,
                      primaryText: primaryText,
                    ),
                  ),

                  // Export Data
                  _buildDrawerTile(
                    icon: Icons.file_download_outlined,
                    title: 'Export Data',
                    subtitle: 'Download CSV & PDF',
                    value: 'Reports',
                    onTap: _showExportDataDialog,
                    isDark: isDark,
                    primaryText: primaryText,
                  ),

                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.only(left: 12, top: 8, bottom: 4),
                    child: Text(
                      'SYSTEM & CLOUD',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),

                  // Backend Server & OCR Endpoint
                  _buildDrawerTile(
                    icon: Icons.dns_rounded,
                    title: 'Backend Server',
                    subtitle: _api.baseUrl.replaceAll('http://', ''),
                    value: 'Configure',
                    onTap: _showServerConfigDialog,
                    isDark: isDark,
                    primaryText: primaryText,
                  ),

                  // Biometrics Toggle
                  ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.cardDarkElevated : AppTheme.sageLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.fingerprint_rounded,
                        size: 20,
                        color: isDark ? const Color(0xFF86AB93) : AppTheme.forestPrimary,
                      ),
                    ),
                    title: Text(
                      'Biometric Lock',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                      ),
                    ),
                    subtitle: const Text(
                      'FaceID / Fingerprint security',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                    trailing: Switch(
                      value: _biometricsEnabled,
                      activeColor: AppTheme.forestPrimary,
                      onChanged: (val) {
                        setState(() => _biometricsEnabled = val);
                        AppToast.showInfo(
                          context,
                          val ? 'Biometrics enabled for app launch' : 'Biometrics disabled',
                        );
                      },
                    ),
                  ),

                  // App Version
                  _buildDrawerTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About ReceiptLedger',
                    subtitle: 'Enterprise Edition v2.4.1',
                    value: 'Latest',
                    onTap: () {
                      AppToast.showInfo(context, 'ReceiptLedger v2.4.1 is up to date.');
                    },
                    isDark: isDark,
                    primaryText: primaryText,
                  ),
                ],
              ),
            ),

            // Logout Action
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: _showLogoutDialog,
                icon: const Icon(Icons.logout_rounded, size: 18, color: AppTheme.badgeRed),
                label: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: AppTheme.badgeRed,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  minimumSize: const Size(double.infinity, 46),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color textColor, {bool isAlert = false}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: isAlert ? AppTheme.badgeRed : textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required VoidCallback onTap,
    required bool isDark,
    required Color primaryText,
  }) {
    return ListTile(
      dense: true,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDarkElevated : AppTheme.sageLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? const Color(0xFF86AB93) : AppTheme.forestPrimary,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: primaryText,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDarkElevated : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFF94A3B8) : AppTheme.forestPrimary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textMutedLight),
        ],
      ),
    );
  }
}
