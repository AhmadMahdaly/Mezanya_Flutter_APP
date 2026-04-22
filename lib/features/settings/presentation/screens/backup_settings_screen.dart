import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// عدّل المسار حسب مشروعك
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

  /// 🔐 Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
  }

  /// 📁 Permission
  Future<bool> _permission() async {
    var s = await Permission.manageExternalStorage.request();
    if (s.isGranted) return true;
    s = await Permission.storage.request();
    return s.isGranted;
  }

  /// 💾 Save
  Future<void> _saveOnce() async {
    if (!await _permission()) {
      _snack('لازم تسمح بالوصول للملفات');
      return;
    }

    final dir = await FilePicker.getDirectoryPath();
    if (dir == null) return;

    try {
      final file =
          File('$dir/backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(widget.cubit.exportStateJson());
      _snack('تم حفظ النسخة بنجاح');
    } catch (e) {
      _snack('فشل الحفظ');
    }
  }

  /// 📥 Import
  Future<void> _import() async {
    try {
      final r = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (r != null && r.files.single.path != null) {
        final data = await File(r.files.single.path!).readAsString();
        await widget.cubit.importStateJson(data);
        _snack('تم استرجاع البيانات');
      }
    } catch (e) {
      _snack('فشل الاستيراد');
    }
  }

  /// 🔥 Google Sign-In (FIXED)
  Future<void> _signIn() async {
    try {
      setState(() => _loading = true);

      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _snack('تم إلغاء العملية');
        return;
      }

      final googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('Missing ID Token');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);

      setState(() {
        _user = userCred.user;
      });

      _snack('تم تسجيل الدخول');
    } catch (e) {
      debugPrint('GOOGLE SIGN IN ERROR: $e');

      String msg = 'فشل تسجيل الدخول';

      if (e.toString().contains('10')) {
        msg = 'مشكلة SHA-1';
      } else if (e.toString().contains('12500')) {
        msg = 'إعداد Firebase غير صحيح';
      }

      _snack(msg);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    setState(() => _user = null);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// HEADER
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: const [
                Icon(Icons.backup, color: primaryGreen),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'احفظ بياناتك واسترجعها بسهولة',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// LOCAL
          _sectionTitle('النسخ المحلي'),
          _card(children: [
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
            _btn('حفظ نسخة', Icons.save, _saveOnce),
          ]),

          const SizedBox(height: 16),

          /// IMPORT
          _sectionTitle('استيراد'),
          _card(children: [
            _btn('استيراد ملف', Icons.download, _import),
          ]),

          const SizedBox(height: 16),

          /// GOOGLE
          _sectionTitle('Google'),
          _card(children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.account_circle, color: primaryGreen),
              title: const Text('الحساب'),
              subtitle: Text(_user == null ? 'غير متصل' : _user!.email ?? ''),
            ),
            const SizedBox(height: 10),
            _btn(
              _user == null ? 'ربط الحساب' : 'تسجيل الخروج',
              _user == null ? Icons.link : Icons.logout,
              _user == null ? _signIn : _signOut,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }

  Widget _btn(String text, IconData icon, VoidCallback onTap) {
    return SizedBox(
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
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14));
  }
}
