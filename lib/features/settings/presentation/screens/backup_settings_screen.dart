import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../app_state/presentation/cubits/app_cubit.dart';

class BackupSettingsScreen extends StatefulWidget {
  final AppCubit cubit;
  const BackupSettingsScreen({super.key, required this.cubit});

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen> {
  static const bgColor = Color(0xFFFAF7F2);
  static const cardColor = Color(0xFFFFFEFC);
  static const primaryGreen = Color(0xFF2F6F5E);

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', drive.DriveApi.driveFileScope],
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

  /// 🔑 user id
  String get userId => _account?.email ?? 'guest';

  /// ================= LOCAL =================
  Future<void> _saveOnce() async {
    final dir = await FilePicker.getDirectoryPath();
    if (dir == null) return;

    final file = File(
      '$dir/backup_${DateTime.now().millisecondsSinceEpoch}.json',
    );

    await file.writeAsString(widget.cubit.exportStateJson());

    _snack('تم الحفظ محليًا ✔');
  }

  Future<void> _import() async {
    final r = await FilePicker.pickFiles(type: FileType.any);
    if (r == null || r.files.single.path == null) return;

    final data = await File(r.files.single.path!).readAsString();
    await widget.cubit.importStateJson(data);

    _snack('تم الاسترجاع محليًا ✔');
  }

  /// ================= FIRESTORE =================
  Future<void> _uploadFirestore() async {
    try {
      setState(() => _loading = true);

      final data = widget.cubit.exportStateJson();

      await FirebaseFirestore.instance.collection('backups').doc(userId).set({
        'data': data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _snack('تم رفع النسخة على Firebase ✔');
    } catch (e) {
      _snack('فشل Firebase: $e');
      log('$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _downloadFirestore() async {
    try {
      setState(() => _loading = true);

      final doc = await FirebaseFirestore.instance
          .collection('backups')
          .doc(userId)
          .get();

      if (!doc.exists) {
        _snack('لا يوجد نسخة على Firebase');
        return;
      }

      final data = doc.data()?['data'];

      if (data != null) {
        await widget.cubit.importStateJson(data);
        _snack('تم الاسترجاع من Firebase ✔');
      }
    } catch (e) {
      _snack('فشل Firebase: $e');
      log('$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// ================= DRIVE =================
  Future<void> _uploadDrive() async {
    if (_account == null) {
      _snack('سجل دخول الأول');
      return;
    }

    final auth = await _account!.authentication;
    final client = GoogleAuthClient(auth.accessToken!);
    final api = drive.DriveApi(client);

    final data = widget.cubit.exportStateJson();
    final bytes = utf8.encode(data);

    final media = drive.Media(
      Stream.value(bytes),
      bytes.length,
    );

    await api.files.create(
      drive.File()..name = "mezanya_backup.json",
      uploadMedia: media,
    );

    _snack('تم رفع على Drive ✔');
  }

  Future<void> _downloadDrive() async {
    if (_account == null) return;

    final auth = await _account!.authentication;
    final client = GoogleAuthClient(auth.accessToken!);
    final api = drive.DriveApi(client);

    final files = await api.files.list(
      q: "name='mezanya_backup.json'",
    );

    if (files.files == null || files.files!.isEmpty) {
      _snack('لا يوجد نسخة');
      return;
    }

    final media = await api.files.get(
      files.files!.first.id!,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final bytes = await media.stream.toList();
    final data = utf8.decode(bytes.expand((e) => e).toList());

    await widget.cubit.importStateJson(data);

    _snack('تم الاسترجاع من Drive ✔');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              /// LOCAL
              _card(
                child: Column(
                  children: [
                    _btn('حفظ محلي', Icons.save, _saveOnce),
                    _btn('استرجاع محلي', Icons.upload, _import),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// FIREBASE
              _card(
                child: Column(
                  children: [
                    const Text('Firebase'),
                    _btn('رفع على Firebase', Icons.cloud_upload,
                        _uploadFirestore),
                    _btn('استرجاع من Firebase', Icons.cloud_download,
                        _downloadFirestore),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// DRIVE
              _card(
                child: Column(
                  children: [
                    const Text('Google Drive'),
                    _btn('رفع على Drive', Icons.cloud_upload, _uploadDrive),
                    _btn('استرجاع من Drive', Icons.cloud_download,
                        _downloadDrive),
                  ],
                ),
              ),
            ],
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
          ),
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(text),
        ),
      ),
    );
  }
}

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
