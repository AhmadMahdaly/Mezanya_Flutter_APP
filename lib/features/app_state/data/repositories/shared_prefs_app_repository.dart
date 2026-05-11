import 'dart:convert';
import 'package:mezanya/core/storage/shared_prefs_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mezanya/features/app_state/domain/entities/app_state_entity.dart';
import 'package:mezanya/features/app_state/domain/repositories/app_repository.dart';

class SharedPrefsAppRepository implements AppRepository {
  final SharedPreferences _prefs;

  SharedPrefsAppRepository(this._prefs);

  @override
  Future<AppStateEntity> loadState() async {
    final payload = _prefs.getString(SharedPrefsKeys.appState);
    if (payload == null || payload.isEmpty) {
      final initial = AppStateEntity.initial();
      await saveState(initial);
      return initial;
    }
    try {
      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      return AppStateEntity.fromMap(decoded);
    } catch (_) {
      final fallback = AppStateEntity.initial();
      await saveState(fallback);
      return fallback;
    }
  }

  @override
  Future<void> saveState(AppStateEntity state) async {
    await _prefs.setString(
      SharedPrefsKeys.appState,
      jsonEncode(state.toMap()),
    );
  }
}