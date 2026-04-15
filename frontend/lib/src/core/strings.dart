abstract final class AppStrings {
  // -- Common / Shared --
  static const login = 'Войти';
  static const register = 'Зарегистрироваться';
  static const phoneLabel = 'Номер телефона';
  static const passwordLabel = 'Пароль';
  static const phoneFormatError = 'Введите номер в формате +7 XXX XXX-XX-XX';
  static const passwordRequired = 'Введите пароль';
  static const checkPhoneFormat = 'Проверьте формат номера';
  static const apply = 'Применить';
  static const favorites = 'Избранное';
  static const settings = 'Настройки';
  static const aboutApp = 'О приложении';
  static const notifications = 'Уведомления';
  static const copy = 'Копировать';

  // -- Login --
  static const loginTitle = 'Давайте\nзнакомиться!';
  static const loginSubtitle = 'Введите данные для входа';
  static const loginFailed = 'Не удалось выполнить вход';
  static const userNotFound = 'Пользователь с таким номером не найден';
  static const invalidPassword = 'Неверный пароль';
  static String noConnectionCheck(String url) =>
      'Нет связи с сервером. Проверьте интернет и адрес $url';

  // -- Register --
  static const registerTitle = 'Еще несколько\nвопросов';
  static const registerSubtitle = 'Укажите необходимые данные для регистрации';
  static const nameLabel = 'Фамилия Имя';
  static const repeatPasswordLabel = 'Повтори пароль';
  static const nameRequired = 'Укажите фамилию и имя';
  static const repeatPasswordRequired = 'Повторите пароль';
  static const passwordsMismatch = 'Пароли не совпадают';
  static const registerFailed = 'Не удалось зарегистрироваться';
  static const phoneAlreadyRegistered = 'Этот номер уже зарегистрирован';

  // -- Auth Service --
  static const emptyServerResponse = 'Пустой ответ сервера';
  static const registrationError = 'Ошибка регистрации';
  static const loginError = 'Ошибка входа';
  static const noConnectionFallback = 'нет связи';
  static String noConnectionDetails(String url, String error) =>
      'Нет связи с сервером. URL: $url Ошибка: $error';

  // -- Tutorial --
  static const tutorialSkip = 'Пропустить';
  static const tutorialNext = 'Далее';
  static const tutorialTitle1 = 'Ищи подходящие\nмастер-классы';
  static const tutorialDesc1 =
      'Принимай участие в мастер-классах и получай бонусы к последующей оплате, '
      'формируй свои интересы в один клик, просто формируй страницу «Мой профиль»';
  static const tutorialTitle2 = 'Общайся\nс чат-ботом';
  static const tutorialDesc2 =
      'В разделе «Чат-бот» можешь смело задавать все интересующие тебя вопросы '
      'чат-боту и проходить интервью, формируя личную ленту интересов';
  static const tutorialTitle3 = 'Следи\nза обновлениями';
  static const tutorialDesc3 =
      'В разделе «Домой» ты можешь отслеживать интересующие тебя мастер-классы '
      'по времени и месту, а также оставлять реакции и комментарии';
  static const tutorialTitle4 = 'Личный кабинет';
  static const tutorialDesc4 =
      'Ты можешь отслеживать количество посещаемых тобой мастер-классов '
      'в разделе «Мой профиль» и делиться со своими друзьями';
  static const tutorialTitle5 = 'Делись\nвпечатлениями';
  static const tutorialDesc5 =
      'Ты можешь смело оставлять комментарии к каждому мастер-классу '
      'и делиться своими эмоциями и впечатлениями с другими людьми';

  // -- Feed --
  static const feedTitle = 'Афиша мастер-классов';
  static const filtersTooltip = 'Фильтры';

  // -- Masterclass Details --
  static const aboutMasterclass = 'О мастер-классе';
  static const paymentDisclaimer =
      'Внимание! Оплата мастер-класса происходит напрямую '
      'у организатора, мы лишь предоставляем возможность '
      'найти подходящий мастер-класс и связаться с самой организацией';
  static const willAttend = 'Пойду';
  static const willNotAttend = 'Не пойду';

  // -- Masterclass Card --
  static const removeFavoriteTooltip = 'Убрать из избранного';
  static const addFavoriteTooltip = 'В избранное';
  static const soonLabelUpper = 'СКОРО';
  static const monthsShortUpper = <int, String>{
    1: 'ЯНВ',
    2: 'ФЕВ',
    3: 'МАР',
    4: 'АПР',
    5: 'МАЙ',
    6: 'ИЮН',
    7: 'ИЮЛ',
    8: 'АВГ',
    9: 'СЕН',
    10: 'ОКТ',
    11: 'НОЯ',
    12: 'ДЕК',
  };

  // -- Filter Modal --
  static const filterSetupTitle = 'Настройте фильтры ленты';
  static const filtersTitle = 'Фильтры';
  static const categorySection = 'Категория';
  static const audienceSection = 'Аудитория';
  static const formatSection = 'Формат';
  static const priceSection = 'Стоимость';

  static const categoryDesign = 'Дизайн';
  static const categoryBeauty = 'Бьюти';
  static const categoryCraft = 'Творчество';
  static const categoryCooking = 'Готовка';
  static const categoryArt = 'Искусство';
  static const categoryPhoto = 'Фото';
  static const categoryTech = 'Технологии';
  static const categoryMusic = 'Музыка';
  static const categoryDance = 'Танцы';
  static const categoryPersonalDev = 'Саморазвитие';
  static const categoryHomeGarden = 'Дом и сад';
  static const categoryWellness = 'Спорт и здоровье';
  static const categoryTheater = 'Театр и кино';

  static const audienceAdults = 'Взрослые';
  static const audienceKids = 'Дети';
  static const audienceFamilies = 'Семья';
  static const audienceTeens = 'Подростки';
  static const audienceCouples = 'Пары';
  static const audienceCorporate = 'Корпоратив';
  static const audienceHobbyists = 'Хобби';
  static const audienceProfessionals = 'Профи';

  static const formatOnline = 'Онлайн';
  static const formatOffline = 'Офлайн';

  // -- Week Date Strip --
  static const monthsShort = <String>[
    'янв',
    'фев',
    'мар',
    'апр',
    'май',
    'июн',
    'июл',
    'авг',
    'сен',
    'окт',
    'ноя',
    'дек',
  ];
  static const prevWeekTooltip = 'Предыдущая неделя';
  static const nextWeekTooltip = 'Следующая неделя';

  // -- Chat --
  static const chatTitle = 'Чат-бот';
  static const chatEmptyHint = 'Напишите, какой мастер-класс ищете';
  static const chatThinking = 'Думаю...';
  static const chatInputHint = 'Опиши свои пожелания по МК';
  static const chatOpenCard = 'Открыть карточку';
  static String chatOpenCardA11y(String title) =>
      'Открыть карточку мастер-класса $title';

  // -- Profile --
  static const showData = 'Показать данные';
  static const logout = 'Выйти';
  static const goToChat = 'Перейти в чат-бот';
  static const profileLoadFailed = 'Failed to load profile';

  // -- Profile Data --
  static const yourData = 'Ваши данные';
  static const profileDataExplanation =
      'Номер телефона и пароль отображаются для вашего удобства. '
      'Пароль хранится только на этом устройстве после последнего '
      'успешного входа или регистрации.';
  static const phoneField = 'Телефон';
  static const passwordField = 'Пароль';
  static const passwordPlaceholder =
      'Выполните вход на этом устройстве ещё раз - тогда пароль появится здесь.';
  static const showPassword = 'Показать';
  static const hidePassword = 'Скрыть';

  // -- Wishlist --
  static const wishlistEmpty = 'В избранном пока пусто';

  // -- About App --
  static String appVersion(String version) => 'Версия $version';
  static const aboutDescription =
      'Приложение помогает находить мастер-классы по интересам, сохранять '
      'понравившиеся события в избранном и уточнять запросы через чат-бота.';
  static const aboutBullet1 = 'Лента с фильтрами по дате и категориям';
  static const aboutBullet2 = 'Чат-бот для подбора мастер-классов';
  static const aboutBullet3 = 'Избранное и профиль с вашими данными';
  static const aboutPaymentNote =
      'Оплата мастер-классов, как правило, проходит у организаторов событий; '
      'мы помогаем с поиском и информацией.';
  static const telegramSection = 'Telegram';
  static const telegramChannelNote =
      'Новости и обновления приложения - в канале';

  // -- Date Formatter --
  static const monthsGenitive = <int, String>{
    1: 'января',
    2: 'февраля',
    3: 'марта',
    4: 'апреля',
    5: 'мая',
    6: 'июня',
    7: 'июля',
    8: 'августа',
    9: 'сентября',
    10: 'октября',
    11: 'ноября',
    12: 'декабря',
  };
  static const soonDate = 'Скоро';
}
