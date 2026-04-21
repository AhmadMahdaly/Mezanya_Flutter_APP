import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import '../../../app_state/presentation/cubits/app_cubit.dart';
import '../widgets/app_settings_sections.dart';
// تأكد من وجود ملف backup_settings_screen.dart إذا كنت ستنتقل إليه
// import 'backup_settings_screen.dart';

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
    _backupDir = state.backupDirectoryPath;
    _autoBackupMode = state.autoBackupMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // --- دالة بناء عنوان القسم ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700),
      ),
    );
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          children: [
            _buildSectionHeader('إعدادات الحساب'),
            ProfileSettingsCard(
              nameController: _nameController,
              onNameChanged: (value) =>
                  widget.cubit.updateSettings(userName: value),
              googleLabel: googleLabel,
              onGoogleSignIn: _signInGoogle,
            ),
            const Divider(height: 30),
            _buildSectionHeader('التفضيلات'),
            ListTile(
              leading: const Icon(Icons.monetization_on_outlined,
                  color: Colors.blue),
              title: const Text('العملة الحالية'),
              subtitle: Text(_currency),
              trailing: const Icon(Icons.keyboard_arrow_down),
              onTap: () => _showCurrencyPicker(context),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_none_outlined,
                  color: Colors.orange),
              title: const Text('إعدادات الإشعارات'),
              subtitle: Text(_notificationsEnabled ? 'مفعلة' : 'معطلة'),
              onTap: _openNotificationSettings,
            ),
            const Divider(height: 30),
            _buildSectionHeader('الأمان والبيانات'),
            ListTile(
              leading:
                  const Icon(Icons.cloud_upload_outlined, color: Colors.green),
              title: const Text('النسخ الاحتياطي والاستعادة'),
              subtitle: const Text('إدارة النسخ الاحتياطي محلياً أو سحابياً'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                // يمكنك فتح كارد النسخ هنا أو الانتقال لصفحة جديدة
                _showBackupOptions(context);
              },
            ),
            const Divider(height: 30),
            DangerZoneCard(onTap: () {}),
          ],
        ),
      ),
    );
  }

  // --- دالة ستارة العملة ---
  void _showCurrencyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('اختر العملة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListTile(
                title: const Text('جنيه مصري (EGP)'),
                onTap: () => _updateCurrency('EGP')),
            ListTile(
                title: const Text('دولار أمريكي (USD)'),
                onTap: () => _updateCurrency('USD')),
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

  // --- الدوال الأصلية (المسؤولة عن تشغيل التطبيق) ---
  Future<void> _signInGoogle() async {/* ضع كود الـ SignIn القديم هنا */}
  void _openNotificationSettings() {/* ضع كود الإشعارات القديم هنا */}
  void _showBackupOptions(BuildContext context) {
    // لإظهار كارد النسخ الذي كان لديك سابقاً
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: BackupManagementCard(
          backupDir: _backupDir,
          autoBackupMode: _autoBackupMode,
          onBackupLocal: () {}, // اربط الدوال القديمة هنا
          onPickBackupDirectory: () {},
          onAutoBackupModeChanged: (v) {},
          onRestoreLocal: () {},
          onBackupDrive: () {},
          onRestoreDrive: () {},
        ),
      ),
    );
  }
}
