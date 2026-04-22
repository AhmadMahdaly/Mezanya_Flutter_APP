import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'package:mezanya_app/features/app_state/presentation/cubits/app_cubit.dart';
import 'package:mezanya_app/features/settings/presentation/widgets/app_settings_sections.dart';
import 'backup_settings_screen.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key, required this.cubit});
  final AppCubit cubit;

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  late final TextEditingController _nameController;
  late String _currency;
  late bool _notificationsEnabled;

  /// 🎨 COLORS
  static const bgColor = Color(0xFFFAF7F2);
  static const cardColor = Color(0xFFFFFEFC);
  static const primaryGreen = Color(0xFF2F6F5E);

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  GoogleSignInAccount? _account;

  @override
  void initState() {
    super.initState();
    final state = widget.cubit.state;
    _nameController = TextEditingController(text: state.userName);
    _currency = state.currencyCode;
    _notificationsEnabled = state.notificationsEnabled;

    _googleSignIn.signInSilently().then((account) {
      if (mounted) setState(() => _account = account);
    });
  }

  @override
  Widget build(BuildContext context) {
    final googleLabel =
        _account == null ? 'ربط حساب Google Drive' : _account!.email;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: true,
        backgroundColor: bgColor,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// 🔰 HEADER
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEFE8DD),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: const [
                Icon(Icons.settings, color: primaryGreen, size: 26),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'إدارة إعدادات التطبيق والحساب',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// 👤 PROFILE
          _sectionTitle('الملف الشخصي'),

          _card(
            child: ProfileSettingsCard(
              nameController: _nameController,
              onNameChanged: (value) =>
                  widget.cubit.updateSettings(userName: value),
              googleLabel: googleLabel,
              onGoogleSignIn: _signInGoogle,
            ),
          ),

          const SizedBox(height: 18),

          /// ⚙️ APP SETTINGS
          _sectionTitle('تفضيلات التطبيق'),

          _card(
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.monetization_on, color: primaryGreen),
                  title: const Text('العملة الأساسية'),
                  subtitle: Text(_currency),
                  trailing: const Icon(Icons.arrow_back_ios_new, size: 14),
                  onTap: () => _showCurrencyPicker(context),
                ),
                const Divider(),
                SwitchListTile(
                  secondary:
                      const Icon(Icons.notifications, color: primaryGreen),
                  title: const Text('الإشعارات'),
                  subtitle: Text(_notificationsEnabled ? 'مفعلة' : 'متوقفة'),
                  value: _notificationsEnabled,
                  onChanged: (val) {
                    setState(() => _notificationsEnabled = val);
                    widget.cubit.updateSettings(notificationsEnabled: val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          /// 🔐 DATA
          _sectionTitle('البيانات والأمان'),

          _card(
            child: ListTile(
              leading: const Icon(Icons.backup, color: primaryGreen, size: 26),
              title: const Text('النسخ الاحتياطي والاستعادة'),
              subtitle: const Text('إدارة النسخ محلياً أو سحابياً'),
              trailing: const Icon(Icons.arrow_back_ios_new, size: 14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        BackupSettingsScreen(cubit: widget.cubit),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 30),

          /// ⚠️ DANGER
          DangerZoneCard(onTap: () {}),
        ],
      ),
    );
  }

  /// 🧱 CARD STYLE
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('اختر العملة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ListTile(
              title: const Text('جنيه مصري (EGP)'),
              onTap: () => _updateCurrency('EGP'),
            ),
            ListTile(
              title: const Text('دولار أمريكي (USD)'),
              onTap: () => _updateCurrency('USD'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateCurrency(String code) {
    setState(() => _currency = code);
    widget.cubit.updateSettings(currencyCode: code);
    Navigator.pop(context);
  }

  Future<void> _signInGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return;

      setState(() => _account = account);

      await widget.cubit.updateSettings(
        userName: account.displayName ?? widget.cubit.state.userName,
        googleEmail: account.email,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تسجيل الدخول: ${account.email}')),
      );
    } catch (e) {
      log('Google Sign In Error: $e');
    }
  }
}
