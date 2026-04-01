import 'package:appmetrica_plugin/appmetrica_plugin.dart';

const _apiKey = '507fbb9f-452e-49f5-8d89-0ab0b07dd0db';

class Analytics {
  static Future<void> init() async {
    await AppMetrica.activate(
      AppMetricaConfig(_apiKey, logs: true),
    );
  }

  static void cardView(int masterclassId) {
    AppMetrica.reportEventWithMap('card_view', {'masterclass_id': masterclassId});
  }

  static void clickAttend(int masterclassId) {
    AppMetrica.reportEventWithMap('click_attend', {'masterclass_id': masterclassId});
  }

  static void clickNotAttend(int masterclassId) {
    AppMetrica.reportEventWithMap('click_not_attend', {'masterclass_id': masterclassId});
  }

  static void favoriteAdd(int masterclassId) {
    AppMetrica.reportEventWithMap('favorite_add', {'masterclass_id': masterclassId});
  }

  static void favoriteRemove(int masterclassId) {
    AppMetrica.reportEventWithMap('favorite_remove', {'masterclass_id': masterclassId});
  }

  static void searchUsed(Map<String, dynamic> filters) {
    AppMetrica.reportEventWithMap('search_used', filters.map(
      (k, v) => MapEntry(k, v?.toString() ?? ''),
    ));
  }

  static void botUsed() {
    AppMetrica.reportEvent('bot_used');
  }

  static void clickWebsite(int masterclassId) {
    AppMetrica.reportEventWithMap('click_website', {'masterclass_id': masterclassId});
  }

  static void clickTelegram(int masterclassId) {
    AppMetrica.reportEventWithMap('click_telegram', {'masterclass_id': masterclassId});
  }
}
