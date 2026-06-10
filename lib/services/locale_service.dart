import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class LocaleService {
  static const String _languageKey = 'language';
  static String _currentLanguage = 'ru';
  static final List<void Function()> _listeners = [];

  static void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  static void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  static String get currentLanguage => _currentLanguage;
  static bool get isEnglish => _currentLanguage == 'en';

  static Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_languageKey) ?? 'ru';
    debugPrint('Language loaded: $_currentLanguage');
  }

  static Future<void> setLanguage(String language) async {
    debugPrint('setLanguage called: $language');
    _currentLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
    debugPrint('Language saved, notifying listeners');
    for (final listener in _listeners) {
      listener();
    }
    _clearServiceCaches();
  }

  static void _clearServiceCaches() {
    try {
      AuthService.clearCaches();
    } catch (e) {
      debugPrint('Cache clear error: $e');
    }
  }

  static String translate(String key) {
    return _getTranslation(key, _currentLanguage);
  }

  static String _getTranslation(String key, String language) {
    final lang = language == 'en' ? 'en' : 'ru';
    return _translations[key]?[lang] ?? key;
  }

  static String translateDbData(String text) {
    if (text.isEmpty) return text;
    
    // Если текущий язык русский
    if (_currentLanguage == 'ru') {
      // Если текст уже есть в ключах (это русский), возвращаем как есть
      if (_dbTranslations.containsKey(text)) {
        return text;
      }
      // Иначе пытаемся найти английский текст в обратном словаре
      return _dbTranslationsReverse[text] ?? text;
    } else {
      // Английский: ищем прямой перевод (русский -> английский)
      return _dbTranslations[text] ?? text;
    }
  }

  // Словарь для перевода данных из БД (рус -> анг)
  static final Map<String, String> _dbTranslations = {
    // Комплексы (категории)
    'Броски': 'Shooting',
    'Дриблинг': 'Dribbling',
    'Пасы': 'Passing',
    'Прыжки': 'Jumping',
    'Защита': 'Defense',
    'Реабилитация': 'Rehabilitation',
    'Физическая подготовка': 'Physical Training',
    
    // Тренировки (workouts)
    'Утренняя тренировка': 'Morning Workout',
    'Вечерняя тренировка': 'Evening Workout',
    'Разминка': 'Warm-up',
    'Отработка бросков': 'Shooting Practice',
    'Отработка дриблинга': 'Dribbling Practice',
    'Отработка пасов': 'Passing Practice',
    'Тренировка прыжков': 'Jumping Training',
    'Защитные упражнения': 'Defensive Exercises',
    'Растяжка': 'Stretching',
    'Силовая тренировка': 'Strength Training',
    'Кардио тренировка': 'Cardio Training',
    
    // Общие
    'Баскетбол': 'Basketball',
    'Тренировка': 'Training',
    'Упражнение': 'Exercise',
    'Комплекс': 'Complex',
    'Начинающий': 'Beginner',
    'Средний': 'Intermediate',
    'Продвинутый': 'Advanced',
    'Для всех': 'For All',
    'Нет упражнения': 'No exercise',
    
    // Упражнения (короткие названия)
    'Бросок': 'Shooting',
    'Завершение': 'Finishing',
    'Передача': 'Passing',
    'Вертикальный прыжок': 'Vertical Jump',
    'Тренировка средних бросков': 'Mid-Range Shooting Practice',
    'Броски с трехочковой линии': '3-Point Shooting',
    'Тренировка бросков Стефа Карри': 'Steph Curry Shooting Practice',
    'Тренировка штрафных бросков': 'Free Throw Practice',
    'Бросковая разминка': 'Shooting Warm-up',
    'Разминка дриблинга': 'Dribbling Warm-up',
    'Тренировка Кайри Ирвинга': 'Kyrie Irving Dribbling Practice',
    'Тренировка на чувство мяча': 'Ball Handling Practice',
    'Тренировка дриблинга с двумя мячами': 'Two-Ball Dribbling',
    'Тренировка завершений в воздухе под кольцом': 'Air Finish Practice',
    'Разминка завершений': 'Finishing Warm-up',
    'Тренировка завершений атак': 'Attack Finishing',
    'Разминка передач в стену': 'Wall Passing Warm-up',
    'Тренировка передач в паре': 'Partner Passing',
    'Тренировка передач со стеной': 'Wall Passing',
    'Разминочные прыжки для разогрева': 'Jumping Jacks',
    'Взрывная тренировка прыжков': 'Explosive Jump Training',
    'Тренировка силы ног в тренажерном зале': 'Leg Strength Gym',
    'Реабилитация голеностопа': 'Ankle Rehabilitation',
    'Разминка всего тела': 'Full Body Warm-up',
    'Реабилитация таза': 'Hip Rehabilitation',
    'Реабилитация поясницы': 'Lower Back Rehabilitation',
    'Реабилитация плеч': 'Shoulder Rehabilitation',
    'Реабилитация локтей': 'Elbow Rehabilitation',
    'Реабилитация кистей': 'Wrist Rehabilitation',
    'Реабилитация коленей': 'Knee Rehabilitation',
    'Бросок после шага от трехочковой линии': 'Step-back 3-pointer',
    'Броски с шагом в сторону': 'Side-step Shooting',
    'Броски после разворота на 180': '180-degree Turnaround Shot',
    'V - переводы перед собой': 'V-Dribble',
    'Восьмерка': 'Figure-8',
    'Переводы за спиной': 'Behind-the-back Dribble',
    'Броски одной рукой об щиток': 'One-hand Bank Shot',
    'Евростеп': 'Euro Step',
    'Флоатер': 'Floater',
    'Передача от груди': 'Chest Pass',
    'Передача с отскоком об пол': 'Bounce Pass',
    'Передача над головой': 'Overhead Pass',
    'Прыжки с колен': 'Kneeling Jumps',
    'Прыжки со скамейки': 'Box Jumps',
    'Прыжки на месте': 'Standing Jumps',
    'Подъемы на икры': 'Calf Raises',
    'Ротация голеностопа с резинкой': 'Ankle Band Rotation',
'Ходьба на пятках': 'Heel Walks',
     
     // Программы
     'Неделя новичка': 'Beginner Week',
     'Две недели': 'Two Weeks',
     'Месяц мастера': 'Master\'s Month',
     'Базовая программа для начинающих. 7 дней тренировок.': 'Basic program for beginners. 7 days of training.',
     'Программа на 14 дней для развития базовых навыков.': '14-day program for developing basic skills.',
     'Интенсивная программа на 30 дней для продвинутых.': 'Intensive 30-day program for advanced users.',
     'Политика конфиденциальности': 'Privacy Policy',
  };

  // Обратный словарь для перевода с английского на русский (строится автоматически)
  static final Map<String, String> _dbTranslationsReverse = 
      _dbTranslations.map((key, value) => MapEntry(value, key));

  // Интерфейсные переводы (все кнопки, заголовки, сообщения)
  static final Map<String, Map<String, String>> _translations = {
    'Настройки': {'ru': 'Настройки', 'en': 'Settings'},
    'Язык': {'ru': 'Язык', 'en': 'Language'},
    'Выберите язык': {'ru': 'Выберите язык', 'en': 'Select language'},
    'Русский': {'ru': 'Русский', 'en': 'Russian'},
    'English': {'ru': 'English', 'en': 'English'},
    'Вибрация': {'ru': 'Вибрация', 'en': 'Vibration'},
    'Вибрация при нажатиях': {
      'ru': 'Вибрация при нажатиях',
      'en': 'Vibration on taps',
    },
    'Фон': {'ru': 'Фон', 'en': 'Background'},
    'Убрать фон': {
      'ru': 'Убрать фон',
      'en': 'Remove background',
    },
    'Показать темный фон': {
      'ru': 'Показать темный фон',
      'en': 'Show dark background',
    },
    'Данные': {'ru': 'Данные', 'en': 'Data'},
    'Очистка кэша': {'ru': 'Очистка кэша', 'en': 'Clear cache'},
    'Обратная связь': {'ru': 'Обратная связь', 'en': 'Feedback'},
    'Связаться с нами': {'ru': 'Связаться с нами', 'en': 'Contact us'},
    'Оценить приложение': {'ru': 'Оценить приложение', 'en': 'Rate app'},
    'Поделиться приложением': {
      'ru': 'Поделиться приложением',
      'en': 'Share app',
    },
    'О приложении': {'ru': 'О приложении', 'en': 'About'},
    'Версия приложения': {'ru': 'Версия приложения', 'en': 'App version'},
    'Разработчик': {'ru': 'Разработчик', 'en': 'Developer'},
    'Вы уверены?': {'ru': 'Вы уверены?', 'en': 'Are you sure?'},
    'Очистить': {'ru': 'Очистить', 'en': 'Clear'},
    'Кэш очищен': {'ru': 'Кэш очищен', 'en': 'Cache cleared'},
    'Политика конфиденциальности': {'ru': 'Политика конфиденциальности', 'en': 'Privacy Policy'},
    'Basketball Training Team': {
      'ru': 'Basketball Training Team',
      'en': 'Basketball Training Team',
    },
    'Доступные тренировки:': {
      'ru': 'Доступные тренировки:',
      'en': 'Available workouts:',
    },
    'Ошибка:': {'ru': 'Ошибка:', 'en': 'Error:'},
    'Без названия': {'ru': 'Без названия', 'en': 'Untitled'},
    'мин.': {'ru': 'мин.', 'en': 'min.'},
    'Тренировки': {'ru': 'Тренировки', 'en': 'Workouts'},
    'Тренер': {'ru': 'Тренер', 'en': 'Coach'},
    'Упражнения': {'ru': 'Упражнения', 'en': 'Exercises'},
    'Избранное': {'ru': 'Избранное', 'en': 'Favorites'},
    'Профиль': {'ru': 'Профиль', 'en': 'Profile'},
    'Вход': {'ru': 'Вход', 'en': 'Login'},
'Регистрация': {'ru': 'Регистрация', 'en': 'Register'},
     'Email': {'ru': 'Email', 'en': 'Email'},
     'Пароль': {'ru': 'Пароль', 'en': 'Password'},
      'Выйти': {'ru': 'Выйти', 'en': 'Logout'},
    'Зарегистрироваться': {'ru': 'Зарегистрироваться', 'en': 'Register'},
     'Нет аккаунта?': {'ru': 'Нет аккаунта?', 'en': 'No account?'},
     'Есть аккаунт?': {'ru': 'Есть аккаунт?', 'en': 'Have an account?'},

     // Политика конфиденциальности
     'privacy_title': {
       'ru': 'Политика конфиденциальности',
       'en': 'Privacy Policy',
     },
     'privacy_text': {
        'ru': 'Мы ценим вашу конфиденциальность. Данная политика объясняет, как мы собираем, используем и защищаем вашу информацию.\n\n'
             '1. Сбор данных\n'
             'Мы собираем только те данные, которые вы предоставляете добровольно при регистрации: email, никнейм и avatar (если загрузите).\n'
             'Дополнительно мы автоматически сохраняем ваш прогресс тренировок, избранные упражнения и настройки приложения.\n\n'
             '2. Использование данных\n'
             'Ваши данные используются для:\n'
             '   - Авторизации в приложении\n'
             '   - Сохранения вашего прогресса тренировок\n'
             '   - Персонализации интерфейса (язык, настройки)\n'
             '   - Улучшения качества приложения\n\n'
             '3. Хранение данных\n'
             'Данные хранятся в защищённых облачных сервисах (Supabase). Мы применяем стандартные меры безопасности для защиты от несанкционированного доступа.\n\n'
             '4. Передача данных третьим лицам\n'
             'Мы НЕ продаём и НЕ передаём ваши персональные данные третьим лицам. Данные могут быть доступны только вам и администраторам приложения.\n\n'
             '5. Ваши права\n'
             'Вы можете в любой момент:\n'
             '   - Удалить свой аккаунт (все ваши данные будут безвозвратно удалены)\n'
             '   - Изменить персональную информацию\n'
             '   - Отозвать согласие на обработку данных\n\n'
             '6. Cookie и отслеживание\n'
             'Приложение не использует cookies и аналогичные технологии для отслеживания.\n\n'
             '7. Изменения политики\n'
             'Мы можем обновлять эту политику. Актуальная версия всегда доступна в приложении.\n\n'
             '8. Контакты\n'
             'По вопросам конфиденциальности пишите: gluk.dan@gmail.com\n\n'
             'Дата последнего обновления: 2025',
       'en': 'We value your privacy. This policy explains how we collect, use and protect your information.\n\n'
             '1. Data Collection\n'
             'We only collect data that you voluntarily provide during registration: email, nickname, and avatar (if uploaded).\n'
             'Additionally, we automatically store your workout progress, favorite exercises, and app preferences.\n\n'
             '2. Use of Data\n'
             'Your data is used for:\n'
             '   - Authentication in the app\n'
             '   - Saving your workout progress\n'
             '   - Personalizing the interface (language, settings)\n'
             '   - Improving app quality\n\n'
             '3. Data Storage\n'
             'Data is stored in secure cloud services (Supabase). We apply standard security measures to protect against unauthorized access.\n\n'
             '4. Data Sharing\n'
             'We DO NOT sell or transfer your personal data to third parties. Data may be accessible only to you and app administrators.\n\n'
             '5. Your Rights\n'
             'You can at any time:\n'
             '   - Delete your account (all your data will be permanently deleted)\n'
             '   - Change personal information\n'
             '   - Withdraw consent to data processing\n\n'
             '6. Cookies & Tracking\n'
             'The app does not use cookies or similar tracking technologies.\n\n'
             '7. Policy Changes\n'
             'We may update this policy. The current version is always available in the app.\n\n'
             '8. Contact\n'
             'For privacy inquiries email: gluk.dan@gmail.com\n\n'
             'Last updated: 2025',
     },
    'Главная': {'ru': 'Главная', 'en': 'Home'},
    'Тренировочные комплексы': {
      'ru': 'Тренировочные комплексы',
      'en': 'Training Complexes',
    },
    'Тренер AI': {'ru': 'Тренер AI', 'en': 'AI Coach'},
    'Online': {'ru': 'Online', 'en': 'Online'},
    'Подтверждение email': {'ru': 'Подтверждение email', 'en': 'Email verification'},
    'Привет! Я AI тренер': {
      'ru': 'Привет! Я AI тренер',
      'en': 'Hello! I\'m AI Coach',
    },
    'Спроси меня о тренировках': {
      'ru': 'Спроси меня о тренировках,\nтехнике или тактике игры',
      'en': 'Ask me about workouts,\ntechnique or game tactics',
    },
    'Как улучшить бросок?': {
      'ru': 'Как улучшить бросок?',
      'en': 'How to improve shooting?',
    },
    'Упражнения для ног': {'ru': 'Упражнения для ног', 'en': 'Leg exercises'},
    'Техника ведения': {'ru': 'Техника ведения', 'en': 'Dribbling technique'},
    'Написать сообщение': {
      'ru': 'Напиши сообщение...',
      'en': 'Write a message...',
    },
    'Добавить в избранное': {
      'ru': 'Добавить в избранное',
      'en': 'Add to favorites',
    },
    'Поделиться': {'ru': 'Поделиться', 'en': 'Share'},
    'Начать тренировку': {'ru': 'Начать тренировку', 'en': 'Start workout'},
    'Пропустить': {'ru': 'Пропустить', 'en': 'Skip'},
    'Пауза': {'ru': 'Пауза', 'en': 'Pause'},
    'Продолжить': {'ru': 'Продолжить', 'en': 'Continue'},
    'Начать заново': {'ru': 'Начать заново', 'en': 'Start over'},
    'Подходы': {'ru': 'Подходы', 'en': 'Sets'},
    'Повторения': {'ru': 'Повторения', 'en': 'Reps'},
    'Отдых': {'ru': 'Отдых', 'en': 'Rest'},
    'Секунды': {'ru': 'Секунды', 'en': 'Seconds'},
    'Описание': {'ru': 'Описание', 'en': 'Description'},
    'Как выполнять': {'ru': 'Как выполнять', 'en': 'How to perform'},
    'Советы': {'ru': 'Советы', 'en': 'Tips'},
    'Назад': {'ru': 'Назад', 'en': 'Back'},
    'Далее': {'ru': 'Далее', 'en': 'Next'},
    'Завершить день': {'ru': 'Завершить день', 'en': 'Finish day'},
    'Готово': {'ru': 'Готово', 'en': 'Done'},
'Start': {'ru': 'Начать', 'en': 'Start'},
     'Старт': {'ru': 'Старт', 'en': 'Start'},
     'Continue': {'ru': 'Продолжить', 'en': 'Continue'},
     'Сброс': {'ru': 'Сброс', 'en': 'Reset'},
    'Training': {'ru': 'Программы', 'en': 'Training'},
    'Unable to start program': {'ru': 'Не удалось начать программу', 'en': 'Unable to start program'},
    'No exercises found for this day': {'ru': 'Упражнения не найдены для этого дня', 'en': 'No exercises found for this day'},
    'Error': {'ru': 'Ошибка', 'en': 'Error'},
    'Retry': {'ru': 'Повторить', 'en': 'Retry'},
    'No exercises found': {'ru': 'Упражнения не найдены', 'en': 'No exercises found'},
    'Program Days': {'ru': 'Дни программы', 'en': 'Program Days'},
    'Not started': {'ru': 'Не начато', 'en': 'Not started'},
    'Locked': {'ru': 'Заблокировано', 'en': 'Locked'},
    'No days found': {'ru': 'Дни не найдены', 'en': 'No days found'},
    'Workout': {'ru': 'Тренировка', 'en': 'Workout'},
    'No programs found': {'ru': 'Программы не найдены', 'en': 'No programs found'},
    'День': {'ru': 'День', 'en': 'Day'},
    'Please try again later': {'ru': 'Попробуйте позже', 'en': 'Please try again later'},
    'Program has no days': {'ru': 'В программе нет дней', 'en': 'Program has no days'},
    'Day not linked to workout': {'ru': 'День не привязан к тренировке', 'en': 'Day not linked to workout'},
    'Complete': {'ru': 'Завершить', 'en': 'Complete'},
    'Завершить': {'ru': 'Завершить', 'en': 'Complete'},
    
    // Для экрана упражнений
    'Exercise': {'ru': 'Упражнение', 'en': 'Exercise'},
    'Day': {'ru': 'День', 'en': 'Day'},
    'Completed': {'ru': 'Завершено', 'en': 'Completed'},
    'In progress': {'ru': 'В процессе', 'en': 'In progress'},
    'Start Training': {'ru': 'Начать тренировку', 'en': 'Start Training'},
    'Review': {'ru': 'Просмотр', 'en': 'Review'},
    
    // Таймер
    'Таймер': {'ru': 'Таймер', 'en': 'Timer'},
    'осталось': {'ru': 'осталось', 'en': 'remaining'},
    'Время вышло!': {'ru': 'Время вышло!', 'en': 'Time is up!'},
    'Таймер завершен. Нажмите "Продолжить" для перехода к следующему упражнению.': {
      'ru': 'Таймер завершен. Нажмите "Продолжить" для перехода к следующему упражнению.',
      'en': 'Timer completed. Press "Continue" to go to the next exercise.',
    },
'Day completed!': {'ru': 'День завершен!', 'en': 'Day completed!'},
     'Вы завершили все упражнения на сегодня. Отлично работа!': {
       'ru': 'Вы завершили все упражнения на сегодня. Отлично работа!',
       'en': 'You completed all exercises for today. Great work!',
     },
'Заблокировано': {'ru': 'Заблокировано', 'en': 'Locked'},
      'Близко к завершению': {'ru': 'Близко к завершению', 'en': 'Almost completed'},
      
     // Программы
    'Программы': {'ru': 'Программы', 'en': 'Programs'},
    'дней': {'ru': 'дней', 'en': 'days'},
    'Начать программу': {'ru': 'Начать программу', 'en': 'Start program'},
     'Программа началась!': {
       'ru': 'Программа началась!',
       'en': 'Program started!',
     },
     'Нет программ': {'ru': 'Нет программ', 'en': 'No programs'},
     'О нас': {'ru': 'О нас', 'en': 'About Us'},
     'about_text': {
       'ru': 'Basketball Training — это современное мобильное приложение для баскетболистов всех уровней. Мы помогаем вам улучшать свои навыки с помощью структурированных тренировочных программ, детальных инструкций по упражнениям и персонального AI-тренера.\n\n'
             '✨ Наши возможности:\n'
             '• Персональные тренировочные программы на 7, 14 и 30 дней\n'
             '• Подробное описание каждого упражнения с видео-демонстрацией\n'
             '• Отслеживание прогресса и статистики\n'
             '• Возможность добавлять упражнения в избранное\n'
             '• AI-тренер для ответов на вопросы по баскетболу и тренировкам\n'
             '• Поддержка нескольких языков\n\n'
             '🎯 Наша миссия — сделать качественные баскетбольные тренировки доступными для каждого, где бы вы ни находились. Мы верим, что систематические занятия с правильной техникой приводят к выдающимся результатам.\n\n'
             '📧 Связь: gluk.dan@gmail.com\n\n'
             '© 2025 Basketball Training Team. Все права защищены.',
       'en': 'Basketball Training is a modern mobile app for basketball players of all levels. We help you improve your skills with structured training programs, detailed exercise instructions, and a personal AI coach.\n\n'
             '✨ Features:\n'
             '• Personal training programs for 7, 14 and 30 days\n'
             '• Detailed description of each exercise with video demonstration\n'
             '• Progress and statistics tracking\n'
             '• Ability to add exercises to favorites\n'
             '• AI coach for basketball and training questions\n'
             '• Multi-language support\n\n'
             '🎯 Our mission is to make quality basketball training accessible to everyone, wherever you are. We believe that systematic training with proper technique leads to outstanding results.\n\n'
             '📧 Contact: gluk.dan@gmail.com\n\n'
             '© 2025 Basketball Training Team. All rights reserved.',
     },
     'Нажмите для просмотра тренировки': {
      'ru': 'Нажмите для просмотра тренировки',
      'en': 'Tap to view workout',
    },
    'Введите код подтверждения': {
      'ru': 'Введите код подтверждения',
      'en': 'Enter verification code',
    },
    'Код должен состоять из 8 цифр': {
      'ru': 'Код должен состоять из 8 цифр',
      'en': 'Code must be 8 digits',
    },
    'Подтвердить': {
      'ru': 'Подтвердить',
      'en': 'Confirm',
    },
    'Отправить повторно': {
      'ru': 'Отправить повторно',
      'en': 'Resend code',
    },
    'Код отправлен повторно': {
      'ru': 'Код отправлен повторно',
      'en': 'Code sent again',
    },
    'Не удалось отправить код. Попробуйте позже.': {
      'ru': 'Не удалось отправить код. Попробуйте позже.',
      'en': 'Failed to send code. Try again later.',
    },
    'Неверный код или код истек. Попробуйте снова.': {
      'ru': 'Неверный код или код истек. Попробуйте снова.',
      'en': 'Invalid or expired code. Try again.',
    },
    'Код отправлен на вашу почту': {
      'ru': 'Код отправлен на вашу почту',
      'en': 'Code sent to your email',
    },
    'Получить код': {
      'ru': 'Получить код',
      'en': 'Get code',
    },
    'Установить время': {'ru': 'Установить время', 'en': 'Set time'},
    'мин': {'ru': 'мин', 'en': 'min'},
    'сек': {'ru': 'сек', 'en': 'sec'},
    'Отмена': {'ru': 'Отмена', 'en': 'Cancel'},
    'ОК': {'ru': 'ОК', 'en': 'OK'},
  };

  static String get(String key, String language) {
    final lang = language == 'en' ? 'en' : 'ru';
    return _translations[key]?[lang] ?? key;
  }

  static String getWithParams(
    String key,
    String language,
    Map<String, String> params,
  ) {
    String text = get(key, language);
    params.forEach((paramKey, value) {
      text = text.replaceAll('{$paramKey}', value);
    });
    return text;
  }
}
