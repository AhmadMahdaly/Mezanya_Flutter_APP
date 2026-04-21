import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../../../app_state/presentation/cubits/app_cubit.dart';
import '../widgets/app_settings_sections.dart';

class BackupSettingsScreen extends StatefulWidget {
  final AppCubit cubit;
  const BackupSettingsScreen({super.key, required this.cubit});

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen> {
  // انقل هنا كل الدوال الخاصة بالـ Backup من ملفك القديم (_backupLocal, _backupDrive, إلخ)
  // سأضع لك الهيكل الأساسي لتشغيل الصفحة حالياً:
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('النسخ الاحتياطي')),
      body: BackupManagementCard(
        backupDir: widget.cubit.state.backupDirectoryPath,
        autoBackupMode: widget.cubit.state.autoBackupMode,
        onBackupLocal: () => {}, // اربط الدوال هنا
        onPickBackupDirectory: () => {},
        onAutoBackupModeChanged: (v) => {},
        onRestoreLocal: () => {},
        onBackupDrive: () => {},
        onRestoreDrive: () => {},
      ),
    );
  }
}
