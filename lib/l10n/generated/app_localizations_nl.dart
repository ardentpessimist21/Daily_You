// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => 'Log vandaag!';

  @override
  String get dailyReminderDescription => 'Schrijf je dagelijkse log…';

  @override
  String get actionTakePhoto => 'Trek foto';

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
  String get actionToday => 'Vandaag';

  @override
  String get actionOtherDay => 'Andere dag';

  @override
  String get pageHomeTitle => 'Start';

  @override
  String get jumpToMonthTitle => 'Spring naar maand';

  @override
  String get jumpToLogTitle => 'Jump to log';

  @override
  String get flashbacksTitle => 'Terugblikken';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Sluit slechte dagen uit';

  @override
  String get flaskbacksEmpty => 'Nog geen terugblikken…';

  @override
  String get flashbackGoodDay => 'Een goede dag';

  @override
  String get flashbackRandomDay => 'Een willekeurige dag';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weken geleden',
      one: '$count week geleden',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count maanden geleden',
      one: '$count maand geleden',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jaren geleden',
      one: '$count jaar geleden',
    );
    return '$_temp0';
  }

  @override
  String get flashbackOnThisDay => 'On This Day';

  @override
  String get pageGalleryTitle => 'Galerij';

  @override
  String get searchLogsHint => 'Doorzoek logboeken…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count logs',
      one: '$count log',
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
      other: '$count woorden',
      one: '$count woord',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => 'Geen logs te tonen…';

  @override
  String get noResults => 'No Results…';

  @override
  String get sortDateTitle => 'Datum';

  @override
  String get sortOrderAscendingTitle => 'Oplopend';

  @override
  String get sortOrderDescendingTitle => 'Aflopend';

  @override
  String get pageStatisticsTitle => 'Statistieken';

  @override
  String get statisticsNotEnoughData => 'Niet genoeg data…';

  @override
  String get statisticsRangeOneMonth => '1 maand';

  @override
  String get statisticsRangeSixMonths => '6 maanden';

  @override
  String get statisticsRangeOneYear => '1 jaar';

  @override
  String get statisticsRangeAllTime => 'Alles';

  @override
  String chartSummaryTitle(Object tag) {
    return '$tag Samenvatting';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag per dag';
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
      other: 'Huidige reeks $count',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Langste reeks $count',
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
      other: 'Dagen sinds een slechte dag $count',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle =>
      'Geen toegang tot externe opslag';

  @override
  String get errorExternalStorageAccessDescription =>
      'Als je netwerkopslag gebruikt, zorg ervoor dat de service online is en dat je netwerktoegang hebt.\n\nHet kan ook zijn dat de app privileges voor de externe map is verloren. Ga naar instellingen en selecteer de externe map om toegang te geven.\n\nWaarschuwing, veranderingen worden niet gesynchroniseerd totdat je toegang tot de externe opslag hersteld!';

  @override
  String get errorExternalStorageAccessContinue =>
      'Ga door met lokale database';

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
  String get lastModified => 'Gewijzigd';

  @override
  String get writeSomethingHint => 'Schrijf iets op…';

  @override
  String get titleHint => 'Titel…';

  @override
  String get deleteLogTitle => 'Verwijder log';

  @override
  String get deleteLogDescription =>
      'Weet je zeker dat je deze log wil verwijderen?';

  @override
  String get deletePhotoTitle => 'Verwijder foto';

  @override
  String get deletePhotoDescription =>
      'Weet je zeker dat je deze foto wil verwijderen?';

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
  String get pageSettingsTitle => 'Instellingen';

  @override
  String get settingsAppearanceTitle => 'Uiterlijk';

  @override
  String get settingsTheme => 'Thema';

  @override
  String get themeSystem => 'Systeem';

  @override
  String get themeLight => 'Licht';

  @override
  String get themeDark => 'Donker';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => 'Eerste dag van de week';

  @override
  String get settingsCalendarSystem => 'Calendar System';

  @override
  String get calendarSystemGregorian => 'Gregorian';

  @override
  String get calendarSystemJalali => 'Jalali';

  @override
  String get settingsUseSystemAccentColor =>
      'Gebruik accentkleur van het systeem';

  @override
  String get settingsCustomAccentColor => 'Eigen accentkleur';

  @override
  String get settingsShowMarkdownToolbar => 'Toon Markdown werkbalk';

  @override
  String get settingsShowFlashbacks => 'Toon terugblikken';

  @override
  String get settingsChangeMoodIcons => 'Wijzig humeuriconen';

  @override
  String get moodIconPrompt => 'Voer een icoon in';

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
  String get pageCalendarTitle => 'Calendar';

  @override
  String get viewLayoutList => 'List';

  @override
  String get viewLayoutGrid => 'Raster';

  @override
  String get settingsNotificationsTitle => 'Meldingen';

  @override
  String get settingsDailyReminderOnboarding =>
      'Zet dagelijkse herinneringen aan om consistent te blijven!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'De \'plan alarmen\' toestemming zal aangevraagd worden om de herinnering op een willekeurig moment of op je gewenste tijd te sturen.';

  @override
  String get settingsDailyReminderTitle => 'Dagelijkse herinnering';

  @override
  String get settingsOnThisDayDescription => 'Revisit past memories';

  @override
  String get settingsDailyReminderDescription =>
      'Iedere dag een kleine herinnering';

  @override
  String get settingsReminderTime => 'Herinneringstijd';

  @override
  String get settingsFixedReminderTimeTitle => 'Vaste herinneringstijd';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Kies een vaste tijd voor de herinnering';

  @override
  String get settingsAlwaysSendReminderTitle => 'Stuur altijd een herinnering';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Stuur ook een herinnering als er al gelogd is';

  @override
  String get settingsCustomizeNotificationTitle => 'Meldingen aanpassen';

  @override
  String get settingsTemplatesTitle => 'Sjablonen';

  @override
  String get settingsDefaultTemplate => 'Standaardsjabloon';

  @override
  String get manageTemplates => 'Sjablonen beheren';

  @override
  String get addTemplate => 'Sjabloon toevoegen';

  @override
  String get newTemplate => 'Nieuw sjabloon';

  @override
  String get noTemplateTitle => 'Geen';

  @override
  String get noTemplatesDescription => 'Nog geen sjablonen aangemaakt…';

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
  String get settingsStorageTitle => 'Opslag';

  @override
  String get settingsImageQuality => 'Afbeeldingskwaliteit';

  @override
  String get settingsMediaQualityTitle => 'Media Quality';

  @override
  String get imageQualityHigh => 'Hoog';

  @override
  String get imageQualityMedium => 'Middel';

  @override
  String get imageQualityLow => 'Laag';

  @override
  String get imageQualityNoCompression => 'Geen compressie';

  @override
  String get settingsStorageUsage => 'Storage Usage';

  @override
  String get settingsLogFolder => 'Logmap';

  @override
  String get settingsImageFolder => 'Afbeeldingsmap';

  @override
  String get settingsExternalSyncTitle => 'Sync with External Location';

  @override
  String get chooseFolderHint => 'Choose a folder';

  @override
  String get warningTitle => 'Waarschuwing';

  @override
  String get logFolderWarningDescription =>
      'Als de geselecteerde map al een \'daily_you.db\' bestand bevat, zal het gebruikt worden om je bestaande logs te overschrijven!';

  @override
  String get errorTitle => 'Fout';

  @override
  String get logFolderErrorDescription => 'Kan de logmap niet wijzigen!';

  @override
  String get imageFolderErrorDescription =>
      'Kan de afbeeldingsmap niet wijzigen!';

  @override
  String get syncErrorDescription =>
      'Failed to sync with the external location!';

  @override
  String get backupErrorDescription => 'Kan geen back-up maken!';

  @override
  String get restoreErrorDescription => 'Kan back-up niet herstellen!';

  @override
  String get settingsBackupRestoreTitle => 'Back-up & Herstellen';

  @override
  String get settingsBackup => 'Back-up';

  @override
  String get settingsRestore => 'Herstellen';

  @override
  String get settingsRestorePromptDescription =>
      'Het herstellen van een back-up zal je huidige data overschrijven!';

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
    return 'Overzetten... $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'Back-up maken... $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'Back-up herstellen... $percent%';
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
  String get cleanUpStatus => 'Schoonmaken…';

  @override
  String migratingImagesStatus(Object current, Object total) {
    return 'Migrating photos… $current/$total';
  }

  @override
  String get settingsExport => 'Export';

  @override
  String get settingsExportToAnotherFormat =>
      'Exporteren naar een ander formaat';

  @override
  String get settingsExportFormatDescription =>
      'Dit zou niet als een back-up gebruikt moeten worden!';

  @override
  String get exportLogs => 'Export Logs';

  @override
  String get exportImages => 'Export Images';

  @override
  String get exportIncludeTitle => 'Include';

  @override
  String get settingsImport => 'Import';

  @override
  String get settingsImportFromAnotherApp => 'Importeer vanuit een andere app';

  @override
  String get settingsTranslateCallToAction =>
      'Iedereen zou toegang tot een dagboek moeten hebben!';

  @override
  String get settingsHelpTranslate => 'Help vertalen';

  @override
  String get importLogs => 'Import Logs';

  @override
  String get importImages => 'Import Images';

  @override
  String get logFormatTitle => 'Kies formaat';

  @override
  String get logFormatDescription =>
      'Het formaat van een andere app ondersteunt mogelijk niet alle functies. Meld eventuele problemen, aangezien formaten van derden op ieder moment kunnen veranderen. Dit heeft geen invloed op bestaande logs!';

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
  String get settingsDeleteAllLogsTitle => 'Verwijder alle logs';

  @override
  String get settingsDeleteAllLogsDescription =>
      'Weet je zeker dat je alle logs wilt verwijderen?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Voer \'$prompt\' in om te bevestigen. Dit kan niet ongedaan worden gemaakt!';
  }

  @override
  String get settingsLanguageTitle => 'Taal';

  @override
  String get settingsAppLanguageTitle => 'Taal van de app';

  @override
  String get settingsOverrideAppLanguageTitle =>
      'Overschrijf de taal van de app';

  @override
  String get settingsSecurityTitle => 'Beveiliging';

  @override
  String get settingsSecurityRequirePassword => 'Vereis wachtwoord';

  @override
  String get settingsSecurityEnterPassword => 'Voer wachtwoord in';

  @override
  String get settingsSecuritySetPassword => 'Stel wachtwoord in';

  @override
  String get settingsSecurityChangePassword => 'Verander wachtwoord';

  @override
  String get settingsSecurityPassword => 'Wachtwoord';

  @override
  String get settingsSecurityConfirmPassword => 'Bevestig wachtwoord';

  @override
  String get settingsSecurityOldPassword => 'Oud wachtwoord';

  @override
  String get settingsSecurityIncorrectPassword => 'Onjuist wachtwoord';

  @override
  String get settingsSecurityPasswordsDoNotMatch =>
      'Wachtwoorden komen niet overeen';

  @override
  String get requiredPrompt => 'Vereist';

  @override
  String get settingsSecurityBiometricUnlock => 'Biometrische ontgrendeling';

  @override
  String get unlockAppPrompt => 'Ontgrendel de app';

  @override
  String get settingsAboutTitle => 'Over';

  @override
  String get settingsVersion => 'Versie';

  @override
  String get settingsLicense => 'Licentie';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'Broncode';

  @override
  String get settingsOpenSourceLicenses => 'Open Source Licenses';

  @override
  String get settingsMadeWithLove => 'Gemaakt met ❤️';

  @override
  String get settingsConsiderSupporting => 'overweeg te ondersteunen';

  @override
  String get imagesTitle => 'Images';

  @override
  String get audioTitle => 'Audio';

  @override
  String get videoTitle => 'Video';

  @override
  String get tagMoodTitle => 'Humeur';

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

  @override
  String get tagFilterTrackers => 'Trackers';

  @override
  String get settingsSelectionActions => 'Selection actions';

  @override
  String get settingsSelectionActionsHint =>
      'Buttons on the bar when you long-press to select entries in the Gallery or Timeline';

  @override
  String get quickFiltersTitle => 'Quick filters';

  @override
  String get quickFilterFavourite => 'Favourite';

  @override
  String get quickFilterLastEdited => 'Last Edited';

  @override
  String get quickFilterPin => 'Pin to Quick filters';

  @override
  String get quickFilterUnpin => 'Unpin from Quick filters';

  @override
  String quickFilterPinned(int used, int max) {
    return 'Pinned to Quick filters · $used of $max used';
  }

  @override
  String quickFilterPinsFull(int max) {
    return 'Quick filters hold $max pins. Unpin one to add another.';
  }

  @override
  String quickFilterPinnedSome(int added, int skipped, int max) {
    return 'Pinned $added, $skipped didn\'t fit · $max of $max used';
  }

  @override
  String get quickFilterUnpinned => 'Unpinned from Quick filters';

  @override
  String get pinnedTagsTitle => 'Pinned';

  @override
  String get tagsPinnedGallery => 'Pinned · Gallery';

  @override
  String get tagsPinnedAddTags => 'Pinned · Add Tags';

  @override
  String tagPinsFree(int count) {
    return '$count free';
  }

  @override
  String get tagPinsEmptyHint =>
      'Long-press tags and tap Pin to add them here.';

  @override
  String get tagsPinTo => 'Pin to';

  @override
  String get tagsPinListGallery => 'Gallery filter';

  @override
  String get tagsPinListAddTags => 'Add Tags';

  @override
  String tagsPinFreeOf(int free, int max) {
    return '$free of $max free';
  }

  @override
  String tagsUnpinFrom(String list) {
    return 'Unpin from $list';
  }

  @override
  String tagsPinnedTo(String list, int used, int max) {
    return 'Pinned to $list · $used of $max used';
  }

  @override
  String tagsPinsFull(String list, int max) {
    return '$list holds $max pins. Unpin one to add another.';
  }

  @override
  String tagsPinnedSome(int added, String list, int skipped) {
    return 'Pinned $added to $list, $skipped didn\'t fit';
  }

  @override
  String tagsUnpinnedFrom(String list) {
    return 'Unpinned from $list';
  }

  @override
  String get tagsChangeColour => 'Change colour';

  @override
  String tagsColourChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tags',
      one: '1 tag',
    );
    return 'Changed the colour of $_temp0';
  }

  @override
  String tagsDeleteSelectedMessage(int count, int logs) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tags',
      one: '1 tag',
    );
    String _temp1 = intl.Intl.pluralLogic(
      logs,
      locale: localeName,
      other: ' They\'re used in $logs logs.',
      one: ' They\'re used in 1 log.',
      zero: '',
    );
    return 'Delete $_temp0?$_temp1 This can\'t be undone.';
  }

  @override
  String get tagsDeleteBackupFirst => 'Back up first';

  @override
  String tagsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tags',
      one: '1 tag',
    );
    return 'Deleted $_temp0';
  }

  @override
  String get tagsSelectAll => 'Select all';

  @override
  String get tagsClearSelection => 'Clear selection';

  @override
  String get tagsExpandAll => 'Expand all';

  @override
  String get tagsCollapseAll => 'Collapse all';

  @override
  String get addTagsSortTitle => 'Sort tags';

  @override
  String get addTagsSortRecent => 'Recent';

  @override
  String get addTagsSortUsage => 'Sort by Usage';

  @override
  String get addTagsSortManual => 'My Order';

  @override
  String get addTagsTrackersOnly => 'Trackers only';
}
