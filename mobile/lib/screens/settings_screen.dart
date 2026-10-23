import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const SettingsScreen({super.key, this.onOpenDrawer});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _api = ApiService();
  String _userName = 'Asad Khan';
  String _userEmail = 'user@receiptledger.com';
  bool _isDarkMode = false;
  bool _biometricsEnabled = true;

  Map<String, dynamic>? _healthData;
  String? _healthError;

  @override
  void initState() {
    super.initState();
    _checkHealthSilently();
  }

  Future<void> _checkHealthSilently() async {
    try {
      final data = await _api.checkHealth();
      if (mounted) {
        setState(() {
          _healthData = data;
          _healthError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _healthError = e.toString().replaceAll('Exception: ', '');
          _healthData = null;
        });
      }
    }
  }

  void _showProfileEditDialog() {
    final nameCtrl = TextEditingController(text: _userName);
    final emailCtrl = TextEditingController(text: _userEmail);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email Address'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _userName = nameCtrl.text.trim();
                _userEmail = emailCtrl.text.trim();
              });
              Navigator.pop(ctx);
              _showToast('Profile updated!');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navyBrand),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCurrencySelector() {
    final currencies = ['PKR', 'USD', 'EUR', 'GBP', 'AED', 'SAR'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Select Transaction Currency',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            ...currencies.map((curr) => ListTile(
                  title: Text(curr, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: _api.currency == curr ? const Icon(Icons.check, color: AppTheme.navyBrand) : null,
                  onTap: () {
                    setState(() {
                      _api.setCurrency(curr);
                    });
                    Navigator.pop(ctx);
                    _showToast('Currency set to $curr');
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showExportDataDialog() {
    final exportUrl = _api.getExportCsvUrl();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Ledger Reports', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your complete categorized expense report can be downloaded as a CSV spreadsheet:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                exportUrl,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.navyBrand),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Compatible with Excel, Google Sheets, and accounting software.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
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
              _showToast('CSV Export link copied to clipboard!');
            },
            icon: const Icon(Icons.copy, size: 16, color: Colors.white),
            label: const Text('Copy Link', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navyBrand),
          ),
        ],
      ),
    );
  }

  void _showServerConfigDialog() {
    final urlCtrl = TextEditingController(text: _api.baseUrl);
    bool probing = false;
    String? probeStatus;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Padding(
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
                  const Text(
                    'Backend Server & OCR Engines',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navyBrand),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Connect to your ReceiptLedger backend server:',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 14),

              // Quick Preset Buttons
              const Text('Quick Presets:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _presetChip('Wi-Fi PC (192.168.100.78)', 'http://192.168.100.78:8000', urlCtrl, setDialogState),
                  _presetChip('Android Emulator (10.0.2.2)', 'http://10.0.2.2:8000', urlCtrl, setDialogState),
                  _presetChip('Localhost (127.0.0.1)', 'http://127.0.0.1:8000', urlCtrl, setDialogState),
                ],
              ),
              const SizedBox(height: 14),

              // Custom URL Input
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'API Base URL',
                  hintText: 'http://192.168.100.78:8000',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 12),

              // Probe status banner
              if (probeStatus != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: probeStatus!.contains('Connected') ? AppTheme.greenVerifiedBg : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        probeStatus!.contains('Connected') ? Icons.check_circle : Icons.error_outline,
                        color: probeStatus!.contains('Connected') ? AppTheme.greenVerified : AppTheme.badgeRed,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          probeStatus!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: probeStatus!.contains('Connected') ? AppTheme.greenVerified : AppTheme.badgeRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Test Connection & Save Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: probing
                          ? null
                          : () async {
                              setDialogState(() {
                                probing = true;
                                probeStatus = 'Probing server...';
                              });
                              _api.setBaseUrl(urlCtrl.text.trim());
                              try {
                                final res = await _api.checkHealth();
                                setDialogState(() {
                                  probing = false;
                                  probeStatus = 'Connected! Status: ${res['status']}';
                                });
                                _checkHealthSilently();
                              } catch (e) {
                                setDialogState(() {
                                  probing = false;
                                  probeStatus = 'Unreachable. Check IP & port 8000.';
                                });
                              }
                            },
                      icon: probing
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.network_check, size: 16),
                      label: const Text('Test Connection'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _api.setBaseUrl(urlCtrl.text.trim());
                        Navigator.pop(ctx);
                        _showToast('Base URL saved: ${_api.baseUrl}');
                        _checkHealthSilently();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.navyBrand,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Save URL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetChip(String label, String url, TextEditingController ctrl, StateSetter setDialogState) {
    return GestureDetector(
      onTap: () {
        setDialogState(() {
          ctrl.text = url;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.navyBrand)),
      ),
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.navyBrand,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = _healthData != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          AppHeader(
            subCaption: 'SETTINGS',
            onAvatarTap: widget.onOpenDrawer,
          ),

          // Main View matching SETTINGS.png
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Profile Card from SETTINGS.png
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      children: [
                        // Circle Avatar with initials "AK" (dark green)
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: AppTheme.avatarGreen,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'AK',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Name & Email
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _userEmail,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Pencil Edit Button
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.navyBrand),
                          onPressed: _showProfileEditDialog,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // PREFERENCES Header
                  const Text(
                    'PREFERENCES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // PREFERENCES Card
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Column(
                      children: [
                        // Currency Item
                        _buildSettingRow(
                          icon: Icons.account_balance_wallet_outlined,
                          iconBg: const Color(0xFFD1FAE5),
                          iconColor: const Color(0xFF059669),
                          title: 'Currency',
                          subtitle: 'Default transaction currency',
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_api.currency} >',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ),
                          onTap: _showCurrencySelector,
                        ),
                        const Divider(height: 1, indent: 64),

                        // Appearance Item
                        _buildSettingRow(
                          icon: Icons.palette_outlined,
                          iconBg: const Color(0xFFE2E8F0),
                          iconColor: AppTheme.navyBrand,
                          title: 'Appearance',
                          subtitle: 'Theme mode',
                          trailing: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: !_isDarkMode ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Light',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: !_isDarkMode ? AppTheme.navyBrand : AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _isDarkMode ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Dark',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _isDarkMode ? AppTheme.navyBrand : AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () {
                            setState(() => _isDarkMode = !_isDarkMode);
                            _showToast(_isDarkMode ? 'Switched to Dark theme' : 'Switched to Light theme');
                          },
                        ),
                        const Divider(height: 1, indent: 64),

                        // Export Data Item
                        _buildSettingRow(
                          icon: Icons.download_outlined,
                          iconBg: const Color(0xFFEDE9FE),
                          iconColor: const Color(0xFF6D28D9),
                          title: 'Export Data',
                          subtitle: 'Download CSV or PDF reports',
                          trailing: const Icon(Icons.chevron_right, color: AppTheme.textMutedLight, size: 20),
                          onTap: _showExportDataDialog,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // SYSTEM Header
                  const Text(
                    'SYSTEM',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // SYSTEM Card
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Column(
                      children: [
                        // Security & Biometrics
                        _buildSettingRow(
                          icon: Icons.shield_outlined,
                          iconBg: const Color(0xFFF1F5F9),
                          iconColor: AppTheme.navyBrand,
                          title: 'Security & Biometrics',
                          subtitle: 'FaceID / Fingerprint lock',
                          trailing: Switch(
                            value: _biometricsEnabled,
                            onChanged: (val) => setState(() => _biometricsEnabled = val),
                            activeThumbColor: AppTheme.navyBrand,
                          ),
                        ),
                        const Divider(height: 1, indent: 64),

                        // Backend Server & Engine
                        _buildSettingRow(
                          icon: Icons.dns_outlined,
                          iconBg: const Color(0xFFE0E7FF),
                          iconColor: AppTheme.headerBlueDark,
                          title: 'Backend Server',
                          subtitle: isOnline
                              ? _api.baseUrl.replaceAll('http://', '')
                              : (_healthError ?? 'Tap to configure server IP'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isOnline ? AppTheme.greenVerifiedBg : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: isOnline ? AppTheme.greenVerified : AppTheme.badgeRed,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOnline ? 'Online' : 'Offline',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isOnline ? AppTheme.greenVerified : AppTheme.badgeRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: _showServerConfigDialog,
                        ),
                        const Divider(height: 1, indent: 64),

                        // App Version
                        _buildSettingRow(
                          icon: Icons.info_outline,
                          iconBg: const Color(0xFFF1F5F9),
                          iconColor: AppTheme.navyBrand,
                          title: 'App Version',
                          subtitle: 'ReceiptLedger Enterprise v2.4.1',
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Latest',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.navyBrand,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Outlined Red Log Out Button from SETTINGS.png
                  OutlinedButton.icon(
                    onPressed: () {
                      _showToast('Logged out of active session.');
                    },
                    icon: const Icon(Icons.logout, size: 18, color: AppTheme.badgeRed),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.badgeRed,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
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

  Widget _buildSettingRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
