// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => 'Напиши про день!';

  @override
  String get dailyReminderDescription => 'Заполни свой дневник сегодня…';

  @override
  String get actionTakePhoto => 'Сделать фото';

  @override
  String get actionTakeVideo => 'Take video';

  @override
  String get actionRecordAudio => 'Record audio';

  @override
  String get actionAddImage => 'Add image';

  @override
  String get actionAddVideo => 'Add video';

  @override
  String get actionAddAudio => 'Add audio';

  @override
  String get actionToday => 'Сегодня';

  @override
  String get actionOtherDay => 'Другой день';

  @override
  String get pageHomeTitle => 'Дом';

  @override
  String get jumpToMonthTitle => 'Выбрать месяц';

  @override
  String get jumpToLogTitle => 'Выбрать день';

  @override
  String get flashbacksTitle => 'Воспоминания';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Не учитывать плохие дни';

  @override
  String get flaskbacksEmpty => 'Воспоминаний пока нет…';

  @override
  String get flashbackGoodDay => 'Хороший день';

  @override
  String get flashbackRandomDay => 'Случайный день';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Недель назад',
      few: '$count Недели назад',
      one: '$count Неделя назад',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Месяцев назад',
      few: '$count Месяца назад',
      one: '$count Месяц назад',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Лет назад',
      few: '$count Года назад',
      one: '$count Год назад',
    );
    return '$_temp0';
  }

  @override
  String get flashbackOnThisDay => 'В этот день';

  @override
  String get pageGalleryTitle => 'Галерея';

  @override
  String get searchLogsHint => 'Искать записи…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count записей',
      few: '$count записи',
      one: '$count запись',
    );
    return '$_temp0';
  }

  @override
  String dayCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дней',
      one: '$count день',
    );
    return '$_temp0';
  }

  @override
  String wordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count слов',
      many: '$count слов',
      few: '$count слова',
      one: '$count слово',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => 'Нет записей…';

  @override
  String get noResults => 'No Results…';

  @override
  String get sortDateTitle => 'Дата';

  @override
  String get sortOrderAscendingTitle => 'В порядке возрастания';

  @override
  String get sortOrderDescendingTitle => 'Убывание';

  @override
  String get pageStatisticsTitle => 'Статистика';

  @override
  String get statisticsNotEnoughData => 'Недостаточно данных…';

  @override
  String get statisticsRangeOneMonth => '1 Месяц';

  @override
  String get statisticsRangeSixMonths => '6 Месяцев';

  @override
  String get statisticsRangeOneYear => '1 Год';

  @override
  String get statisticsRangeAllTime => 'Все время';

  @override
  String chartSummaryTitle(Object tag) {
    return '$tag Сводка';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag По дням';
  }

  @override
  String chartOverTimeTitle(Object tag) {
    return '$tag Over Time';
  }

  @override
  String get chartGroupingLabel => 'Сгруппировать по';

  @override
  String get chartGroupingDay => 'День';

  @override
  String get chartGroupingWeek => 'Неделя';

  @override
  String get chartGroupingMonth => 'Месяц';

  @override
  String get chartGroupingYear => 'Год';

  @override
  String get chartSmoothingLabel => 'Сглаживание';

  @override
  String streakCurrent(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Дней подряд $count',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Макс. дней подряд $count',
    );
    return '$_temp0';
  }

  @override
  String streakGreatDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Great Days $count',
    );
    return '$_temp0';
  }

  @override
  String streakSinceBadDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Дни с последнего Плохого Дня $count',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle =>
      'Нет доступа к внешнему хранилищу';

  @override
  String get errorExternalStorageAccessDescription =>
      'Если вы используете сетевое хранилище, убедитесь, что оно работает и у вас есть доступ к Интернету.\n\nВ противном случае, приложение могло потерять разрешение для доступа к внешней папке. Откройте настройки и выберите внешнюю папку снова, чтобы предоставить доступ.\n\nВнимание, изменения не будут синхронизироваться, пока доступ к внешнему хранилищу не будет восстановлен!';

  @override
  String get errorExternalStorageAccessContinue =>
      'Продолжить с локальным хранением данных';

  @override
  String get databaseMigrationErrorTitle => 'Не смогли перенести ваши данные';

  @override
  String get databaseMigrationErrorDescription =>
      'Your entries are safe but couldn\'t be moved to the app\'s storage.\n\nTry again, and report the issue if it keeps happening.';

  @override
  String get databaseMigrationErrorRetry => 'Повторить';

  @override
  String get databaseNewerErrorTitle => 'Update Required';

  @override
  String get databaseNewerErrorDescription =>
      'Your data was saved by a newer version of Daily You. This version can\'t open it safely. Update the app to continue.';

  @override
  String get errorReport => 'Сообщить о проблеме';

  @override
  String get lastModified => 'Изменено';

  @override
  String get writeSomethingHint => 'Напишите что-нибудь…';

  @override
  String get titleHint => 'Название…';

  @override
  String get deleteLogTitle => 'Удалить запись';

  @override
  String get deleteLogDescription => 'Вы хотите удалить эту запись?';

  @override
  String get deletePhotoTitle => 'Удалить фото';

  @override
  String get deletePhotoDescription => 'Вы хотите удалить это фото?';

  @override
  String get deleteAttachmentTitle => 'Delete Attachment';

  @override
  String get deleteAttachmentDescription =>
      'Do you want to delete this attachment?';

  @override
  String get largeAttachmentWarningTitle => 'Large attachment';

  @override
  String get largeAttachmentWarningDescription =>
      'This attachment is large and will increase your backup size.';

  @override
  String get dontShowAgain => 'Don\'t show again';

  @override
  String get pageSettingsTitle => 'Настройки';

  @override
  String get settingsAppearanceTitle => 'Внешний вид';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get themeSystem => 'Система';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Темная';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => 'Первый день недели';

  @override
  String get settingsCalendarSystem => 'Тип календаря';

  @override
  String get calendarSystemGregorian => 'Григорианский календарь';

  @override
  String get calendarSystemJalali => 'Jalali';

  @override
  String get settingsUseSystemAccentColor =>
      'Использовать акцентный цвет как в системе';

  @override
  String get settingsCustomAccentColor => 'Пользовательский акцентный цвет';

  @override
  String get settingsShowMarkdownToolbar =>
      'Показать панель инструментов Markdown';

  @override
  String get settingsShowFlashbacks => 'Показать воспоминания';

  @override
  String get settingsChangeMoodIcons => 'Изменить значки настроения';

  @override
  String get moodIconPrompt => 'Введите значок (емодзи)';

  @override
  String get settingsFlashbacksViewLayout => 'Отображение флеш-беков';

  @override
  String get settingsGalleryViewLayout => 'Отображение галереи';

  @override
  String get settingsHideImagesInGallery => 'Скрыть изображения в галерее';

  @override
  String get settingsHideImages => 'Скрыть изображения';

  @override
  String get settingsTimelineShowFullEntries => 'Show Full Entries In Timeline';

  @override
  String get settingsTimelineShowFullEntriesHint =>
      'Show the whole text of each entry instead of a short preview';

  @override
  String get timelineNewestFirst => 'Newest first';

  @override
  String get timelineOldestFirst => 'Oldest first';

  @override
  String get timelineShowFullEntries => 'Show full entries';

  @override
  String get timelineShowPreviews => 'Show previews';

  @override
  String get timelineAddEntry => 'Add entry for this day';

  @override
  String get favouriteAdd => 'Add to favourites';

  @override
  String get favouriteRemove => 'Remove from favourites';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get greetingNight => 'Good night';

  @override
  String get settingsHomeGreeting => 'Greeting On Home';

  @override
  String get settingsHomeGreetingHint => 'Show a greeting instead of \"Home\"';

  @override
  String get settingsGreetingStyle => 'Greeting Style';

  @override
  String get greetingStyleClassic => 'Classic';

  @override
  String get greetingStylePlayful => 'Playful';

  @override
  String get settingsYourName => 'Your Name';

  @override
  String get settingsYourNameHint => 'Leave empty for no name';

  @override
  String get settingsFlashbackStyle => 'Flashback Style';

  @override
  String get flashbackStyleCards => 'Cards';

  @override
  String get flashbackStyleChips => 'Chips';

  @override
  String get flashbackStyleIcon => 'Icon (✨)';

  @override
  String bulkSelected(int count) {
    return '$count selected';
  }

  @override
  String get bulkChangeMood => 'Change mood';

  @override
  String get bulkChangeTags => 'Change tags';

  @override
  String get bulkNoMood => 'No mood';

  @override
  String get bulkNoTags => 'No tags yet';

  @override
  String bulkForEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'For $count entries',
      one: 'For 1 entry',
    );
    return '$_temp0';
  }

  @override
  String bulkTagsHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Outlined tags are on some of the $count entries. Tap to put a tag on all of them, tap again to remove it from all.',
      one: 'Tap a tag to add or remove it.',
    );
    return '$_temp0';
  }

  @override
  String bulkTagsOnSome(int count, String tags) {
    return 'On some of the $count entries: $tags. Tap one to add it to all.';
  }

  @override
  String bulkDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count entries?',
      one: 'Delete 1 entry?',
    );
    return '$_temp0';
  }

  @override
  String get bulkDeleteDescription =>
      'Their photos and other attachments are deleted too. This can\'t be undone.';

  @override
  String get bulkMoodChanged => 'Mood changed';

  @override
  String get bulkTagsUpdated => 'Tags updated';

  @override
  String get editorUndo => 'Undo';

  @override
  String get editorRedo => 'Redo';

  @override
  String get editorTimestamp => 'Timestamp';

  @override
  String get editorDateAndTime => 'Date and time';

  @override
  String get editorList => 'List';

  @override
  String get editorNumberedList => 'Numbered list';

  @override
  String get editorChecklist => 'Checklist';

  @override
  String get editorTickedCheckbox => 'Ticked checkbox';

  @override
  String get editorHeading => 'Heading';

  @override
  String get editorHeading1 => 'Heading 1';

  @override
  String get editorBold => 'Bold';

  @override
  String get editorItalic => 'Italic';

  @override
  String get editorHighlight => 'Highlight';

  @override
  String get editorStrikethrough => 'Strikethrough';

  @override
  String get editorQuote => 'Quote';

  @override
  String get editorDivider => 'Divider line';

  @override
  String get editorLink => 'Link';

  @override
  String get editorPasteLink => 'Paste copied link';

  @override
  String get restoreSettingsTitle => 'Restore settings too?';

  @override
  String get restoreSettingsBody =>
      'This backup also has your settings: theme, editor buttons, mood icons and more. Passwords, app lock and backup or sync folders aren\'t included.';

  @override
  String get restoreSettingsYes => 'Restore settings';

  @override
  String get restoreSettingsLogsOnly => 'Logs only';

  @override
  String get editorTime => 'Time';

  @override
  String get editorBulletList => 'Bullet list';

  @override
  String get editorHeading2 => 'Heading 2';

  @override
  String get editorHeadingMenu => 'Pick a heading (H1–H6)';

  @override
  String get editorAddLink => 'Add link';

  @override
  String get editorNothing => 'Nothing';

  @override
  String editorButtonsTapHold(String tap, String hold) {
    return 'tap: $tap · hold: $hold';
  }

  @override
  String get editorButtonsActionsHint =>
      'Tap a button to choose what a tap and a long-press do.';

  @override
  String get editorButtonTap => 'Tap';

  @override
  String get editorButtonHold => 'Long-press';

  @override
  String get editorButtonDefaults => 'Use defaults';

  @override
  String get editorCustomButtonPickIcon => 'Pick an icon';

  @override
  String get editorCustomButtonIcon => 'Icon';

  @override
  String get settingsEditorButtons => 'Editor Buttons';

  @override
  String get settingsEditorButtonsHint =>
      'Arrange the toolbar and the popup that appears when you select text';

  @override
  String get editorButtonsToolbar => 'Toolbar';

  @override
  String get editorButtonsToolbarHint =>
      'Drag to reorder. Tap the eye to hide a button. Buttons that don\'t fit go under •••.';

  @override
  String get editorButtonsPopup => 'Selection popup';

  @override
  String get editorButtonsPopupHint =>
      'Shown before Copy and Paste when you select text. Drag to reorder.';

  @override
  String editorButtonsHold(String action) {
    return 'hold: $action';
  }

  @override
  String get editorButtonsReset => 'Reset to default';

  @override
  String get editorButtonsCustomHint =>
      'Your own buttons insert text or Markdown with one tap. Tap one to edit it.';

  @override
  String get editorCustomButtonAdd => 'Add custom button';

  @override
  String get editorCustomButtonEdit => 'Edit button';

  @override
  String get editorCustomButtonName => 'Name';

  @override
  String get editorCustomButtonNameHint => 'e.g. Gratitude';

  @override
  String get editorCustomButtonSymbol => 'Button shows';

  @override
  String get editorCustomButtonSymbolHint => 'An emoji or 1–2 letters, e.g. 🙏';

  @override
  String get editorCustomButtonText => 'Inserts';

  @override
  String get editorCustomButtonTextHint =>
      'Text or Markdown, e.g. ## Grateful for';

  @override
  String get editorCustomButtonDelete => 'Delete button';

  @override
  String get editorCustomButtonUnnamed => 'Custom button';

  @override
  String get settingsWritingPrompts => 'Writing Prompts';

  @override
  String get settingsWritingPromptsHint =>
      'Show a gentle question in empty new entries';

  @override
  String bulkDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries deleted',
      one: '1 entry deleted',
    );
    return '$_temp0';
  }

  @override
  String get pageCalendarTitle => 'Календарь';

  @override
  String get viewLayoutList => 'Список';

  @override
  String get viewLayoutGrid => 'Сетка';

  @override
  String get settingsNotificationsTitle => 'Уведомления';

  @override
  String get settingsDailyReminderOnboarding =>
      'Включи ежедневные напоминания, чтобы оставаться последовательным!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'Будет запрошено разрешение «Планирование будильников» для отправки напоминания в случайный момент или в выбранное время.';

  @override
  String get settingsDailyReminderTitle => 'Ежедневное напоминание';

  @override
  String get settingsOnThisDayDescription =>
      'Вернитесь к прошлым воспоминаниям';

  @override
  String get settingsDailyReminderDescription =>
      'Удобное пуш-уведомление на каждый день';

  @override
  String get settingsReminderTime => 'Время напоминания';

  @override
  String get settingsFixedReminderTimeTitle =>
      'Фиксированное время напоминания';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Выберите фиксированное время напоминания';

  @override
  String get settingsAlwaysSendReminderTitle => 'Всегда напоминать';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Напоминать, даже если запись уже начата';

  @override
  String get settingsCustomizeNotificationTitle => 'Настроить уведомления';

  @override
  String get settingsTemplatesTitle => 'Шаблоны';

  @override
  String get settingsDefaultTemplate => 'Шаблон по умолчанию';

  @override
  String get manageTemplates => 'Управление шаблонами';

  @override
  String get addTemplate => 'Добавить шаблон';

  @override
  String get newTemplate => 'Новый шаблон';

  @override
  String get noTemplateTitle => 'Нет';

  @override
  String get noTemplatesDescription => 'Нет созданных шаблонов…';

  @override
  String get templateVariableTime => 'Время';

  @override
  String get templateDefaultTimestampTitle => 'Временная метка';

  @override
  String templateDefaultTimestampBody(Object date, Object time) {
    return '$date - $time:';
  }

  @override
  String get templateDefaultSummaryTitle => 'Итог дня';

  @override
  String get templateDefaultSummaryBody => '### Итог\n- \n\n### Цитата\n> ';

  @override
  String get templateDefaultReflectionTitle => 'Рефлексия';

  @override
  String get templateDefaultReflectionBody =>
      '### What did you enjoy about today?\n- \n\n### What are you thankful for?\n- \n\n### What are you looking forward to?\n- ';

  @override
  String get settingsTagsTitle => 'Теги';

  @override
  String get manageTags => 'Управлять тегами';

  @override
  String get tagTypeLabelTitle => 'Label';

  @override
  String get tagTypeTrackerTitle => 'Tracker';

  @override
  String get nameHint => 'Name';

  @override
  String get tagColorLabel => 'Color';

  @override
  String get iconPickerTitle => 'Choose Icon';

  @override
  String get iconPickerIconsTab => 'Icons';

  @override
  String get iconPickerCustomTab => 'Custom';

  @override
  String get iconPickerSearchHint => 'Search icons…';

  @override
  String get colorPickerTitle => 'Choose Color';

  @override
  String get colorPickerPaletteTab => 'Colors';

  @override
  String get iconGroupMoodPeople => 'Mood & People';

  @override
  String get iconGroupHealth => 'Health';

  @override
  String get iconGroupWorkFinance => 'Work & Finance';

  @override
  String get iconGroupHabitsGoals => 'Habits & Goals';

  @override
  String get iconGroupNature => 'Nature';

  @override
  String get iconGroupFoodDrink => 'Food & Drink';

  @override
  String get iconGroupHome => 'Home';

  @override
  String get iconGroupTravel => 'Travel';

  @override
  String get iconGroupSymbols => 'Symbols';

  @override
  String get tagCategoryLabel => 'Category';

  @override
  String get tagLabel => 'Tag';

  @override
  String get tagCategoryUncategorized => 'Uncategorized';

  @override
  String get newCategoryTitle => 'New Category';

  @override
  String get shareButtonLabel => 'Share';

  @override
  String get importErrorDescription => 'Failed to import file!';

  @override
  String get exportErrorDescription => 'Failed to export file!';

  @override
  String get deleteTitle => 'Delete';

  @override
  String deleteTagMessage(num count, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' It is used in $count logs.',
      one: ' It is used in 1 log.',
      zero: '',
    );
    return 'Delete \"$name\"?$_temp0';
  }

  @override
  String deleteCategoryMessage(num count, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' Its $count tags will also be deleted.',
      one: ' Its 1 tag will also be deleted.',
      zero: '',
    );
    return 'Delete \"$name\"?$_temp0';
  }

  @override
  String deleteTemplateMessage(Object name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get filterTagsTitle => 'Filter';

  @override
  String get tagFilterModeAny => 'Any Tag';

  @override
  String get tagFilterModeAll => 'All Tags';

  @override
  String get clearAllFilters => 'Clear All';

  @override
  String get noTagsFilterLabel => 'No Tags';

  @override
  String get addTagsTitle => 'Add Tags';

  @override
  String get addTagsSearchHint => 'Search tags…';

  @override
  String get tagPickerSortManualLabel => 'Manual order';

  @override
  String get tagPickerSortUsageLabel => 'Sort by usage';

  @override
  String get tagPickerFrequent => 'Frequent';

  @override
  String get tagPickerFrequentWindow => 'Last 60 days';

  @override
  String tagsSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get tagsMoveToCategory => 'Move to category';

  @override
  String tagsMovedToCategory(int count, String category) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tags',
      one: '1 tag',
    );
    return 'Moved $_temp0 to $category';
  }

  @override
  String get favouriteTagLockedNote =>
      'Set with the star button. Only the colour can be changed.';

  @override
  String get tagFavoriteName => 'Favorite';

  @override
  String get tagEnergyName => 'Energy';

  @override
  String get tagCategoryActivitiesName => 'Activities';

  @override
  String get tagExerciseName => 'Exercise';

  @override
  String get tagSocializingName => 'Socializing';

  @override
  String get tagHobbyName => 'Hobby';

  @override
  String get tagEntertainmentName => 'Entertainment';

  @override
  String get tagDiningName => 'Dining';

  @override
  String get tagChoresName => 'Chores';

  @override
  String get tagCategoryEmotionsName => 'Emotions';

  @override
  String get tagExcitedName => 'Excited';

  @override
  String get tagGratefulName => 'Grateful';

  @override
  String get tagCalmName => 'Calm';

  @override
  String get tagTiredName => 'Tired';

  @override
  String get tagAnxiousName => 'Anxious';

  @override
  String get tagAnnoyedName => 'Annoyed';

  @override
  String get welcomeLogBodyText =>
      '## Welcome to Daily You\n\n> Every day is worth remembering, capture it!\n\n**Daily You** is free, [open source](https://github.com/Demizo/Daily_You), and community supported. Built around the belief that your diary should be yours, not a product:\n\n- No ads\n- No locked features\n- No tracking or data collection\n\nWhether you\'re journaling, reflecting, or just noting what made you smile, **Daily You** gives you a private space that\'s _truly your own_.';

  @override
  String get settingsStorageTitle => 'Хранилище';

  @override
  String get settingsImageQuality => 'Качество изображения';

  @override
  String get settingsMediaQualityTitle => 'Media Quality';

  @override
  String get imageQualityHigh => 'Высокое';

  @override
  String get imageQualityMedium => 'Среднее';

  @override
  String get imageQualityLow => 'Низкое';

  @override
  String get imageQualityNoCompression => 'Без сжатия';

  @override
  String get settingsStorageUsage => 'Storage Usage';

  @override
  String get settingsLogFolder => 'Папка для записей';

  @override
  String get settingsImageFolder => 'Папка для картинок';

  @override
  String get settingsExternalSyncTitle => 'Sync with External Location';

  @override
  String get chooseFolderHint => 'Choose a folder';

  @override
  String get warningTitle => 'Внимание';

  @override
  String get logFolderWarningDescription =>
      'Если выбранная папка уже содержит файл \'daily_you.db\', существующие записи будут перезаписаны!';

  @override
  String get errorTitle => 'Ошибка';

  @override
  String get logFolderErrorDescription =>
      'Не удалось поменять папку для записей!';

  @override
  String get imageFolderErrorDescription =>
      'Не удалось поменять папку для картинок!';

  @override
  String get syncErrorDescription =>
      'Failed to sync with the external location!';

  @override
  String get backupErrorDescription => 'Не удалось создать резервную копию!';

  @override
  String get restoreErrorDescription =>
      'Не удалось восстановить резервную копию!';

  @override
  String get settingsBackupRestoreTitle => 'Резервная копия и востановление';

  @override
  String get settingsBackup => 'Резервная копия';

  @override
  String get settingsRestore => 'Восстановить';

  @override
  String get settingsRestorePromptDescription =>
      'Откат к резервной копии перезапишет существующие данные!';

  @override
  String get settingsBackupPasswordProtect => 'Password Protect Backups';

  @override
  String get backupEncryptedTitle => 'Encrypted Backup';

  @override
  String get backupEncryptedContent => 'This backup is password protected.';

  @override
  String get settingsAutoBackup => 'Automatic Backups';

  @override
  String get settingsAutoBackupLocation => 'Backup Location';

  @override
  String get settingsAutoBackupInterval => 'Backup Interval';

  @override
  String get settingsAutoBackupIntervalDaily => 'Daily';

  @override
  String get settingsAutoBackupIntervalWeekly => 'Weekly';

  @override
  String get settingsAutoBackupIntervalMonthly => 'Monthly';

  @override
  String get settingsAutoBackupMaxCount => 'Backups To Keep';

  @override
  String get settingsAutoBackupRequireCharging => 'Only While Charging';

  @override
  String settingsBackupLast(Object time) {
    return 'Last backup $time';
  }

  @override
  String get settingsBackupNever => 'Never backed up';

  @override
  String settingsAutoBackupNext(Object time) {
    return 'Next backup $time';
  }

  @override
  String get settingsAutoBackupKeepAll => 'All';

  @override
  String get autoBackupFailedTitle => 'Backup Failed';

  @override
  String tranferStatus(Object percent) {
    return 'Перемещение... $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'Создание резервной копии...$percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'Откат из резервной копии... $percent%';
  }

  @override
  String encryptingBackupStatus(Object percent) {
    return 'Encrypting Backup… $percent%';
  }

  @override
  String decryptingBackupStatus(Object percent) {
    return 'Decrypting Backup… $percent%';
  }

  @override
  String get cleanUpStatus => 'Прибираемся…';

  @override
  String migratingImagesStatus(Object current, Object total) {
    return 'Migrating photos… $current/$total';
  }

  @override
  String get settingsExport => 'Экспорт';

  @override
  String get settingsExportToAnotherFormat => 'Сохранить в другом формате';

  @override
  String get settingsExportFormatDescription =>
      'Не используйте это как резервную копию!';

  @override
  String get exportLogs => 'Экспорт записей';

  @override
  String get exportImages => 'Экспорт изображений';

  @override
  String get exportIncludeTitle => 'Include';

  @override
  String get settingsImport => 'Импорт';

  @override
  String get settingsImportFromAnotherApp => 'Импорт из другого приложения';

  @override
  String get settingsTranslateCallToAction => 'Каждому нужен журнал!';

  @override
  String get settingsHelpTranslate => 'Помогите с переводом';

  @override
  String get importLogs => 'Импорт записей';

  @override
  String get importImages => 'Импорт изображений';

  @override
  String get logFormatTitle => 'Выбрать формат';

  @override
  String get logFormatDescription =>
      'Формат другого приложения может не поддерживать все функции. Пожалуйста, сообщайте о любых проблемах, так как сторонние форматы могут изменяться в любое время. Это не повлияет на существующие записи!';

  @override
  String get formatDailyYouJson => 'Daily You (JSON)';

  @override
  String get formatDaybook => 'Daybook';

  @override
  String get formatDaylio => 'Daylio';

  @override
  String get formatDiarium => 'Diarium';

  @override
  String get formatDiaro => 'Diaro';

  @override
  String get formatMyBrain => 'My Brain';

  @override
  String get formatOneShot => 'OneShot';

  @override
  String get formatPixels => 'Pixels';

  @override
  String get formatMarkdown => 'Markdown';

  @override
  String get settingsDeleteAllLogsTitle => 'Удалить все записи';

  @override
  String get settingsDeleteAllLogsDescription =>
      'Вы уверены, что хотите удалить все свои записи?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Введите \'$prompt\', чтобы подтвердить. Это действие безвозвратно!';
  }

  @override
  String get settingsLanguageTitle => 'Язык';

  @override
  String get settingsAppLanguageTitle => 'Язык приложения';

  @override
  String get settingsOverrideAppLanguageTitle => 'Заменить язык приложения';

  @override
  String get settingsSecurityTitle => 'Безопасность';

  @override
  String get settingsSecurityRequirePassword => 'Требовать пароль';

  @override
  String get settingsSecurityEnterPassword => 'Введите пароль';

  @override
  String get settingsSecuritySetPassword => 'Установить пароль';

  @override
  String get settingsSecurityChangePassword => 'Сменить пароль';

  @override
  String get settingsSecurityPassword => 'Пароль';

  @override
  String get settingsSecurityConfirmPassword => 'Подтверждение пароля';

  @override
  String get settingsSecurityOldPassword => 'Старый пароль';

  @override
  String get settingsSecurityIncorrectPassword => 'Неверный пароль';

  @override
  String get settingsSecurityPasswordsDoNotMatch => 'Пароли не совпадают';

  @override
  String get requiredPrompt => 'При входе требуется пароль';

  @override
  String get settingsSecurityBiometricUnlock => 'Отпечаток пальца';

  @override
  String get unlockAppPrompt => 'Разблокировка дневника';

  @override
  String get settingsAboutTitle => 'О программе';

  @override
  String get settingsVersion => 'Версия';

  @override
  String get settingsLicense => 'Лицензия';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'Исходный код';

  @override
  String get settingsOpenSourceLicenses => 'Open Source Licenses';

  @override
  String get settingsMadeWithLove => 'Сделано с ❤️';

  @override
  String get settingsConsiderSupporting => 'подумайте о поддержке проекта';

  @override
  String get imagesTitle => 'Изображения';

  @override
  String get audioTitle => 'Audio';

  @override
  String get videoTitle => 'Video';

  @override
  String get tagMoodTitle => 'Настроение';

  @override
  String get calendarTagDisplayLabel => 'Tag';

  @override
  String get selectTagTitle => 'Select Tag';

  @override
  String get labelPresentLabel => 'Present';

  @override
  String get labelAbsentLabel => 'Absent';

  @override
  String get labelCoverageLabel => 'Coverage';

  @override
  String chartDistributionTitle(Object tag) {
    return '$tag Distribution';
  }

  @override
  String get shareAddToLogPickerTitle => 'Choose a log';

  @override
  String get attachmentAddErrorDescription => 'Failed to add attachment!';

  @override
  String get attachmentLoadFailed => 'Could not open this attachment';

  @override
  String get attachmentNoAppToOpen => 'No app can open this attachment';

  @override
  String get recorderDiscardTitle => 'Discard recording?';

  @override
  String get recorderDiscardDescription => 'This recording will be deleted.';

  @override
  String get recorderDiscardAction => 'Discard';

  @override
  String get recorderPermissionDenied =>
      'Microphone permission is required to record audio';

  @override
  String get recorderErrorDescription => 'Failed to record audio!';

  @override
  String searchMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '1 match',
    );
    return '$_temp0';
  }

  @override
  String searchMatchPosition(int current, int total) {
    return '$current of $total';
  }

  @override
  String get searchPreviousMatch => 'Previous match';

  @override
  String get searchNextMatch => 'Next match';

  @override
  String get searchClearHighlights => 'Clear highlights';

  @override
  String get galleryJumpToMonth => 'Jump to month';

  @override
  String galleryMonthEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
      zero: 'No entries',
    );
    return '$_temp0';
  }

  @override
  String galleryUpcoming(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Upcoming · $count entries',
      one: 'Upcoming · 1 entry',
    );
    return '$_temp0';
  }

  @override
  String get upcomingTitle => 'Upcoming';

  @override
  String get settingsFutureEntries => 'Allow future entries';

  @override
  String get settingsFutureEntriesHint =>
      'Write entries for days ahead, up to 12 months. They stay out of stats and flashbacks until their day.';

  @override
  String get linkCopied => 'Link to entry copied';

  @override
  String get linkEntryMissing => 'That entry no longer exists';

  @override
  String get linkCannotOpen => 'Couldn\'t open this link';

  @override
  String get linkAddTitle => 'Add link';

  @override
  String get linkKindEntry => 'Entry';

  @override
  String get linkKindWebsite => 'Website';

  @override
  String get linkTextToShow => 'Text to show';

  @override
  String get linkChooseEntry => 'Choose an entry';

  @override
  String get linkClear => 'Clear';

  @override
  String get linkWebAddress => 'Web address';

  @override
  String get linkAdd => 'Add';

  @override
  String get linkAnyDate => 'Any date';

  @override
  String get linkCopyToEntry => 'Copy link to entry';

  @override
  String get shareEntry => 'Share';

  @override
  String get editorPlace => 'Place';

  @override
  String get placeAddTitle => 'Add a place';

  @override
  String get placeTypeHint => 'Type a place';

  @override
  String get placePasteCopied => 'Paste copied place';

  @override
  String get placeFindInMaps => 'Find in Google Maps';

  @override
  String get placeFindInMapsHint => 'Pick a place, tap Share, then Daily You';

  @override
  String get placeSaved => 'Saved places';

  @override
  String get placeSavedEmpty =>
      'Add the places you go often, like Home or Work, to put them in an entry with one tap.';

  @override
  String get placeManageSaved => 'Manage saved places';

  @override
  String get placeNewSaved => 'New place';

  @override
  String get placeName => 'Name';

  @override
  String get placeMapLink => 'Map link (optional)';

  @override
  String get placeMapLinkHint =>
      'In Google Maps, tap Share on the place, then Copy, and paste it here.';

  @override
  String get placeHasMapSpot => 'Opens in Maps';

  @override
  String get placeNoMapSpot => 'Searches its name in Maps';

  @override
  String get settingsLocations => 'Locations';

  @override
  String get settingsShowLocationButtons => 'Show location buttons';

  @override
  String get settingsShowLocationButtonsHint =>
      'In the entry view and the Timeline. Tap one to open it in Maps.';

  @override
  String get locationRemove => 'Remove location';

  @override
  String locationOpenInMaps(String place) {
    return '$place, open in Maps';
  }

  @override
  String get locationNameTitle => 'Name this place';

  @override
  String get locationNameHint => 'e.g. Jollibee Taipei';

  @override
  String get swipeAgainToExit => 'Swipe again to exit';

  @override
  String get galleryShowList => 'Show as list';

  @override
  String get galleryShowGrid => 'Show as grid';

  @override
  String get unlockWelcome => 'Welcome';

  @override
  String get forgotPasswordButton => 'Forgot password?';

  @override
  String get forgotPasswordTitle => 'Reset your password';

  @override
  String get forgotPasswordUseFingerprint => 'Use fingerprint';

  @override
  String get forgotPasswordUseCode => 'Use recovery code';

  @override
  String get forgotPasswordNoWay =>
      'Fingerprint unlock is off and there\'s no recovery code, so the password can\'t be reset here.';

  @override
  String get forgotPasswordNewPassword => 'Set a new password';

  @override
  String get recoveryCodeLabel => 'Recovery code';

  @override
  String get recoveryCodeWrong => 'That code doesn\'t match';

  @override
  String get recoveryCodeTitle => 'Your recovery code';

  @override
  String get recoveryCodeExplain =>
      'If you forget your password, this code lets you set a new one. It works once, and won\'t be shown again. Keep it somewhere safe away from this phone, like a password manager or on paper.';

  @override
  String get recoveryCodeCopy => 'Copy';

  @override
  String get recoveryCodeCopied => 'Code copied';

  @override
  String get recoveryCodeSaved => 'I\'ve saved it';

  @override
  String get recoveryCodeSetting => 'Recovery code';

  @override
  String get recoveryCodeSettingHasCode =>
      'You have a code. Making a new one cancels the old one.';

  @override
  String get recoveryCodeSettingNoCode =>
      'Make a one-time code to reset a forgotten password';

  @override
  String get settingsJustifyText => 'Justify text';

  @override
  String get settingsJustifyTextHint =>
      'When reading, lines fill the width like a book, with long words split by a hyphen. Off keeps text left-aligned.';
}
