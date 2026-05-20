# frontend

Flutter-приложение **canDo!** — афиша мастер-классов (Android, в перспективе iOS).

## Что внутри

Четыре вкладки с bottom navigation bar (`go_router` + `StatefulShellRoute`):

1. **Лента** — список мастер-классов с фильтрами (категория, аудитория, формат, цена, дата, рейтинг), полоска дат по неделям, бесконечный скролл. Карточка ведёт на детальный экран с полным описанием, ссылками на сайт и Telegram.
2. **Чат** — диалог с Yandex GPT через agent sidecar (`POST /chat`). Бот подбирает мастер-классы по запросу, уточняет параметры, возвращает превью с карточками.
3. **Избранное** — сохранённые мастер-классы (синхронизируются с бэкендом через `/user/favorites`).
4. **Профиль** — данные пользователя, настройки, информация о приложении.

Авторизация: телефон + пароль (`/register`, `/login`). После первого входа показывается туториал. Сессия хранится в `SharedPreferences`.

## Структура

```
lib/
  main.dart                         точка входа
  src/
    app.dart                        MaterialApp.router, тема, маршруты
    core/
      api_client.dart               HTTP-клиент (dio), базовые URL
      session_storage.dart          хранение сессии (SharedPreferences)
      strings.dart                  централизованные UI-строки (AppStrings)
      providers/                    FavoritesProvider
      widgets/                      общие виджеты
      utils/                        форматирование дат, телефонов
    features/
      auth/                         авторизация, регистрация, туториал
      masterclasses/                лента, детали, фильтры, карточки
      chat/                         чат с ботом
      profile/                      профиль, избранное, настройки
      navigation/                   ScaffoldWithNavBar (bottom bar)
```

## Зависимости

| Пакет | Зачем |
|-------|-------|
| `dio` | HTTP-клиент |
| `provider` | State management (`ChatState`, `FavoritesProvider`) |
| `go_router` | Навигация и вложенные маршруты |
| `shared_preferences` | Локальное хранение сессии и настроек |
| `flutter_svg` | SVG-ассеты |
| `url_launcher` | Открытие ссылок в браузере |
| `flutter_launcher_icons` | Генерация иконки из `assets/app_icon.png` |

## Подключение к бэкенду

| Параметр | По умолчанию | Назначение |
|----------|-------------|-----------|
| `API_HOST` | debug: `10.0.2.2` (эмулятор); release: прод | Хост бэкенда |
| `API_PORT` | `80` | Порт бэкенда |
| `CHAT_HOST` | тот же, что `API_HOST` | Хост агента |
| `CHAT_PORT` | `5000` | Порт агента |

## Сборка

### Android

Из корня репозитория: `./scripts/build_android_apk.sh`

Для генерации бандла в google play: `./scripts/build_android_aab.sh`

### iOS (только на macOS)

iOS-релиз нельзя собрать на Linux — нужен **macOS + Xcode + CocoaPods**, плюс Apple Developer аккаунт для подписи. Папка `frontend/ios/` в репозитории отсутствует и создаётся одноразово.

Первый раз на macOS:

```bash
sudo gem install cocoapods       # если ещё не установлен
./scripts/setup_ios_platform.sh  # flutter create --platforms=ios + Info.plist + Podfile + bundle id
open frontend/ios/Runner.xcworkspace
# В Xcode: Signing & Capabilities → выбрать команду разработчика (automatic provisioning)
#          General → Minimum Deployments → iOS 13.0
```

Bundle ID по умолчанию — **`com.cando.app`** (`PRODUCT_BUNDLE_IDENTIFIER` во всех Runner-конфигурациях `project.pbxproj`). Переопределить:

```bash
IOS_BUNDLE_ID=com.example.app ./scripts/setup_ios_platform.sh
```

Сама сборка:

```bash
./scripts/build_ios.sh                  # release IPA для App Store / Transporter
BUILD_TARGET=app ./scripts/build_ios.sh # .app для запуска на устройстве через Xcode
```

Переменные те же, что для Android: `API_HOST`, `API_PORT`, `CHAT_HOST`, `CHAT_PORT`.

Важно: бэкенд по `http://158.160.158.103` без TLS — iOS блокирует cleartext через ATS. Скрипт `setup_ios_platform.sh` пропишет в `Info.plist` именованное исключение для этого IP. Для App Store правильнее **перевести бэкенд на HTTPS** (Let's Encrypt + reverse proxy), иначе модератор может попросить обоснование. Для AppMetrica дополнительно потребуется заполнить «Privacy Manifest» (`PrivacyInfo.xcprivacy`) и раздел «Data Collection» в App Store Connect.