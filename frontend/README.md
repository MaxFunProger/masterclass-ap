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

Хост и порт задаются через `--dart-define` при сборке:

| Параметр | По умолчанию | Назначение |
|----------|-------------|-----------|
| `API_HOST` | debug: `10.0.2.2` (эмулятор); release: прод | Хост бэкенда |
| `API_PORT` | `80` | Порт бэкенда |
| `CHAT_HOST` | тот же, что `API_HOST` | Хост агента |
| `CHAT_PORT` | `5000` | Порт агента |

Пример для нестандартного порта:

```bash
flutter run --dart-define=API_HOST=<ip> --dart-define=API_PORT=8080
```

Без `--dart-define` release-сборка использует порт 80 (бэкенд) и 5000 (чат).

Картинки мастер-классов: поле `image_url` из JSON. Относительные пути дополняются базовым URL бэкенда (`ApiClient.resolveImageUrl`), абсолютные используются как есть.

## Сборка

```bash
cd frontend
flutter pub get
flutter build apk
```

Или через скрипт из корня репозитория: `./scripts/build_android_apk.sh` (включает генерацию иконки).
