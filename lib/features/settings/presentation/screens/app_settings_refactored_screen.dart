import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../../../app_state/presentation/cubits/app_cubit.dart';
import '../widgets/app_settings_sections.dart';
import 'backup_settings_screen.dart'; // سننشئ هذا الملف في الخطوة القادمة

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
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );
  GoogleSignInAccount? _account;
  String _backupDir = '';
  String _autoBackupMode = 'off';

  @override
  void initState() {
    super.initState();
    final state = widget.cubit.state;
    _nameController = TextEditingController(text: state.userName);
    _currency = state.currencyCode;
    _notificationsEnabled = state.notificationsEnabled;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final googleLabel =
        _account == null ? 'تسجيل دخول Google' : 'متصل: ${_account!.email}';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إعدادات التطبيق')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader('إعدادات الحساب'),
            ProfileSettingsCard(
              nameController: _nameController,
              onNameChanged: (value) =>
                  widget.cubit.updateSettings(userName: value),
              googleLabel: googleLabel,
              onGoogleSignIn: _signInGoogle,
            ),
            ProfileSettingsCard(
              nameController: _nameController,
              onNameChanged: (value) =>
                  widget.cubit.updateSettings(userName: value),
              googleLabel: 'إعدادات الحساب المتصل',
              onGoogleSignIn: () {}, // سنعالج هذا في صفحة الحساب لاحقاً
            ),
            const Divider(height: 32),
            _buildHeader('التفضيلات'),
            ListTile(
              leading: const Icon(Icons.monetization_on_outlined,
                  color: Colors.blue),
              title: const Text('العملة الحالية'),
              subtitle: Text(_currency),
              trailing: const Icon(Icons.keyboard_arrow_down),
              onTap: () => _showCurrencyPicker(),
            ),
            const Divider(height: 32),
            _buildHeader('البيانات والأمان'),
            ListTile(
              leading:
                  const Icon(Icons.cloud_upload_outlined, color: Colors.green),
              title: const Text('النسخ الاحتياطي والاستعادة'),
              subtitle: const Text('إدارة بياناتك على Drive أو محلياً'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
          ],
        ),
      ),
    );
  }

  Future<void> _signInGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return;
      }
      setState(() => _account = account);
      await widget.cubit.updateSettings(
        userName: account.displayName ?? widget.cubit.state.userName,
        googleEmail: account.email,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الدخول بحساب Google.')),
      );
    } catch (e) {
      log(e.toString());
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تسجيل الدخول بحساب Google.')),
      );
    }
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
              title: const Text('جنيه مصري (EGP)'),
              onTap: () => _updateCurr('EGP')),
          ListTile(
              title: const Text('دولار أمريكي (USD)'),
              onTap: () => _updateCurr('USD')),
        ],
      ),
    );
  }

  void _updateCurr(String code) {
    setState(() => _currency = code);
    widget.cubit.updateSettings(currencyCode: code);
    Navigator.pop(context);
  }
}
