// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => 'Log hari ini!';

  @override
  String get dailyReminderDescription => 'Ambil log harian anda…';

  @override
  String get actionTakePhoto => 'Ambil gambar';

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
  String get actionToday => 'Hari ini';

  @override
  String get actionOtherDay => 'Hari lain';

  @override
  String get pageHomeTitle => 'Utama';

  @override
  String get jumpToMonthTitle => 'Langkau ke bulan';

  @override
  String get jumpToLogTitle => 'Langkau ke log';

  @override
  String get flashbacksTitle => 'Imbas kembali';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Kecualikan hari-hari buruk';

  @override
  String get flaskbacksEmpty => 'Belum ada imbas semula…';

  @override
  String get flashbackGoodDay => 'Hari yang baik';

  @override
  String get flashbackRandomDay => 'Hari yang rawak';

  @override
  String flashbackWeek(num count) {
    return '$count Minggu Lepas';
  }

  @override
  String flashbackMonth(num count) {
    return '$count Bulan Lepas';
  }

  @override
  String flashbackYear(num count) {
    return '$count Tahun Lepas';
  }

  @override
  String get flashbackOnThisDay => 'Pada Hari Ini';

  @override
  String get pageGalleryTitle => 'Galeri';

  @override
  String get searchLogsHint => 'Log carian…';

  @override
  String logCount(num count) {
    return '$count log';
  }

  @override
  String dayCount(num count) {
    return '$count hari';
  }

  @override
  String wordCount(num count) {
    return '$count perkataan';
  }

  @override
  String get noLogs => 'Tiada log…';

  @override
  String get noResults => 'Tiada hasil…';

  @override
  String get sortDateTitle => 'Tarikh';

  @override
  String get sortOrderAscendingTitle => 'Menaik';

  @override
  String get sortOrderDescendingTitle => 'Menurun';

  @override
  String get pageStatisticsTitle => 'Statistik';

  @override
  String get statisticsNotEnoughData => 'Tidak cukup data…';

  @override
  String get statisticsRangeOneMonth => '1 Bulan';

  @override
  String get statisticsRangeSixMonths => '6 Bulan';

  @override
  String get statisticsRangeOneYear => '1 Tahun';

  @override
  String get statisticsRangeAllTime => 'Setiap Masa';

  @override
  String chartSummaryTitle(Object tag) {
    return '$tag Ringkasan';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag Per Hari';
  }

  @override
  String chartOverTimeTitle(Object tag) {
    return '$tag Dari Semasa Ke Semasa';
  }

  @override
  String get chartGroupingLabel => 'Kumpulkan dengan';

  @override
  String get chartGroupingDay => 'Hari';

  @override
  String get chartGroupingWeek => 'Minggu';

  @override
  String get chartGroupingMonth => 'Bulan';

  @override
  String get chartGroupingYear => 'Tahun';

  @override
  String get chartSmoothingLabel => 'Smoothing';

  @override
  String streakCurrent(num count) {
    return 'Rentetan Semasa $count';
  }

  @override
  String streakLongest(num count) {
    return 'Rentetan Terpanjang $count';
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
    return 'Hari Semenjak Hari Yang Buruk $count';
  }

  @override
  String get errorExternalStorageAccessTitle =>
      'Tidak Dapat Mengakses Storan Luaran';

  @override
  String get errorExternalStorageAccessDescription =>
      'Jika anda menggunakan storan rangkaian, pastikan perkhidmatan tersebut dalam talian dan anda mempunyai akses rangkaian.\n\nJika tidak, aplikasi mungkin akan kehilangan kebenaran untuk folder luaran. Pergi ke tetapan dan pilih semula folder luaran untuk memberikan akses.\n\nAmaran, perubahan tidak akan disegerakkan sehingga anda memulihkan akses ke lokasi storan luaran!';

  @override
  String get errorExternalStorageAccessContinue =>
      'Teruskan Dengan Pangkalan Data Tempatan';

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
  String get lastModified => 'Diubah suai';

  @override
  String get writeSomethingHint => 'Tulis sesuatu…';

  @override
  String get titleHint => 'Tajuk…';

  @override
  String get deleteLogTitle => 'Padam Log';

  @override
  String get deleteLogDescription => 'Adakah anda ingin memadam log ini?';

  @override
  String get deletePhotoTitle => 'Padam Foto';

  @override
  String get deletePhotoDescription => 'Adakah anda ingin memadam foto ini?';

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
  String get pageSettingsTitle => 'Tetapan';

  @override
  String get settingsAppearanceTitle => 'Penampilan';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Terang';

  @override
  String get themeDark => 'Gelap';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => 'Hari Pertama Dalam Seminggu';

  @override
  String get settingsCalendarSystem => 'Sistem Kalendar';

  @override
  String get calendarSystemGregorian => 'Gregorian';

  @override
  String get calendarSystemJalali => 'Jalali';

  @override
  String get settingsUseSystemAccentColor => 'Gunakan Warna Tema Sistem';

  @override
  String get settingsCustomAccentColor => 'Warna Tema Tersuai';

  @override
  String get settingsShowMarkdownToolbar => 'Show Markdown Toolbar';

  @override
  String get settingsShowFlashbacks => 'Tunjukkan Imbasan Semula';

  @override
  String get settingsChangeMoodIcons => 'Tukar Ikon Emosi';

  @override
  String get moodIconPrompt => 'Masukkan Ikon';

  @override
  String get settingsFlashbacksViewLayout => 'Flashbacks View Layout';

  @override
  String get settingsGalleryViewLayout => 'Susun Atur Paparan Galeri';

  @override
  String get settingsHideImagesInGallery => 'Sembunyikan Imej Dalam Galeri';

  @override
  String get settingsHideImages => 'Sembunyikan Imej';

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
  String get pageCalendarTitle => 'Kalendar';

  @override
  String get viewLayoutList => 'Senarai';

  @override
  String get viewLayoutGrid => 'Grid';

  @override
  String get settingsNotificationsTitle => 'Pemberitahuan';

  @override
  String get settingsDailyReminderOnboarding =>
      'Dayakan peringatan harian untuk memastikan diri anda konsisten!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'Kebenaran \'jadualkan penggera\' akan diminta untuk menghantar peringatan pada waktu tertentu atau pada waktu pilihan anda.';

  @override
  String get settingsDailyReminderTitle => 'Peringatan Harian';

  @override
  String get settingsOnThisDayDescription => 'Imbas kembali memori lama';

  @override
  String get settingsDailyReminderDescription =>
      'Peringatan lembut setiap hari';

  @override
  String get settingsReminderTime => 'Masa Peringatan';

  @override
  String get settingsFixedReminderTimeTitle => 'Masa Peringatan Tetap';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Pilih masa yang tetap untuk peringatan';

  @override
  String get settingsAlwaysSendReminderTitle => 'Semtiasa Hantar Peringatan';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Hantar peringatan walaupun log telah dimulakan';

  @override
  String get settingsCustomizeNotificationTitle => 'Sesuaikan Pemberitahuan';

  @override
  String get settingsTemplatesTitle => 'Templat';

  @override
  String get settingsDefaultTemplate => 'Templat Asal';

  @override
  String get manageTemplates => 'Urus Templat';

  @override
  String get addTemplate => 'Tambah Templat';

  @override
  String get newTemplate => 'New Template';

  @override
  String get noTemplateTitle => 'Tiada';

  @override
  String get noTemplatesDescription => 'Tiada templat dicipta…';

  @override
  String get templateVariableTime => 'Masa';

  @override
  String get templateDefaultTimestampTitle => 'Tanda Masa';

  @override
  String templateDefaultTimestampBody(Object date, Object time) {
    return '$date - $time:';
  }

  @override
  String get templateDefaultSummaryTitle => 'Ringkasan Hari';

  @override
  String get templateDefaultSummaryBody =>
      '### Ringkasan\n- \n\n### Petikan\n> ';

  @override
  String get templateDefaultReflectionTitle => 'Refleksi';

  @override
  String get templateDefaultReflectionBody =>
      '### Apakah yang anda nikmati hari ini?\n- \n\n### Apakah yang anda syukuri?\n- \n\n### Apakah yang anda nanti-nantikan?\n- ';

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
  String get settingsStorageTitle => 'Storan';

  @override
  String get settingsImageQuality => 'Kualiti Imej';

  @override
  String get settingsMediaQualityTitle => 'Media Quality';

  @override
  String get imageQualityHigh => 'Tinggi';

  @override
  String get imageQualityMedium => 'Sederhana';

  @override
  String get imageQualityLow => 'Rendah';

  @override
  String get imageQualityNoCompression => 'Tiada Pemampatan';

  @override
  String get settingsStorageUsage => 'Storage Usage';

  @override
  String get settingsLogFolder => 'Folder Log';

  @override
  String get settingsImageFolder => 'Folder Imej';

  @override
  String get settingsExternalSyncTitle => 'Sync with External Location';

  @override
  String get chooseFolderHint => 'Choose a folder';

  @override
  String get warningTitle => 'Amaran';

  @override
  String get logFolderWarningDescription =>
      'Jika folder yang dipilih telah mengandungi fail \'daily_you.db\', ia akan digunakan untuk menulis semula log sedia ada anda!';

  @override
  String get errorTitle => 'Ralat';

  @override
  String get logFolderErrorDescription => 'Gagal menukar folder log!';

  @override
  String get imageFolderErrorDescription => 'Gagal menukar folder imej!';

  @override
  String get syncErrorDescription =>
      'Failed to sync with the external location!';

  @override
  String get backupErrorDescription => 'Gagal mencipta sandaran!';

  @override
  String get restoreErrorDescription => 'Gagal memulihkan sandaran!';

  @override
  String get settingsBackupRestoreTitle => 'Sandaran & Pemulihan';

  @override
  String get settingsBackup => 'Sandarkan';

  @override
  String get settingsRestore => 'Pulihkan';

  @override
  String get settingsRestorePromptDescription =>
      'Memulihkan sandaran akan menulis semula data sedia ada anda!';

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
    return 'Memindahkan... $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'Mencipta Sandaran... $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'Memulihkan Sandaran... $percent%';
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
  String get cleanUpStatus => 'Membersihkan…';

  @override
  String migratingImagesStatus(Object current, Object total) {
    return 'Migrating photos… $current/$total';
  }

  @override
  String get settingsExport => 'Export';

  @override
  String get settingsExportToAnotherFormat => 'Eksport Kepada Format Lain';

  @override
  String get settingsExportFormatDescription =>
      'Ini tidak boleh digunakan sebagai sandaran!';

  @override
  String get exportLogs => 'Export Logs';

  @override
  String get exportImages => 'Export Images';

  @override
  String get exportIncludeTitle => 'Include';

  @override
  String get settingsImport => 'Import';

  @override
  String get settingsImportFromAnotherApp => 'Import Daripada Aplikasi Lain';

  @override
  String get settingsTranslateCallToAction =>
      'Setiap orang harus mempunyai akses kepada jurnal!';

  @override
  String get settingsHelpTranslate => 'Bantu Terjemahkan';

  @override
  String get importLogs => 'Import Logs';

  @override
  String get importImages => 'Import Images';

  @override
  String get logFormatTitle => 'Pilih Format';

  @override
  String get logFormatDescription =>
      'Format aplikasi lain mungkin tidak menyokong semua ciri. Sila laporkan sebarang isu kerana format pihak ketiga mungkin berubah pada bila-bila masa. Ini tidak akan menjejaskan log sedia ada!';

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
  String get settingsDeleteAllLogsTitle => 'Padam Semua Log';

  @override
  String get settingsDeleteAllLogsDescription =>
      'Adakah anda ingin memadam semua log anda?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Masukkan \'$prompt\' untuk meneruskan. Ini tidak dapat dibatalkan!';
  }

  @override
  String get settingsLanguageTitle => 'Bahasa';

  @override
  String get settingsAppLanguageTitle => 'Bahasa Apl';

  @override
  String get settingsOverrideAppLanguageTitle => 'Bahasa Aplikasi Ganti';

  @override
  String get settingsSecurityTitle => 'Keselamatan';

  @override
  String get settingsSecurityRequirePassword => 'Memerlukan Kata Laluan';

  @override
  String get settingsSecurityEnterPassword => 'Masukkan Kata Laluan';

  @override
  String get settingsSecuritySetPassword => 'Tetapkan Kata Laluan';

  @override
  String get settingsSecurityChangePassword => 'Tukar Kata Laluan';

  @override
  String get settingsSecurityPassword => 'Kata Laluan';

  @override
  String get settingsSecurityConfirmPassword => 'Sahkan Kata Laluan';

  @override
  String get settingsSecurityOldPassword => 'Kata Laluan Lama';

  @override
  String get settingsSecurityIncorrectPassword => 'Kata Laluan Salah';

  @override
  String get settingsSecurityPasswordsDoNotMatch => 'Kata laluan tidak sepadan';

  @override
  String get requiredPrompt => 'Diperlukan';

  @override
  String get settingsSecurityBiometricUnlock => 'Buka Kunci Biometrik';

  @override
  String get unlockAppPrompt => 'Buka kunci apl';

  @override
  String get settingsAboutTitle => 'Tentang';

  @override
  String get settingsVersion => 'Versi';

  @override
  String get settingsLicense => 'Lesen';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'Kod Sumber';

  @override
  String get settingsOpenSourceLicenses => 'Open Source Licenses';

  @override
  String get settingsMadeWithLove => 'Dibuat dengan ❤️';

  @override
  String get settingsConsiderSupporting => 'pertimbangkan untuk menyokong';

  @override
  String get imagesTitle => 'Images';

  @override
  String get audioTitle => 'Audio';

  @override
  String get videoTitle => 'Video';

  @override
  String get tagMoodTitle => 'Suasana';

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
