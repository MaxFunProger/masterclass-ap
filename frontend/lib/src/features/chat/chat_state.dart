import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/chat_service.dart';

/// Состояние чата: история для UI персистится; контекст для LLM живёт только в памяти
/// (сбрасывается при закрытии приложения / detached и не сбрасывается при смене вкладки).
class ChatState extends ChangeNotifier {
  ChatState() : _chatService = ChatService();

  final ChatService _chatService;

  static const String _prefsKeyUi = 'chat_ui_messages_v1';

  /// Все сообщения, которые видит пользователь (загружаются с диска при старте).
  final List<Map<String, String>> uiMessages = [];

  /// История только для API sidecar (user/assistant); не сохраняется на диск.
  final List<Map<String, String>> llmMessages = [];

  /// Эхо exclude_ids для "ещё".
  List<int> shownMasterclassIds = [];

  bool loading = false;

  /// Загрузить сохранённую переписку для отображения (без восстановления контекста LLM).
  Future<void> loadPersistedUi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKeyUi);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      uiMessages
        ..clear()
        ..addAll(_parseMessageList(decoded));
      notifyListeners();
    } catch (e, st) {
      debugPrint('ChatState.loadPersistedUi: $e\n$st');
    }
  }

  List<Map<String, String>> _parseMessageList(List<dynamic> list) {
    final out = <Map<String, String>>[];
    for (final e in list) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final row = <String, String>{
        'role': m['role']?.toString() ?? 'user',
        'content': m['content']?.toString() ?? '',
      };
      final p = m['mc_previews'];
      if (p != null && p.toString().isNotEmpty) {
        row['mc_previews'] = p.toString();
      }
      out.add(row);
    }
    return out;
  }

  Future<void> _saveUiMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyUi, jsonEncode(uiMessages));
    } catch (e, st) {
      debugPrint('ChatState._saveUiMessages: $e\n$st');
    }
  }

  /// Сброс контекста LLM при завершении приложения (вкладки не трогаем).
  void clearLlmSession() {
    llmMessages.clear();
    shownMasterclassIds = [];
    notifyListeners();
  }

  /// Выход из аккаунта: очистить и UI, и сессию LLM.
  Future<void> clearAllOnLogout() async {
    uiMessages.clear();
    llmMessages.clear();
    shownMasterclassIds = [];
    loading = false;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKeyUi);
    } catch (e, st) {
      debugPrint('ChatState.clearAllOnLogout: $e\n$st');
    }
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || loading) return;

    loading = true;
    uiMessages.add({'role': 'user', 'content': trimmed});
    notifyListeners();

    try {
      final result = await _chatService.sendMessage(
        message: trimmed,
        messages: llmMessages.isEmpty
            ? null
            : List<Map<String, String>>.from(llmMessages),
        shownMasterclassIds: shownMasterclassIds,
      );
      final assistantMsg = <String, String>{
        'role': 'assistant',
        'content': result.reply,
      };
      if (result.masterclassesPreview.isNotEmpty) {
        assistantMsg['mc_previews'] = jsonEncode(result.masterclassesPreview);
      }
      uiMessages.add(assistantMsg);
      llmMessages.add({'role': 'user', 'content': trimmed});
      llmMessages.add({'role': 'assistant', 'content': result.reply});
      shownMasterclassIds = result.shownMasterclassIds;
      await _saveUiMessages();
    } catch (e) {
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
