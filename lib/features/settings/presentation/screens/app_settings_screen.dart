import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../../../app_state/presentation/cubits/app_cubit.dart';

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
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: [drive.DriveApi.driveAppdataScope]);
  GoogleSignInAccount? _account;

  @override
  void initState() {
    super.initState();
    final s = widget.cubit.state;
    _nameController = TextEditingController(text: s.userName);
    _currency = s.currencyCode;
    _notificationsEnabled = s.notificationsEnabled;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.cubit.state;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('إعدادات التطبيق', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('اسم المستخدم', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  onChanged: (value) => widget.cubit.updateSettings(userName: value),
                  decoration: const InputDecoration(hintText: 'اكتب اسمك'),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _signInGoogle,
                  icon: const Icon(Icons.login),
                  label: Text(_account == null ? 'تسجيل دخول Google' : 'متصل: ${_account!.email}'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('العملة', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _currency,
                  items: const [
                    DropdownMenuItem(value: 'EGP', child: Text('جنيه مصري (EGP)')),
                    DropdownMenuItem(value: 'SAR', child: Text('ريال سعودي (SAR)')),
                    DropdownMenuItem(value: 'USD', child: Text('دولار أمريكي (USD)')),
                    DropdownMenuItem(value: 'EUR', child: Text('يورو (EUR)')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _currency = value);
                    widget.cubit.updateSettings(currencyCode: value);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            title: const Text('الإشعارات'),
            subtitle: Text(_notificationsEnabled ? 'مفعلة' : 'موقوفة'),
            trailing: const Icon(Icons.chevron_left),
            onTap: _openNotificationSettings,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('إدارة النسخ الاحتياطي', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _backupLocal,
                  icon: const Icon(Icons.download),
                  label: const Text('تحميل نسخة احتياطية محليًا'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _restoreLocal,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('استرجاع من ملف محلي'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _backupDrive,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('رفع النسخة إلى Google Drive'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _restoreDrive,
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: const Text('استرجاع من Google Drive'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('حذف كل البيانات', style: TextStyle(color: Colors.red)),
            subtitle: const Text('يتطلب تأكيد قبل الحذف'),
            onTap: _confirmDeleteAll,
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: ListTile(
            title: const Text('الميزانية'),
            subtitle: Text('المستخدم: ${state.userName.isEmpty ? 'غير محدد' : state.userName}'),
            trailing: const Text('v1.0.0'),
          ),
        ),
      ],
    );
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الدخول بحساب Google.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تسجيل الدخول بحساب Google.')));
    }
  }

  void _openNotificationSettings() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('إعدادات الإشعارات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('تفعيل إشعارات التطبيق'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setSheet(() => _notificationsEnabled = value);
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
    final bytes = Uint8List.fromList(utf8.encode(data));
    await FileSaver.instance.saveFile(
      name: 'korassa-backup-${DateTime.now().millisecondsSinceEpoch}',
      bytes: bytes,
      fileExtension: 'json',
      mimeType: MimeType.json,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ النسخة محليًا.')));
  }

  Future<void> _restoreLocal() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    final file = picked?.files.single;
    if (file == null || file.bytes == null) return;
    final json = utf8.decode(file.bytes!);
    await widget.cubit.importStateJson(json);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الاسترجاع من النسخة المحلية.')));
  }

  Future<void> _backupDrive() async {
    final account = _account ?? await _googleSignIn.signIn();
    if (account == null) return;
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفع النسخة إلى Google Drive.')));
  }

  Future<void> _restoreDrive() async {
    final account = _account ?? await _googleSignIn.signIn();
    if (account == null) return;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد ملف نسخة على Drive.')));
      return;
    }
    final media = await api.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
    final chunks = <int>[];
    await for (final c in media.stream) {
      chunks.addAll(c);
    }
    await widget.cubit.importStateJson(utf8.decode(chunks));
    client.close();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الاسترجاع من Google Drive.')));
  }

  Future<void> _confirmDeleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف كل البيانات؟ لا يمكن التراجع.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.cubit.resetAllData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف كل البيانات.')));
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
