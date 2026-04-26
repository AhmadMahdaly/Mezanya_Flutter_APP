import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'package:mezanya_app/features/app_state/presentation/cubits/app_cubit.dart';
import 'backup_settings_screen.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key, required this.cubit});
  final AppCubit cubit;

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  late final TextEditingController _nameController;

  static const bgColor = Color(0xFFFAF7F2);
  static const cardColor = Color(0xFFFFFEFC);
  static const primaryGreen = Color(0xFF2F6F5E);

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', drive.DriveApi.driveFileScope],
  );

  GoogleSignInAccount? _account;

  @override
  void initState() {
    super.initState();
    final state = widget.cubit.state;
    _nameController = TextEditingController(text: state.userName);
    _initGoogle();
  }

  Future<void> _initGoogle() async {
    final acc = await _googleSignIn.signInSilently();
    if (mounted) setState(() => _account = acc);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      // appBar: AppBar(
      //   title: const Text('الإعدادات'),
      //   centerTitle: true,
      //   backgroundColor: bgColor,
      //   elevation: 0,
      //   foregroundColor: Colors.black,
      // ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// 👤 PROFILE
          _sectionTitle('الملف الشخصي'),

          _card(
            child: Column(
              children: [
                /// صورة
                CircleAvatar(
                  radius: 35,
                  backgroundColor: primaryGreen.withOpacity(0.2),
                  child: const Icon(Icons.person, size: 35),
                ),

                const SizedBox(height: 12),

                /// الاسم
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المستخدم',
                  ),
                  onChanged: (v) => widget.cubit.updateSettings(userName: v),
                ),

                const SizedBox(height: 10),

                /// الإيميل
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _account?.email ?? 'لا يوجد حساب مرتبط',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),

                const SizedBox(height: 12),

                /// تغيير الباسورد (UI بس)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تغيير الباسورد لاحقًا'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.lock),
                    label: const Text('تغيير كلمة المرور'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          /// 🔗 GOOGLE ACCOUNT
          _sectionTitle('ربط الحساب'),

          _card(
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.account_circle, color: primaryGreen),
                  title: Text(
                    _account?.email ?? 'غير متصل',
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
                    onPressed:
                        _account == null ? _signInGoogle : _signOutGoogle,
                    icon: Icon(
                      _account == null ? Icons.link : Icons.link_off,
                    ),
                    label: Text(
                      _account == null ? 'ربط حساب Google' : 'إلغاء الربط',
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          /// 🔐 DATA
          _sectionTitle('البيانات'),

          _card(
            child: ListTile(
              leading: const Icon(Icons.backup, color: primaryGreen),
              title: const Text('النسخ الاحتياطي'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BackupSettingsScreen(cubit: widget.cubit),
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
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Future<void> _signInGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return;

      setState(() => _account = account);
    } catch (e) {
      log('Google Sign In Error: $e');
    }
  }

  Future<void> _signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
      setState(() => _account = null);
    } catch (e) {
      log('Google Sign Out Error: $e');
    }
  }
}
