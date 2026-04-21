import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../app_state/presentation/cubits/app_cubit.dart';

class BackupSettingsScreen extends StatefulWidget {
  final AppCubit cubit;
  const BackupSettingsScreen({super.key, required this.cubit});

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _performSilentBackup();
    }
  }

  Future<void> _performSilentBackup() async {
    final path = widget.cubit.state.backupDirectoryPath;
    if (path.isNotEmpty) {
      try {
        final data = widget.cubit.exportStateJson();
        final file = File('$path/mezanya_live_backup.json');
        await file.writeAsString(data);
      } catch (e) {
        debugPrint('Auto backup error: $e');
      }
    }
  }

  Future<void> _saveManualToFolder() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        final data = widget.cubit.exportStateJson();
        final fileName =
            'backup_${DateTime.now().day}_${DateTime.now().month}.json';
        final file = File('$selectedDirectory/$fileName');
        await file.writeAsString(data);
        if (mounted) _showSnackBar('✅ تم حفظ النسخة اليدوية بنجاح');
      }
    } catch (e) {
      _showSnackBar('❌ فشل الحفظ: تحقق من صلاحيات المجلد');
    }
  }

  Future<void> _importBackupData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        await widget.cubit.importStateJson(jsonString);
        if (mounted) _showSnackBar('✅ تم استرجاع كافة البيانات');
      }
    } catch (e) {
      _showSnackBar('❌ فشل استيراد الملف');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.indigo.shade900,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.cubit.state;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: AppBar(
          title: const Text('الحفظ التلقائي والاستعادة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.indigo.shade900,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _buildExplainerHeader(state.backupDirectoryPath.isNotEmpty),
            const SizedBox(height: 25),
            _buildSectionTitle('إدارة التخزين المحلي'),
            _buildModernLocalCard(state.backupDirectoryPath),
            const SizedBox(height: 25),
            _buildSectionTitle('المزامنة السحابية المتطورة'),
            _buildLargeCloudCard(state.autoBackupMode),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- كارت الشرح العلوي ---
  Widget _buildExplainerHeader(bool isActive) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.indigo.withOpacity(0.06), blurRadius: 20)
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                Text('01',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                Text('10',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('نظام الحفظ التلقائي',
                    style: TextStyle(
                        color: Color(0xFF1A237E),
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(
                  'يقوم التطبيق تلقائياً بتحديث نسخة احتياطية من بياناتك فور إغلاق التطبيق لضمان الحماية القصوى.',
                  style:
                      TextStyle(color: Colors.grey, fontSize: 11, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- كارت التحكم المحلي ---
  Widget _buildModernLocalCard(String path) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)
        ],
      ),
      child: Column(
        children: [
          _buildActionRow(
            icon: Icons.folder_zip_rounded,
            color: Colors.blue.shade600,
            title: 'تحديد مسار الحفظ',
            subtitle: path.isEmpty ? 'انقر لربط مجلد بالجهاز' : path,
            onTap: () async {
              String? dir = await FilePicker.platform.getDirectoryPath();
              if (dir != null)
                widget.cubit.updateSettings(backupDirectoryPath: dir);
            },
          ),
          const Divider(height: 1, indent: 70),
          _buildActionRow(
            icon: Icons.upload_file_rounded,
            color: Colors.teal,
            title: 'تصدير نسخة فورية',
            subtitle: 'حفظ ملف بيانات JSON يدوياً الآن',
            onTap: _saveManualToFolder,
          ),
          const Divider(height: 1, indent: 70),
          _buildActionRow(
            icon: Icons.downloading_rounded,
            color: Colors.orange.shade700,
            title: 'استيراد البيانات',
            subtitle: 'استرجاع السجلات من ملف سابق',
            onTap: _importBackupData,
          ),
        ],
      ),
    );
  }

  // --- كارت جوجل درايف (المحسن) ---
  Widget _buildLargeCloudCard(String mode) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade800, Colors.indigo.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 20)
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.cloud_sync, color: Colors.white)),
            title: const Text('جدولة Google Drive',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            trailing: Theme(
              data: Theme.of(context)
                  .copyWith(canvasColor: Colors.indigo.shade700),
              child: DropdownButton<String>(
                underline: const SizedBox(),
                dropdownColor: Colors.indigo.shade800,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                value: ['off', 'daily', 'weekly'].contains(mode) ? mode : 'off',
                items: const [
                  DropdownMenuItem(value: 'off', child: Text('إيقاف')),
                  DropdownMenuItem(value: 'daily', child: Text('يومي')),
                  DropdownMenuItem(value: 'weekly', child: Text('أسبوعي')),
                ],
                onChanged: (v) =>
                    widget.cubit.updateSettings(autoBackupMode: v),
              ),
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLargeCloudBtn(Icons.add_link_rounded, 'ربط الحساب'),
                _buildLargeCloudBtn(
                    Icons.cloud_download_rounded, 'استرجاع الداتا'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- دوال بناء الـ Widgets المساعدة (خارج دالة build) ---
  Widget _buildLargeCloudBtn(IconData icon, String label) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
            color: Colors.white12, borderRadius: BorderRadius.circular(15)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15)),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      trailing:
          const Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.black12),
      onTap: onTap,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 10),
      child: Text(title,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.indigo.shade900)),
    );
  }
}
