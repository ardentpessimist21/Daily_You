// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => 'Registe hoje!';

  @override
  String get dailyReminderDescription => 'Faça o seu registo diário…';

  @override
  String get actionTakePhoto => 'Tire uma foto';

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
  String get actionToday => 'Hoje';

  @override
  String get actionOtherDay => 'Outro dia';

  @override
  String get pageHomeTitle => 'Início';

  @override
  String get jumpToMonthTitle => 'Jump to month';

  @override
  String get jumpToLogTitle => 'Jump to log';

  @override
  String get flashbacksTitle => 'Recordações';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Excluir dias maus';

  @override
  String get flaskbacksEmpty => 'Ainda sem recordações…';

  @override
  String get flashbackGoodDay => 'Um Bom Dia';

  @override
  String get flashbackRandomDay => 'Um Dia Aleatório';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Semanas Atrás',
      one: '$count Semana Atrás',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Meses Atrás',
      one: '$count Mês Atrás',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Anos Atrás',
      one: '$count Ano Atrás',
    );
    return '$_temp0';
  }

  @override
  String get flashbackOnThisDay => 'On This Day';

  @override
  String get pageGalleryTitle => 'Galeria';

  @override
  String get searchLogsHint => 'Procurar registos…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registos',
      one: '$count registo',
    );
    return '$_temp0';
  }

  @override
  String dayCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String wordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '$count word',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => 'Sem Registos…';

  @override
  String get noResults => 'No Results…';

  @override
  String get sortDateTitle => 'Data';

  @override
  String get sortOrderAscendingTitle => 'Ascendente';

  @override
  String get sortOrderDescendingTitle => 'Descendente';

  @override
  String get pageStatisticsTitle => 'Estatísticas';

  @override
  String get statisticsNotEnoughData => 'Sem dados suficientes…';

  @override
  String get statisticsRangeOneMonth => '1 Mês';

  @override
  String get statisticsRangeSixMonths => '6 Meses';

  @override
  String get statisticsRangeOneYear => '1 Ano';

  @override
  String get statisticsRangeAllTime => 'Todo o histórico';

  @override
  String chartSummaryTitle(Object tag) {
    return 'Resumo de $tag';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag Por Dia';
  }

  @override
  String chartOverTimeTitle(Object tag) {
    return '$tag Over Time';
  }

  @override
  String get chartGroupingLabel => 'Group by';

  @override
  String get chartGroupingDay => 'Day';

  @override
  String get chartGroupingWeek => 'Week';

  @override
  String get chartGroupingMonth => 'Month';

  @override
  String get chartGroupingYear => 'Year';

  @override
  String get chartSmoothingLabel => 'Smoothing';

  @override
  String streakCurrent(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sequência Atual $count',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sequência Mais Longa $count',
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
      other: 'Dias Desde um Dia Ruim $count',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle =>
      'Não é possível aceder armazenamento externo';

  @override
  String get errorExternalStorageAccessDescription =>
      'Se usar o armazenamento em rede, certifique-se que o serviço está online e que tenha acesso à rede.\n\nCaso contrário, a app pode ter perdido permissões para a pasta externa. Vá em configurações e selecione novamente a pasta externa para permitir o acesso.\n\nAtenção: as modificações não serão sincronizadas até restaurar o acesso ao local do armazenamento externo!';

  @override
  String get errorExternalStorageAccessContinue =>
      'Continuar com a base de dados local';

  @override
  String get databaseMigrationErrorTitle => 'Couldn\'t Move Your Data';

  @override
  String get databaseMigrationErrorDescription =>
      'Your entries are safe but couldn\'t be moved to the app\'s storage.\n\nTry again, and report the issue if it keeps happening.';

  @override
  String get databaseMigrationErrorRetry => 'Retry';

  @override
  String get databaseNewerErrorTitle => 'Update Required';

  @override
  String get databaseNewerErrorDescription =>
      'Your data was saved by a newer version of Daily You. This version can\'t open it safely. Update the app to continue.';

  @override
  String get errorReport => 'Report Issue';

  @override
  String get lastModified => 'Modificado';

  @override
  String get writeSomethingHint => 'Escreva alguma coisa…';

  @override
  String get titleHint => 'Título…';

  @override
  String get deleteLogTitle => 'Apagar Registo';

  @override
  String get deleteLogDescription => 'Quer apagar este registo?';

  @override
  String get deletePhotoTitle => 'Remover Foto';

  @override
  String get deletePhotoDescription => 'Quer apagar esta foto?';

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
  String get pageSettingsTitle => 'Configurações';

  @override
  String get settingsAppearanceTitle => 'Aparência';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => 'Primeiro Dia da Semana';

  @override
  String get settingsCalendarSystem => 'Calendar System';

  @override
  String get calendarSystemGregorian => 'Gregorian';

  @override
  String get calendarSystemJalali => 'Jalali';

  @override
  String get settingsUseSystemAccentColor => 'Usar Cores do Sistema';

  @override
  String get settingsCustomAccentColor => 'Cor Personalizada';

  @override
  String get settingsShowMarkdownToolbar =>
      'Mostrar Barra de Ferramentas Markdown';

  @override
  String get settingsShowFlashbacks => 'Mostrar recordações';

  @override
  String get settingsChangeMoodIcons => 'Alterar Ícones de Humor';

  @override
  String get moodIconPrompt => 'Insira um ícone';

  @override
  String get settingsFlashbacksViewLayout => 'Flashbacks View Layout';

  @override
  String get settingsGalleryViewLayout => 'Gallery View Layout';

  @override
  String get settingsHideImagesInGallery => 'Hide Images In Gallery';

  @override
  String get settingsHideImages => 'Hide Images';

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
  String get pageCalendarTitle => 'Calendar';

  @override
  String get viewLayoutList => 'List';

  @override
  String get viewLayoutGrid => 'Grid';

  @override
  String get settingsNotificationsTitle => 'Notificações';

  @override
  String get settingsDailyReminderOnboarding =>
      'Ativar lembretes diários para deixá-lo consistente!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'A permissão \"Agendar Alarmes\" será solicitada para mandar lembretes a um momento aleatório ou ao seu tempo preferido.';

  @override
  String get settingsDailyReminderTitle => 'Lembrete Diário';

  @override
  String get settingsOnThisDayDescription => 'Revisit past memories';

  @override
  String get settingsDailyReminderDescription => 'Um lembrete suave cada dia';

  @override
  String get settingsReminderTime => 'Hora do Lembrete';

  @override
  String get settingsFixedReminderTimeTitle => 'Hora do Lembrete Fixa';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Escolha uma hora fixa para o lembrete';

  @override
  String get settingsAlwaysSendReminderTitle => 'Sempre mandar um lembrete';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Mandar um lembrete mesmo se um registo já foi começado';

  @override
  String get settingsCustomizeNotificationTitle => 'Customizar Notificações';

  @override
  String get settingsTemplatesTitle => 'Modelos';

  @override
  String get settingsDefaultTemplate => 'Modelo Padrão';

  @override
  String get manageTemplates => 'Gerir Modelos';

  @override
  String get addTemplate => 'Adicionar Modelo';

  @override
  String get newTemplate => 'Novo Modelo';

  @override
  String get noTemplateTitle => 'Nenhum';

  @override
  String get noTemplatesDescription => 'Nenhum modelo criado ainda…';

  @override
  String get templateVariableTime => 'Time';

  @override
  String get templateDefaultTimestampTitle => 'Timestamp';

  @override
  String templateDefaultTimestampBody(Object date, Object time) {
    return '$date - $time:';
  }

  @override
  String get templateDefaultSummaryTitle => 'Day Summary';

  @override
  String get templateDefaultSummaryBody => '### Summary\n- \n\n### Quote\n> ';

  @override
  String get templateDefaultReflectionTitle => 'Reflection';

  @override
  String get templateDefaultReflectionBody =>
      '### What did you enjoy about today?\n- \n\n### What are you thankful for?\n- \n\n### What are you looking forward to?\n- ';

  @override
  String get settingsTagsTitle => 'Tags';

  @override
  String get manageTags => 'Manage Tags';

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
  String get settingsStorageTitle => 'Armazenamento';

  @override
  String get settingsImageQuality => 'Qualidade da Imagem';

  @override
  String get settingsMediaQualityTitle => 'Media Quality';

  @override
  String get imageQualityHigh => 'Alta';

  @override
  String get imageQualityMedium => 'Média';

  @override
  String get imageQualityLow => 'Baixa';

  @override
  String get imageQualityNoCompression => 'Sem Compressão';

  @override
  String get settingsStorageUsage => 'Storage Usage';

  @override
  String get settingsLogFolder => 'Pasta de Registos';

  @override
  String get settingsImageFolder => 'Pasta de Imagens';

  @override
  String get settingsExternalSyncTitle => 'Sync with External Location';

  @override
  String get chooseFolderHint => 'Choose a folder';

  @override
  String get warningTitle => 'Aviso';

  @override
  String get logFolderWarningDescription =>
      'Se a pasta selecionada já contiver um ficheiro \'daily_you.db\', ele será usado para substituir os seus registos existentes!';

  @override
  String get errorTitle => 'Erro';

  @override
  String get logFolderErrorDescription =>
      'Não foi possível alterar a pasta de registos!';

  @override
  String get imageFolderErrorDescription =>
      'Não foi possível alterar a pasta de imagens!';

  @override
  String get syncErrorDescription =>
      'Failed to sync with the external location!';

  @override
  String get backupErrorDescription => 'Não foi possível criar backup!';

  @override
  String get restoreErrorDescription => 'Não foi possível restaurar backup!';

  @override
  String get settingsBackupRestoreTitle => 'Backup e Restaurar';

  @override
  String get settingsBackup => 'Backup';

  @override
  String get settingsRestore => 'Restaurar';

  @override
  String get settingsRestorePromptDescription =>
      'Restaurar um backup irá sobrescrever os seus dados atuais!';

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
    return 'A transferir… $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'A criar um backup… $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'A restaurar o backup… $percent%';
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
  String get cleanUpStatus => 'A limpar…';

  @override
  String migratingImagesStatus(Object current, Object total) {
    return 'Migrating photos… $current/$total';
  }

  @override
  String get settingsExport => 'Export';

  @override
  String get settingsExportToAnotherFormat => 'Exportar para outro formato';

  @override
  String get settingsExportFormatDescription =>
      'Isto não deve ser usado como backup!';

  @override
  String get exportLogs => 'Export Logs';

  @override
  String get exportImages => 'Export Images';

  @override
  String get exportIncludeTitle => 'Include';

  @override
  String get settingsImport => 'Import';

  @override
  String get settingsImportFromAnotherApp => 'Importar de outra app';

  @override
  String get settingsTranslateCallToAction =>
      'Todos devem ter acesso a um diário!';

  @override
  String get settingsHelpTranslate => 'Ajude a Traduzir';

  @override
  String get importLogs => 'Import Logs';

  @override
  String get importImages => 'Import Images';

  @override
  String get logFormatTitle => 'Escolher Formato';

  @override
  String get logFormatDescription =>
      'O formato de outra app pode não suportar todas as funcionalidades. Por favor, informe quaisquer problemas, pois os formatos de terceiros podem mudar a qualquer momento. Isto não irá impactar os registos existentes!';

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
  String get settingsDeleteAllLogsTitle => 'Apagar Todos os Registos';

  @override
  String get settingsDeleteAllLogsDescription =>
      'Quer apagar todos os seus registos?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Digite \'$prompt\' para confirmar. Isto não pode ser desfeito!';
  }

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsAppLanguageTitle => 'Idioma da app';

  @override
  String get settingsOverrideAppLanguageTitle => 'Substituir língua da app';

  @override
  String get settingsSecurityTitle => 'Segurança';

  @override
  String get settingsSecurityRequirePassword => 'Pedir Password';

  @override
  String get settingsSecurityEnterPassword => 'Introduza Password';

  @override
  String get settingsSecuritySetPassword => 'Definir Password';

  @override
  String get settingsSecurityChangePassword => 'Alterar Password';

  @override
  String get settingsSecurityPassword => 'Password';

  @override
  String get settingsSecurityConfirmPassword => 'Confirmar Password';

  @override
  String get settingsSecurityOldPassword => 'Antiga Password';

  @override
  String get settingsSecurityIncorrectPassword => 'Password Incorreta';

  @override
  String get settingsSecurityPasswordsDoNotMatch =>
      'As passwords não são iguais';

  @override
  String get requiredPrompt => 'Requirido';

  @override
  String get settingsSecurityBiometricUnlock => 'Desbloqueio por Biometria';

  @override
  String get unlockAppPrompt => 'Desbloquear a aplicação';

  @override
  String get settingsAboutTitle => 'Sobre';

  @override
  String get settingsVersion => 'Versão';

  @override
  String get settingsLicense => 'Licença';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'Código-fonte';

  @override
  String get settingsOpenSourceLicenses => 'Open Source Licenses';

  @override
  String get settingsMadeWithLove => 'Feito com ❤️';

  @override
  String get settingsConsiderSupporting => 'Considere Apoiar';

  @override
  String get imagesTitle => 'Images';

  @override
  String get audioTitle => 'Audio';

  @override
  String get videoTitle => 'Video';

  @override
  String get tagMoodTitle => 'Humor';

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

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get dailyReminderTitle => 'Registre hoje!';

  @override
  String get dailyReminderDescription => 'Faça o seu registro diário…';

  @override
  String get actionTakePhoto => 'Tirar uma foto';

  @override
  String get actionToday => 'Hoje';

  @override
  String get actionOtherDay => 'Outro dia';

  @override
  String get pageHomeTitle => 'Início';

  @override
  String get jumpToMonthTitle => 'Pular para o mês';

  @override
  String get jumpToLogTitle => 'Ir para registro';

  @override
  String get flashbacksTitle => 'Recordações';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Excluir dias ruins';

  @override
  String get flaskbacksEmpty => 'Ainda sem recordações…';

  @override
  String get flashbackGoodDay => 'Um Bom Dia';

  @override
  String get flashbackRandomDay => 'Um Dia Aleatório';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Semanas Atrás',
      one: '$count Semana Atrás',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Meses Atrás',
      one: '$count Mês Atrás',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Anos Atrás',
      one: '$count Ano Atrás',
    );
    return '$_temp0';
  }

  @override
  String get flashbackOnThisDay => 'Neste dia';

  @override
  String get pageGalleryTitle => 'Galeria';

  @override
  String get searchLogsHint => 'Buscar Registros…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registros',
      one: '$count registro',
    );
    return '$_temp0';
  }

  @override
  String wordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count palavras',
      one: '$count palavra',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => 'Sem Registros…';

  @override
  String get noResults => 'Sem resultados…';

  @override
  String get sortDateTitle => 'Data';

  @override
  String get sortOrderAscendingTitle => 'Crescente';

  @override
  String get sortOrderDescendingTitle => 'Decrescente';

  @override
  String get pageStatisticsTitle => 'Estatísticas';

  @override
  String get statisticsNotEnoughData => 'Sem dados suficientes…';

  @override
  String get statisticsRangeOneMonth => '1 Mês';

  @override
  String get statisticsRangeSixMonths => '6 Meses';

  @override
  String get statisticsRangeOneYear => '1 Ano';

  @override
  String get statisticsRangeAllTime => 'Todo o histórico';

  @override
  String chartSummaryTitle(Object tag) {
    return 'Resumo de $tag';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag Por Dia';
  }

  @override
  String get chartGroupingLabel => 'Agrupar por';

  @override
  String get chartGroupingDay => 'Dia';

  @override
  String get chartGroupingWeek => 'Semana';

  @override
  String get chartGroupingMonth => 'Mês';

  @override
  String get chartGroupingYear => 'Ano';

  @override
  String streakCurrent(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sequência Atual $count',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sequência Mais Longa $count',
    );
    return '$_temp0';
  }

  @override
  String streakSinceBadDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dias Desde um Dia Ruim $count',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle =>
      'Não é possível acessar armazenamento externo';

  @override
  String get errorExternalStorageAccessDescription =>
      'Se você estiver usando o armazenamento em rede, certifique-se que o serviço está online e que você tenha acesso à rede.\n\nCaso contrário, o aplicativo pode ter perdido permissões para a pasta externa. Vá em configurações e selecione novamente a pasta externa para permitir o acesso.\n\nAtenção: as modificações não serão sincronizadas até você restaurar o acesso ao local do armazenamento externo!';

  @override
  String get errorExternalStorageAccessContinue =>
      'Continuar com banco de dados local';

  @override
  String get lastModified => 'Modificado';

  @override
  String get writeSomethingHint => 'Escreva alguma coisa…';

  @override
  String get titleHint => 'Título…';

  @override
  String get deleteLogTitle => 'Apagar Registro';

  @override
  String get deleteLogDescription => 'Você quer apagar este registro?';

  @override
  String get deletePhotoTitle => 'Remover Foto';

  @override
  String get deletePhotoDescription => 'Você quer apagar esta foto?';

  @override
  String get pageSettingsTitle => 'Configurações';

  @override
  String get settingsAppearanceTitle => 'Aparência';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => 'Primeiro Dia da Semana';

  @override
  String get settingsCalendarSystem => 'Sistema de Calendário';

  @override
  String get calendarSystemGregorian => 'Gregoriano';

  @override
  String get calendarSystemJalali => 'Persa';

  @override
  String get settingsUseSystemAccentColor => 'Usar Cores do Sistema';

  @override
  String get settingsCustomAccentColor => 'Cor Personalizada';

  @override
  String get settingsShowMarkdownToolbar =>
      'Mostrar Barra de Ferramentas Markdown';

  @override
  String get settingsShowFlashbacks => 'Mostrar Flashbacks';

  @override
  String get settingsChangeMoodIcons => 'Alterar Ícones de Humor';

  @override
  String get moodIconPrompt => 'Insira um ícone';

  @override
  String get settingsFlashbacksViewLayout => 'Visualização de Recordações';

  @override
  String get settingsGalleryViewLayout => 'Visualização da Galeria';

  @override
  String get settingsHideImagesInGallery => 'Ocultar Imagens Na Galeria';

  @override
  String get settingsHideImages => 'Ocultar Imagens';

  @override
  String get pageCalendarTitle => 'Calendário';

  @override
  String get viewLayoutList => 'Lista';

  @override
  String get viewLayoutGrid => 'Grade';

  @override
  String get settingsNotificationsTitle => 'Notificações';

  @override
  String get settingsDailyReminderOnboarding =>
      'Habilite lembretes diários para te deixar consistente!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'A permissão \"Agendar Alarmes\" será solicitada para mandar lembretes a um momento aleatório ou ao seu tempo preferido.';

  @override
  String get settingsDailyReminderTitle => 'Lembrete Diário';

  @override
  String get settingsDailyReminderDescription => 'Um lembrete suave cada dia';

  @override
  String get settingsReminderTime => 'Hora do Lembrete';

  @override
  String get settingsFixedReminderTimeTitle => 'Hora do Lembrete Fixa';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Escolha uma hora fixa para o lembrete';

  @override
  String get settingsAlwaysSendReminderTitle => 'Sempre mandar um lembrete';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Mandar um lembrete mesmo se um registro já foi começado';

  @override
  String get settingsCustomizeNotificationTitle => 'Customizar Notificações';

  @override
  String get settingsTemplatesTitle => 'Modelos';

  @override
  String get settingsDefaultTemplate => 'Modelo Padrão';

  @override
  String get manageTemplates => 'Gerenciar Modelos';

  @override
  String get addTemplate => 'Adicionar Modelo';

  @override
  String get newTemplate => 'Novo Modelo';

  @override
  String get noTemplateTitle => 'Nenhum';

  @override
  String get noTemplatesDescription => 'Nenhum modelo criado ainda…';

  @override
  String get templateVariableTime => 'Tempo';

  @override
  String get templateDefaultTimestampTitle => 'Registro de data';

  @override
  String templateDefaultTimestampBody(Object date, Object time) {
    return '$date-$time:';
  }

  @override
  String get templateDefaultSummaryTitle => 'Resumo Diário';

  @override
  String get templateDefaultSummaryBody => '### Resumo\n- \n\n### Citação\n> ';

  @override
  String get templateDefaultReflectionTitle => 'Reflexão';

  @override
  String get templateDefaultReflectionBody =>
      '### O que você gostou sobre hoje?\n- \n\n### O que te deixou agradecido(a)?\n- \n\n### O que você espera para o futuro?\n- ';

  @override
  String get settingsStorageTitle => 'Armazenamento';

  @override
  String get settingsImageQuality => 'Qualidade da Imagem';

  @override
  String get imageQualityHigh => 'Alta';

  @override
  String get imageQualityMedium => 'Média';

  @override
  String get imageQualityLow => 'Baixa';

  @override
  String get imageQualityNoCompression => 'Sem Compressão';

  @override
  String get settingsLogFolder => 'Pasta de Registros';

  @override
  String get settingsImageFolder => 'Pasta de Imagens';

  @override
  String get warningTitle => 'Aviso';

  @override
  String get logFolderWarningDescription =>
      'Se a pasta selecionada já contiver um arquivo \'daily_you.db\', ele será usado para substituir seus registros existentes!';

  @override
  String get errorTitle => 'Erro';

  @override
  String get logFolderErrorDescription =>
      'Não foi possível alterar a pasta de registros!';

  @override
  String get imageFolderErrorDescription =>
      'Não foi possível alterar a pasta de imagens!';

  @override
  String get backupErrorDescription => 'Não foi possível criar backup!';

  @override
  String get restoreErrorDescription => 'Não foi possível restaurar backup!';

  @override
  String get settingsBackupRestoreTitle => 'Backup e Restaurar';

  @override
  String get settingsBackup => 'Backup';

  @override
  String get settingsRestore => 'Restaurar';

  @override
  String get settingsRestorePromptDescription =>
      'Restaurar um backup irá sobrescrever os seus dados atuais!';

  @override
  String tranferStatus(Object percent) {
    return 'Transferindo… $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'Criando Backup… $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'Restaurando Backup… $percent%';
  }

  @override
  String get cleanUpStatus => 'Limpando…';

  @override
  String get settingsExport => 'Exportar';

  @override
  String get settingsExportToAnotherFormat => 'Exportar Para Outro Formato';

  @override
  String get settingsExportFormatDescription =>
      'Isso não deve ser usado como backup!';

  @override
  String get exportLogs => 'Exportar Registros';

  @override
  String get exportImages => 'Exportar Imagens';

  @override
  String get settingsImport => 'Importar';

  @override
  String get settingsImportFromAnotherApp => 'Importar de Outro Aplicativo';

  @override
  String get settingsTranslateCallToAction =>
      'Todos devem ter acesso a um diário!';

  @override
  String get settingsHelpTranslate => 'Ajude a Traduzir';

  @override
  String get importLogs => 'Importar Registros';

  @override
  String get importImages => 'Importar Imagens';

  @override
  String get logFormatTitle => 'Escolher Formato';

  @override
  String get logFormatDescription =>
      'O formato de outro aplicativo pode não suportar todas as funcionalidades. Por favor, informe qualquer problemas, pois os formatos de terceiros podem mudar a qualquer momento. Isto não irá impactar os registros existentes!';

  @override
  String get formatMarkdown => 'Markdown';

  @override
  String get settingsDeleteAllLogsTitle => 'Apagar Todos os Registros';

  @override
  String get settingsDeleteAllLogsDescription =>
      'Você quer apagar todos os seus registros?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Digite \'$prompt\' para confirmar. Isto não pode ser desfeito!';
  }

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsAppLanguageTitle => 'Linguagem do Aplicativo';

  @override
  String get settingsOverrideAppLanguageTitle =>
      'Substituir Linguagem do Aplicativo';

  @override
  String get settingsSecurityTitle => 'Segurança';

  @override
  String get settingsSecurityRequirePassword => 'Requer Senha';

  @override
  String get settingsSecurityEnterPassword => 'Digite a Senha';

  @override
  String get settingsSecuritySetPassword => 'Definir Senha';

  @override
  String get settingsSecurityChangePassword => 'Mudar Senha';

  @override
  String get settingsSecurityPassword => 'Senha';

  @override
  String get settingsSecurityConfirmPassword => 'Confirmar Senha';

  @override
  String get settingsSecurityOldPassword => 'Senha Antiga';

  @override
  String get settingsSecurityIncorrectPassword => 'Senha Incorreta';

  @override
  String get settingsSecurityPasswordsDoNotMatch => 'Senhas Não Coincidem';

  @override
  String get requiredPrompt => 'Obrigatório';

  @override
  String get settingsSecurityBiometricUnlock => 'Desbloquear com Biometria';

  @override
  String get unlockAppPrompt => 'Desbloquear Aplicativo';

  @override
  String get settingsAboutTitle => 'Sobre';

  @override
  String get settingsVersion => 'Versão';

  @override
  String get settingsLicense => 'Licença';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'Código-fonte';

  @override
  String get settingsMadeWithLove => 'Feito com ❤️';

  @override
  String get settingsConsiderSupporting => 'Considere Apoiar';

  @override
  String get tagMoodTitle => 'Humor';
}
