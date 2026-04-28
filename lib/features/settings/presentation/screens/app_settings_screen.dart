import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:mezanya_app/features/app_state/presentation/cubits/app_cubit.dart';
import 'backup_settings_screen.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({
    super.key,
    required this.cubit,
  });

  final AppCubit cubit;

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  late TextEditingController _nameController;

  static const bg = Color(0xFFF7F7F4);

  static const card = Colors.white;

  static const primary = Color(0xFF2F6F5E);

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  GoogleSignInAccount? _account;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.cubit.state.userName,
    );

    _initGoogle();
  }

  Future<void> _initGoogle() async {
    final acc =
        _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();

    if (!mounted) return; // مهم قبل لمس controller

    if (acc != null && _nameController.text.trim().isEmpty) {
      _nameController.text = acc.displayName ?? '';
    }

    setState(() {
      _account = acc;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: bg,
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const SizedBox(
            height: 10,
          ),

          // PROFILE
          _sectionLabel(
            'الملف الشخصي',
          ),

          _card(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: primary.withOpacity(.12),
                      backgroundImage: _account?.photoUrl != null
                          ? NetworkImage(
                              _account!.photoUrl!,
                            )
                          : null,
                      child: _account?.photoUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 44,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 18,
                ),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم المستخدم',
                    prefixIcon: const Icon(
                      Icons.person_outline,
                    ),
                    filled: true,
                    fillColor: const Color(
                      0xFFF4F6F4,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        16,
                      ),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) {
                    widget.cubit.updateSettings(
                      userName: v,
                    );
                  },
                ),
                const SizedBox(
                  height: 14,
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFF4F6F4,
                    ),
                    borderRadius: BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        size: 20,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Text(
                          _account?.email ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 22,
          ),

          // GOOGLE
          _sectionLabel(
            'ربط الحساب',
          ),

          _card(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFF8FAF8,
                    ),
                    borderRadius: BorderRadius.circular(
                      18,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            14,
                          ),
                          color: Colors.white,
                        ),
                        child: const Center(
                          child: Text(
                            'G',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'حساب Google',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _account?.email ?? 'غير متصل',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        _account == null ? _signInGoogle : _signOutGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(
                        54,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          18,
                        ),
                      ),
                    ),
                    icon: Icon(
                      _account == null ? Icons.login : Icons.logout,
                    ),
                    label: Text(
                      _account == null
                          ? 'تسجيل الدخول بجوجل'
                          : 'تسجيل الخروج من جوجل',
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 22,
          ),

          // DATA
          _sectionLabel(
            'البيانات',
          ),

          _card(
            child: InkWell(
              borderRadius: BorderRadius.circular(
                18,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BackupSettingsScreen(
                      cubit: widget.cubit,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(
                          .12,
                        ),
                        borderRadius: BorderRadius.circular(
                          16,
                        ),
                      ),
                      child: const Icon(
                        Icons.backup_rounded,
                        color: primary,
                      ),
                    ),
                    const SizedBox(
                      width: 14,
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إدارة النسخ الاحتياطي',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(
                            height: 4,
                          ),
                          Text(
                            'نسخ محلي و Firebase',
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_left,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 30,
          ),
        ],
      ),
    );
  }

  Widget _card({
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(
          26,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            offset: Offset(0, 5),
            color: Color(0x11000000),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionLabel(
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 18,
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

      _nameController.text = account.displayName ?? '';

      widget.cubit.updateSettings(
        userName: _nameController.text,
        googleEmail: account.email,
      );

      setState(() {
        _account = account;
      });
    } catch (e) {
      log(
        'Google sign in error $e',
      );
    }
  }

  Future<void> _signOutGoogle() async {
    try {
      await _googleSignIn.signOut();

      widget.cubit.updateSettings(
        googleEmail: '',
      );

      setState(() {
        _account = null;
      });
    } catch (e) {
      log(
        'Google sign out error $e',
      );
    }
  }
}
