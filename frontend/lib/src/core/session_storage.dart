import 'package:shared_preferences/shared_preferences.dart';

/// Хранит идентификатор залогиненного пользователя между запусками приложения.
/// Значение всегда нормализуется в строку (JSON может отдать int).
class SessionStorage {
  SessionStorage._();

  static const String _userIdKey = 'user_id';
  static const String _savedPhoneKey = 'saved_login_phone';
  static const String _savedPasswordKey = 'saved_login_password';
  static const String _needsPostRegistrationFeedFiltersKey =
      'needs_post_registration_feed_filters';

  /// После регистрации, до завершения туториала. После "Пропустить"/последнего шага - см. [markPostTutorialFeedFilterPromptReady].
  static const String _awaitingPostTutorialFeedFilterKey =
      'awaiting_post_tutorial_feed_filter';

  /// `null`, если пользователь не входил или вышел.
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_userIdKey);
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  /// Сохранить после успешного /login или /register.
  static Future<void> saveUserId(Object? raw) async {
    if (raw == null) return;
    final s = raw.toString().trim();
    if (s.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, s);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_savedPhoneKey);
    await prefs.remove(_savedPasswordKey);
    await prefs.remove(_needsPostRegistrationFeedFiltersKey);
    await prefs.remove(_awaitingPostTutorialFeedFilterKey);
  }

  /// Сохраняет телефон и пароль на устройстве после успешного входа/регистрации (для экрана "Показать данные").
  static Future<void> saveLoginCredentials(
      String phone, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedPhoneKey, phone.trim());
    await prefs.setString(_savedPasswordKey, password);
  }

  static Future<String?> getSavedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_savedPhoneKey);
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  static Future<String?> getSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedPasswordKey);
  }

  /// После успешной регистрации: пользователь пройдёт туториал, затем на ленте покажется окно фильтров.
  static Future<void> setAwaitingPostTutorialFeedFilterPrompt(
      bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool(_awaitingPostTutorialFeedFilterKey, true);
    } else {
      await prefs.remove(_awaitingPostTutorialFeedFilterKey);
    }
  }

  static Future<bool> awaitingPostTutorialFeedFilterPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_awaitingPostTutorialFeedFilterKey) ?? false;
  }

  /// Вызывать при выходе с туториала на ленту (после регистрации): включает одноразовый показ окна фильтров.
  static Future<void> markPostTutorialFeedFilterPromptReady() async {
    final prefs = await SharedPreferences.getInstance();
    final awaiting = prefs.getBool(_awaitingPostTutorialFeedFilterKey) ?? false;
    if (!awaiting) return;
    await prefs.remove(_awaitingPostTutorialFeedFilterKey);
    await prefs.setBool(_needsPostRegistrationFeedFiltersKey, true);
  }

  /// Сбрасывается после "Применить" в окне фильтров ленты.
  static Future<void> setNeedsPostRegistrationFeedFilters(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool(_needsPostRegistrationFeedFiltersKey, true);
    } else {
      await prefs.remove(_needsPostRegistrationFeedFiltersKey);
    }
  }

  static Future<bool> needsPostRegistrationFeedFilters() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_needsPostRegistrationFeedFiltersKey) ?? false;
  }
}
