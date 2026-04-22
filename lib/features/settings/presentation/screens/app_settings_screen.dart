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

  static const bgColor = Color(0xFFFAF7F2);
  static const cardColor = Color(0xFFFFFEFC);
  static const primaryGreen = Color(0xFF2F6F5E);

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      drive.DriveApi.driveFileScope,
    ],
  );

  GoogleSignInAccount? _account;

  @override
  void initState() {
    super.initState();
    final state = widget.cubit.state;
    _nameController = TextEditingController(text: state.userName);
    _currency = state.currencyCode;
    _notificationsEnabled = state.notificationsEnabled;

    _initGoogle();
  }

  Future<void> _initGoogle() async {
    final acc = await _googleSignIn.signInSilently();
    if (mounted) setState(() => _account = acc);
  }

  @override
  Widget build(BuildContext context) {
    final googleLabel = _account == null ? 'غير متصل' : _account!.email;

    return Scaffold(
      backgroundColor: bgColor,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// 👤 PROFILE
          _sectionTitle('الملف الشخصي'),
          _card(
            child: ProfileSettingsCard(
              nameController: _nameController,
              onNameChanged: (value) =>
                  widget.cubit.updateSettings(userName: value),
              googleLabel: googleLabel,
              onGoogleSignIn: () async {
                if (_account == null) {
                  await _signInGoogle();
                }
              },
            ),
          ),

          const SizedBox(height: 12),

          /// 🔐 ACCOUNT (كارت واحد Login + Logout)
          _sectionTitle('الحساب'),

          _card(
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.account_circle, color: primaryGreen),
                  title: Text(
                    _account?.email ?? 'غير متصل',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _account == null
                        ? 'قم بتسجيل الدخول لحفظ بياناتك على السحابة'
                        : 'متصل بحساب Google',
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _account == null
                        ? () async => await _signInGoogle()
                        : () async => await _signOutGoogle(),
                    icon: Icon(
                      _account == null ? Icons.login : Icons.logout,
                    ),
                    label: Text(
                      _account == null ? 'تسجيل الدخول' : 'تسجيل الخروج',
                    ),
                  ),
                ),
              ],
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
              subtitle: const Text('إدارة النسخ محلياً أو على Google Drive'),
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
        ],
      ),
    );
  }

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

  Future<void> _signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
      setState(() => _account = null);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الخروج')),
      );
    } catch (e) {
      log('Google Sign Out Error: $e');
    }
  }
}
