import 'package:dio/dio.dart';
import '../../../core/api_client.dart';

class ChatService {
  late final Dio _dio;

  ChatService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiClient.chatBaseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: <String, dynamic>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));
  }

  Future<ChatReply> sendMessage({
    required String message,
    List<Map<String, String>>? messages,
    List<int> shownMasterclassIds = const [],
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/chat',
      data: <String, dynamic>{
        'message': message,
        if (messages != null && messages.isNotEmpty) 'messages': messages,
        if (shownMasterclassIds.isNotEmpty)
          'shown_masterclass_ids': shownMasterclassIds,
      },
    );
    final data = response.data;
    final reply = data?['reply'] as String?;
    if (reply == null) throw Exception('No reply in response');
    final raw = data?['shown_masterclass_ids'];
    final List<int> shown = [];
    if (raw is List) {
      for (final e in raw) {
        if (e is int) {
          shown.add(e);
        } else if (e is num) {
          shown.add(e.toInt());
        }
      }
    }
    final List<Map<String, dynamic>> preview = [];
    final rawPrev = data?['masterclasses_preview'];
    if (rawPrev is List) {
      for (final e in rawPrev) {
        if (e is Map) {
          preview.add(Map<String, dynamic>.from(e as Map<dynamic, dynamic>));
        }
      }
    }
    return ChatReply(
      reply: reply,
      shownMasterclassIds: shown,
      masterclassesPreview: preview,
    );
  }
}

class ChatReply {
  final String reply;
  final List<int> shownMasterclassIds;
  final List<Map<String, dynamic>> masterclassesPreview;

  const ChatReply({
    required this.reply,
    required this.shownMasterclassIds,
    this.masterclassesPreview = const [],
  });
}
