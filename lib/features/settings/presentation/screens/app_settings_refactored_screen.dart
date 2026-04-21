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
    _runAutoBackupIfNeeded(trigger: 'open');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.cubit.state;
    final googleLabel = _account == null
        ? 'تسجيل دخول Google'
        : 'متصل: ${_account!.email}';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'إعدادات التطبيق',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ProfileSettingsCard(
            nameController: _nameController,
            onNameChanged: (value) => widget.cubit.updateSettings(userName: value),
            googleLabel: googleLabel,
            onGoogleSignIn: _signInGoogle,
          ),
          const SizedBox(height: 12),
          CurrencySettingsCard(
            currency: _currency,
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() => _currency = value);
              widget.cubit.updateSettings(currencyCode: value);
            },
          ),
          const SizedBox(height: 12),
          NotificationsSettingsTile(
            enabled: _notificationsEnabled,
            onTap: _openNotificationSettings,
          ),
          const SizedBox(height: 12),
          BackupManagementCard(
            backupDir: _backupDir,
            autoBackupMode: _autoBackupMode,
            onBackupLocal: _backupLocal,
            onPickBackupDirectory: _pickBackupDirectory,
            onAutoBackupModeChanged: (value) async {
              if (value == null) {
                return;
              }
              setState(() => _autoBackupMode = value);
              await widget.cubit.updateSettings(autoBackupMode: value);
            },
            onRestoreLocal: _restoreLocal,
            onBackupDrive: _backupDrive,
            onRestoreDrive: _restoreDrive,
          ),
          const SizedBox(height: 12),
          DangerZoneCard(onTap: _confirmDeleteAll),
          const SizedBox(height: 14),
          AppInfoCard(userName: state.userName),
        ],
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
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تسجيل الدخول بحساب Google.')),
      );
    }
  }

  void _openNotificationSettings() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'إعدادات الإشعارات',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('تفعيل إشعارات التطبيق'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setSheetState(() => _notificationsEnabled = value);
                  widget.cubit.updateSettings(notificationsEnabled: value);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _backupLocal() async {
    final data = widget.cubit.exportStateJson();
    final filePath =
        '${Directory.systemTemp.path}${Platform.pathSeparator}korassa-backup-${DateTime.now().millisecondsSinceEpoch}.json';
    try {
      final file = File(filePath);
      await file.writeAsString(data);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, mimeType: 'application/json')],
          text: 'نسخة احتياطية من تطبيق Korassa',
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر تجهيز أو مشاركة ملف النسخة الاحتياطية.'),
        ),
      );
      return;
    }
    await widget.cubit.updateAutoBackupTimestamp(DateTime.now());
    if (!mounted) {
      return;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم حفظ النسخة في: $filePath')),
    );
  }

  Future<void> _restoreLocal() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: false,
    );
    final file = picked?.files.single;
    if (file == null || file.path == null || file.path!.isEmpty) {
      return;
    }
    try {
      final json = await File(file.path!).readAsString();
      await widget.cubit.importStateJson(json);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر قراءة ملف النسخة الاحتياطية المحدد.')),
      );
      return;
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم الاسترجاع من النسخة المحلية.')),
    );
  }

  Future<void> _backupDrive() async {
    final account = _account ?? await _googleSignIn.signIn();
    if (account == null) {
      return;
    }
    final authHeaders = await account.authHeaders;
    final client = _GoogleAuthClient(authHeaders);
    final api = drive.DriveApi(client);
    final data = utf8.encode(widget.cubit.exportStateJson());

    final file = drive.File()
      ..name = 'korassa-backup.json'
      ..parents = ['appDataFolder'];
    await api.files.create(
      file,
      uploadMedia: drive.Media(Stream.value(data), data.length),
    );
    client.close();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم رفع النسخة إلى Google Drive.')),
    );
  }

  Future<void> _restoreDrive() async {
    final account = _account ?? await _googleSignIn.signIn();
    if (account == null) {
      return;
    }
    final authHeaders = await account.authHeaders;
    final client = _GoogleAuthClient(authHeaders);
    final api = drive.DriveApi(client);
    final list = await api.files.list(
      spaces: 'appDataFolder',
      q: "name='korassa-backup.json'",
      orderBy: 'modifiedTime desc',
      pageSize: 1,
    );
    final fileId = list.files?.isNotEmpty == true ? list.files!.first.id : null;
    if (fileId == null) {
      client.close();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد ملف نسخة على Drive.')),
      );
      return;
    }
    final media = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final chunks = <int>[];
    await for (final chunk in media.stream) {
      chunks.addAll(chunk);
    }
    await widget.cubit.importStateJson(utf8.decode(chunks));
    client.close();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم الاسترجاع من Google Drive.')),
    );
  }

  Future<void> _confirmDeleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف كل البيانات؟ لا يمكن التراجع.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) {
      return;
    }
    await widget.cubit.resetAllData();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف كل البيانات.')),
    );
  }

  Future<void> _pickBackupDirectory() async {
    final dir = await FilePicker.platform.getDirectoryPath();
    if (dir == null || dir.isEmpty) {
      return;
    }
    setState(() => _backupDir = dir);
    await widget.cubit.updateSettings(backupDirectoryPath: dir);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تحديد مسار النسخ: $dir')),
    );
  }

  Future<void> _runAutoBackupIfNeeded({required String trigger}) async {
    final state = widget.cubit.state;
    final mode = state.autoBackupMode;
    if (mode == 'off') {
      return;
    }
    if (mode == 'on-close' && trigger != 'close' && trigger != 'open') {
      return;
    }
    if (state.backupDirectoryPath.isEmpty) {
      return;
    }

    final last = state.lastAutoBackupAt.isEmpty
        ? null
        : DateTime.tryParse(state.lastAutoBackupAt);
    final now = DateTime.now();
    if (mode == 'daily' && last != null && now.difference(last).inHours < 24) {
      return;
    }
    if (mode == 'weekly' && last != null && now.difference(last).inDays < 7) {
      return;
    }
    if (mode == 'on-close' && trigger == 'open') {
      return;
    }

    final filePath =
        '${state.backupDirectoryPath}${Platform.pathSeparator}korassa-auto-${now.millisecondsSinceEpoch}.json';
    try {
      await File(filePath).writeAsString(widget.cubit.exportStateJson());
    } catch (_) {
      if (trigger != 'close' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل النسخ التلقائي: مسار النسخ غير قابل للكتابة.'),
          ),
        );
      }
      return;
    }
    await widget.cubit.updateAutoBackupTimestamp(now);
  }

  @override
  void deactivate() {
    _runAutoBackupIfNeeded(trigger: 'close');
    super.deactivate();
  }
}

class _GoogleAuthClient extends http.BaseClient {
  _GoogleAuthClient(this._headers);

  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
    super.close();
  }
}
