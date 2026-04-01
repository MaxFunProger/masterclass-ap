import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/api_client.dart';
import '../../../../core/analytics.dart';
import '../../../../core/strings.dart';
import '../../../masterclasses/domain/masterclass.dart';
import '../../chat_state.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

/// Нижний отступ списка под поле ввода и safe area.
const double _kChatComposerReserve = 104;

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(BuildContext context, String text) async {
    final chat = context.read<ChatState>();
    final trimmed = text.trim();
    if (trimmed.isEmpty || chat.loading) return;
    Analytics.botUsed();
    _controller.clear();
    _scrollToEnd();
    try {
      await chat.send(trimmed);
      if (!mounted) return;
      _scrollToEnd();
    } catch (_) {
      if (!mounted) return;
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatState>();
    final messages = chat.uiMessages;
    final loading = chat.loading;

    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final listBottomPad = 12.0 + bottomSafe + _kChatComposerReserve;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          AppStrings.chatTitle,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: messages.isEmpty && !loading
                ? Padding(
                    padding: EdgeInsets.only(bottom: listBottomPad),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            AppStrings.chatEmptyHint,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(16, 12, 16, listBottomPad),
                    itemCount: messages.length + (loading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SvgPicture.asset(
                                  'assets/avatar_chat.svg',
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          AppStrings.chatThinking,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final msg = messages[index];
                      final isUser = msg['role'] == 'user';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isUser) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SvgPicture.asset(
                                  'assets/avatar_chat.svg',
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Flexible(
                              child: Card(
                                color: isUser
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  child: isUser
                                      ? Text(
                                          msg['content'] ?? '',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                        )
                                      : _AssistantMessageWithMcPreviews(
                                          content: msg['content'] ?? '',
                                          previewRows: _parseMcPreviews(msg),
                                          textStyle:
                                              const TextStyle(fontSize: 15),
                                        ),
                                ),
                              ),
                            ),
                            if (isUser) const SizedBox(width: 12),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: AppStrings.chatInputHint,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: 3,
                          minLines: 1,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (v) => _send(context, v),
                          enabled: !loading,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: Colors.white,
                      elevation: 3,
                      shadowColor: Colors.black26,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: loading
                            ? null
                            : () => _send(context, _controller.text),
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/icon_send.svg',
                              width: 26,
                              height: 26,
                              colorFilter: loading
                                  ? ColorFilter.mode(
                                      Theme.of(context).disabledColor,
                                      BlendMode.srcIn,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<Map<String, dynamic>> _parseMcPreviews(Map<String, String> msg) {
  final s = msg['mc_previews'];
  if (s == null || s.isEmpty) return [];
  try {
    final decoded = jsonDecode(s);
    if (decoded is! List) return [];
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {
    return [];
  }
}

/// Делит ответ бота на блоки (абзацы / пункты списка), чтобы вставить фото после описания каждого МК.
List<String> _splitAssistantIntoBlocks(String content, int previewCount) {
  final trimmed = content.trim();
  if (trimmed.isEmpty) return [];

  List<String> blocks = trimmed
      .split(RegExp(r'\n\s*\n'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  if (blocks.length >= previewCount && previewCount > 0) {
    return blocks;
  }

  final numbered = trimmed.split(RegExp(r'\n(?=\d+\.\s)'));
  if (numbered.length >= previewCount && previewCount > 1) {
    return numbered.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  final bullets = trimmed.split(RegExp(r'\n(?=[*\-\*]\s)'));
  if (bullets.length >= previewCount && previewCount > 1) {
    return bullets.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  return blocks.isEmpty ? [trimmed] : blocks;
}

/// Вводный абзац без конкретного МК ("Вот пара подходящих...") - к нему не цепляем превью.
bool _isChatIntroOnlyBlock(String paragraph) {
  final t = paragraph.trim();
  if (t.contains('"')) return false;
  if (RegExp(r'\d{3,5}\s*(руб|₽)').hasMatch(t)) return false;
  if (RegExp(
          r'\d{1,2}\s+(январ|феврал|март|апрел|ма[ей]|июн|июл|август|сентяб|октяб|нояб|декабр)',
          caseSensitive: false)
      .hasMatch(t)) {
    return false;
  }
  final low = t.toLowerCase();
  if (low.length > 220) return false;
  return RegExp(
    r'^\s*(вот|итак|смотри|держи|подобрал|подобрала|наш[её]л|нашла|есть\s+(пара|несколько|вариант)|'
    r'here\s+are|there\s+are)\b',
    caseSensitive: false,
  ).hasMatch(low);
}

const _genericTitleTokens = <String>{
  'мастер-класс',
  'мастер-класса',
  'мастер-классу',
  'мастер-классом',
  'мастер-классе',
  'мастер-классов',
  'мастер-классам',
  'мастер-классами',
  'мастеркласс',
  'мастер',
  'класс',
  'класса',
  'классу',
};

/// Сопоставление абзаца с названием МК без ложных срабатываний на "мастер-класс" во вступлении.
bool _paragraphMentionsTitle(String paragraph, String title) {
  if (_isChatIntroOnlyBlock(paragraph)) return false;

  final t = title.trim();
  if (t.isEmpty) return false;
  final h = paragraph.toLowerCase();
  var tl = t
      .toLowerCase()
      .replaceAll(RegExp(r'["""„]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (h.contains(tl)) return true;
  if (tl.length > 28 && h.contains(tl.substring(0, 28))) return true;

  final words = tl
      .split(RegExp(r'[\s,.;:!? - \-/]+'))
      .map((w) => w.trim())
      .where((w) => w.length >= 5 && !_genericTitleTokens.contains(w))
      .toList();

  if (words.length >= 2) {
    final hits = words.where((w) => h.contains(w)).length;
    if (hits >= 2) return true;
  }
  for (final w in words) {
    if (w.length >= 10 && h.contains(w)) return true;
  }
  return false;
}

/// Текст ответа + после каждого подходящего абзаца - миниатюра; несопоставленные - в конце.
class _AssistantMessageWithMcPreviews extends StatelessWidget {
  const _AssistantMessageWithMcPreviews({
    required this.content,
    required this.previewRows,
    required this.textStyle,
  });

  final String content;
  final List<Map<String, dynamic>> previewRows;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    if (previewRows.isEmpty) {
      return Text(content, style: textStyle);
    }

    final blocks = _splitAssistantIntoBlocks(content, previewRows.length);
    final placed = <int>{};
    final children = <Widget>[];

    for (var b = 0; b < blocks.length; b++) {
      final p = blocks[b];
      if (b > 0) {
        children.add(const SizedBox(height: 10));
      }
      children.add(Text(p, style: textStyle));

      // Не более одной миниатюры на абзац - иначе длинный текст с общими словами
      // мог сопоставиться с несколькими title из одной выдачи и дублировать карточки.
      for (var i = 0; i < previewRows.length; i++) {
        if (placed.contains(i)) continue;
        String title;
        try {
          title = Masterclass.fromJson(previewRows[i]).title;
        } catch (_) {
          continue;
        }
        if (_paragraphMentionsTitle(p, title)) {
          placed.add(i);
          children.add(
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _ChatMcPhotoTile(row: previewRows[i]),
              ),
            ),
          );
          break;
        }
      }
    }

    final trailing = <Widget>[];
    for (var i = 0; i < previewRows.length; i++) {
      if (placed.contains(i)) continue;
      trailing.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _ChatMcPhotoTile(row: previewRows[i]),
          ),
        ),
      );
    }
    if (trailing.isNotEmpty) {
      children.addAll(trailing);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

/// Одна кликабельная миниатюра МК + подсказка, что можно открыть карточку.
class _ChatMcPhotoTile extends StatelessWidget {
  const _ChatMcPhotoTile({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final Masterclass mc;
    try {
      mc = Masterclass.fromJson(row);
    } catch (_) {
      return const SizedBox.shrink();
    }
    final url = ApiClient.resolveImageUrl(mc.imageUrl);
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: AppStrings.chatOpenCardA11y(mc.title),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Analytics.cardView(mc.id);
            context.push('/masterclass', extra: {
              'masterclass': mc,
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 132,
                    height: 100,
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.primary,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => ColoredBox(
                        color: Colors.grey.shade300,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 15,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppStrings.chatOpenCard,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
