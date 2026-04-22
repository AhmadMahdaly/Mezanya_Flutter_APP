import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../../../app_state/presentation/cubits/app_cubit.dart';

class BackupSettingsScreen extends StatefulWidget {
  final AppCubit cubit;
  const BackupSettingsScreen({super.key, required this.cubit});

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen> {
  /// 🎨 Colors
  static const bgColor = Color(0xFFFAF7F2);
  static const cardColor = Color(0xFFFFFEFC);
  static const primaryGreen = Color(0xFF2F6F5E);
  static const headerColor = Color(0xFFEFE8DD);

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      drive.DriveApi.driveFileScope,
    ],
  );

  GoogleSignInAccount? _account;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    final acc = await _googleSignIn.signInSilently();
    if (mounted) setState(() => _account = acc);
  }

  /// 📁 Permissions
  Future<bool> _permission() async {
    var s = await Permission.manageExternalStorage.request();
    if (s.isGranted) return true;
    s = await Permission.storage.request();
    return s.isGranted;
  }

  /// 💾 Save once (LOCAL)
  Future<void> _saveOnce() async {
    if (!await _permission()) {
      _snack('لازم تسمح بالوصول للملفات');
      return;
    }

    final dir = await FilePicker.getDirectoryPath();
    if (dir == null) return;

    try {
      final file = File(
        '$dir/backup_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(widget.cubit.exportStateJson());
      _snack('تم حفظ النسخة بنجاح ✔');
    } catch (e) {
      _snack('فشل الحفظ: $e');
    }
  }

  /// 📥 Import (LOCAL)
  Future<void> _import() async {
    try {
      final r = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (r != null && r.files.single.path != null) {
        final data = await File(r.files.single.path!).readAsString();
        await widget.cubit.importStateJson(data);
        _snack('تم استرجاع البيانات ✔');
      }
    } catch (e) {
      _snack('فشل الاستيراد: $e');
    }
  }

  /// ☁️ Upload to Drive
  Future<void> _upload() async {
    if (_account == null) {
      _snack('سجل دخول من صفحة الإعدادات الأول');
      return;
    }

    try {
      setState(() => _loading = true);

      final auth = await _account!.authentication;
      final client = GoogleAuthClient(auth.accessToken!);
      final api = drive.DriveApi(client);

      final data = widget.cubit.exportStateJson();

      final media = drive.Media(
        Stream.value(utf8.encode(data)),
        data.length,
      );

      final file = drive.File()..name = "mezanya_backup.json";

      await api.files.create(file, uploadMedia: media);

      _snack('تم رفع النسخة ✔');
    } catch (e) {
      _snack('فشل الرفع: $e');
      log('UPLOAD ERROR: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// ☁️ Download from Drive
  Future<void> _download() async {
    if (_account == null) {
      _snack('سجل دخول من صفحة الإعدادات الأول');
      return;
    }

    try {
      setState(() => _loading = true);

      final auth = await _account!.authentication;
      final client = GoogleAuthClient(auth.accessToken!);
      final api = drive.DriveApi(client);

      final files = await api.files.list(
        q: "name='mezanya_backup.json'",
        $fields: "files(id, name)",
      );

      if (files.files == null || files.files!.isEmpty) {
        _snack('لا يوجد نسخة');
        return;
      }

      final fileId = files.files!.first.id!;

      final media = await api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = await media.stream.toList();
      final data = utf8.decode(bytes.expand((e) => e).toList());

      await widget.cubit.importStateJson(data);

      _snack('تم الاسترجاع ✔');
    } catch (e) {
      _snack('فشل الاسترجاع: $e');
      log('DOWNLOAD ERROR: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.cubit.state;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('النسخ الاحتياطي'),
        centerTitle: true,
        backgroundColor: bgColor,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              /// 🔰 HEADER
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.cloud_sync, color: primaryGreen),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'احفظ بياناتك محلياً أو على Google Drive واسترجعها بسهولة',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// 💾 LOCAL BACKUP
              _sectionTitle('النسخ المحلي'),
              _card(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.folder, color: primaryGreen),
                      title: const Text('مسار الحفظ'),
                      subtitle: Text(
                        state.backupDirectoryPath.isEmpty
                            ? 'غير محدد'
                            : state.backupDirectoryPath,
                      ),
                      onTap: () async {
                        final dir = await FilePicker.getDirectoryPath();
                        if (dir != null) {
                          widget.cubit.updateSettings(backupDirectoryPath: dir);
                        }
                      },
                    ),
                    const Divider(),
                    _btn('حفظ نسخة يدوياً', Icons.save, _saveOnce),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// 📥 IMPORT
              _sectionTitle('استيراد'),
              _card(
                child: _btn('استيراد ملف', Icons.download, _import),
              ),

              const SizedBox(height: 16),

              /// 👤 ACCOUNT (عرض فقط)
              _sectionTitle('الحساب'),
              _card(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.account_circle, color: primaryGreen),
                  title: const Text('Google Account'),
                  subtitle: Text(
                    _account == null ? 'غير متصل' : _account!.email,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// ☁️ GOOGLE DRIVE
              _sectionTitle('Google Drive'),
              _card(
                child: Column(
                  children: [
                    _btn('رفع نسخة على Drive', Icons.cloud_upload, _upload),
                    const SizedBox(height: 10),
                    _btn('استرجاع من Drive', Icons.cloud_download, _download),
                  ],
                ),
              ),
            ],
          ),
          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  Widget _btn(String text, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(text),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

/// 🔐 Google Client
class GoogleAuthClient extends http.BaseClient {
  final String token;
  final http.Client _client = http.Client();

  GoogleAuthClient(this.token);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $token';
    return _client.send(request);
  }
}
