// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => 'Scrivi sul diario';

  @override
  String get dailyReminderDescription => 'Tieni traccia della tua giornata…';

  @override
  String get actionTakePhoto => 'Scatta una foto';

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
  String get actionToday => 'Oggi';

  @override
  String get actionOtherDay => 'Altro giorno';

  @override
  String get pageHomeTitle => 'Home';

  @override
  String get jumpToMonthTitle => 'Vai al mese';

  @override
  String get jumpToLogTitle => 'Vai al giorno';

  @override
  String get flashbacksTitle => 'Ricordi';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Escludi le giornate negative';

  @override
  String get flaskbacksEmpty => 'Ancora nessun ricordo…';

  @override
  String get flashbackGoodDay => 'Una bella giornata';

  @override
  String get flashbackRandomDay => 'Una giornata casuale';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count settimane fa',
      one: '$count settimana fa',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mesi fa',
      one: '$count mese fa',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count anni fa',
      one: '$count anno fa',
    );
    return '$_temp0';
  }

  @override
  String get flashbackOnThisDay => 'Accade oggi';

  @override
  String get pageGalleryTitle => 'Galleria';

  @override
  String get searchLogsHint => 'Cerca entrate del diario…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count annotazioni',
      one: '$count annotazione',
    );
    return '$_temp0';
  }

  @override
  String dayCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni',
      one: '$count giorno',
    );
    return '$_temp0';
  }

  @override
  String wordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count parole',
      one: '$count parola',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => 'Nessuna annotazione…';

  @override
  String get noResults => 'Nessun risultato…';

  @override
  String get sortDateTitle => 'Data';

  @override
  String get sortOrderAscendingTitle => 'Crescente';

  @override
  String get sortOrderDescendingTitle => 'Decrescente';

  @override
  String get pageStatisticsTitle => 'Statistiche';

  @override
  String get statisticsNotEnoughData => 'Dati insufficienti…';

  @override
  String get statisticsRangeOneMonth => 'Un mese';

  @override
  String get statisticsRangeSixMonths => '6 mesi';

  @override
  String get statisticsRangeOneYear => 'Un anno';

  @override
  String get statisticsRangeAllTime => 'Da sempre';

  @override
  String chartSummaryTitle(Object tag) {
    return 'Riepilogo $tag';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag per giorno';
  }

  @override
  String chartOverTimeTitle(Object tag) {
    return '$tag nel tempo';
  }

  @override
  String get chartGroupingLabel => 'Raggruppa per';

  @override
  String get chartGroupingDay => 'Giorno';

  @override
  String get chartGroupingWeek => 'Settimana';

  @override
  String get chartGroupingMonth => 'Mese';

  @override
  String get chartGroupingYear => 'Anno';

  @override
  String get chartSmoothingLabel => 'Smussamento delle curve';

  @override
  String streakCurrent(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni di fila',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Record di giorni di fila: $count',
    );
    return '$_temp0';
  }

  @override
  String streakGreatDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Giornate positive $count',
    );
    return '$_temp0';
  }

  @override
  String streakSinceBadDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Giorni trascorsi dall\'ultima giornata negativa $count',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle =>
      'Impossibile accedere alla memoria esterna';

  @override
  String get errorExternalStorageAccessDescription =>
      'Se utilizzi un archivio di rete, assicurati che il servizio sia online e che tu disponga di accesso alla rete.\n\nIn caso contrario, l\'app potrebbe aver perso le autorizzazioni per la cartella esterna. Vai alle impostazioni e seleziona la cartella esterna, e concedi l\'accesso.\n\nAttenzione, le modifiche non verranno sincronizzate finché non ripristinerai l\'accesso all\'archivio esterno!';

  @override
  String get errorExternalStorageAccessContinue =>
      'Prosegui con l\'archivio locale';

  @override
  String get databaseMigrationErrorTitle => 'Impossibile spostare i dati';

  @override
  String get databaseMigrationErrorDescription =>
      'I tuoi ricordi sono al sicuro, ma non è stato possibile spostarli nell\'archivio dell\'app.\n\nRiprova. Dovesse continuare a succedere, crea una segnalazione.';

  @override
  String get databaseMigrationErrorRetry => 'Riprova';

  @override
  String get databaseNewerErrorTitle => 'Update Required';

  @override
  String get databaseNewerErrorDescription =>
      'Your data was saved by a newer version of Daily You. This version can\'t open it safely. Update the app to continue.';

  @override
  String get errorReport => 'Segnala un problema';

  @override
  String get lastModified => 'Modificato';

  @override
  String get writeSomethingHint => 'Scrivi qualcosa…';

  @override
  String get titleHint => 'Titolo…';

  @override
  String get deleteLogTitle => 'Elimina l\'entrata del diario';

  @override
  String get deleteLogDescription =>
      'Vuoi davvero eliminare questa entrata del diario?';

  @override
  String get deletePhotoTitle => 'Elimina la foto';

  @override
  String get deletePhotoDescription => 'Vuoi eliminare questa foto?';

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
  String get pageSettingsTitle => 'Impostazioni';

  @override
  String get settingsAppearanceTitle => 'Aspetto';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => 'Primo giorno della settimana';

  @override
  String get settingsCalendarSystem => 'Formato del calendario';

  @override
  String get calendarSystemGregorian => 'Gregoriano';

  @override
  String get calendarSystemJalali => 'Persiano';

  @override
  String get settingsUseSystemAccentColor =>
      'Usa il colore di accento del sistema';

  @override
  String get settingsCustomAccentColor => 'Personalizza colore';

  @override
  String get settingsShowMarkdownToolbar =>
      'Mostra la barra degli strumenti Markdown';

  @override
  String get settingsShowFlashbacks => 'Mostra i ricordi';

  @override
  String get settingsChangeMoodIcons => 'Cambia le icone dell\'umore';

  @override
  String get moodIconPrompt => 'Inserisci un\'icona';

  @override
  String get settingsFlashbacksViewLayout =>
      'Layout di visualizzazione Ricordi';

  @override
  String get settingsGalleryViewLayout => 'Layout visualizzazione Galleria';

  @override
  String get settingsHideImagesInGallery =>
      'Nascondi le immagini nella galleria';

  @override
  String get settingsHideImages => 'Nascondi immagini';

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
  String get pageCalendarTitle => 'Calendario';

  @override
  String get viewLayoutList => 'Elenco';

  @override
  String get viewLayoutGrid => 'Griglia';

  @override
  String get settingsNotificationsTitle => 'Notifiche';

  @override
  String get settingsDailyReminderOnboarding =>
      'Attiva i promemoria giornalieri per rimanere costante!';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'Sarà richiesta l\'autorizzazione \"imposta sveglie\" per poterti inviare i promemoria casuali o al tuo orario preferito.';

  @override
  String get settingsDailyReminderTitle => 'Promemoria giornaliero';

  @override
  String get settingsOnThisDayDescription => 'Riguarda i tuoi ricordi passati';

  @override
  String get settingsDailyReminderDescription =>
      'Ricevi il promemoria giornaliero';

  @override
  String get settingsReminderTime => 'Orario del promemoria';

  @override
  String get settingsFixedReminderTimeTitle =>
      'Fissa un orario per il promemoria';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Scegli un orario fisso per ricevere un promemoria';

  @override
  String get settingsAlwaysSendReminderTitle => 'Invia comunque un promemoria';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Invia il promemoria giornaliero anche se hai già creato un ricordo manualmente';

  @override
  String get settingsCustomizeNotificationTitle =>
      'Personalizza le notifiche (impostazioni di sistema)';

  @override
  String get settingsTemplatesTitle => 'Modelli fac-simile';

  @override
  String get settingsDefaultTemplate => 'Modello predefinito';

  @override
  String get manageTemplates => 'Gestisci i modelli';

  @override
  String get addTemplate => 'Aggiungi un modello';

  @override
  String get newTemplate => 'Nuovo Modello';

  @override
  String get noTemplateTitle => 'Nessuno';

  @override
  String get noTemplatesDescription => 'Nessun modello ancora creato…';

  @override
  String get templateVariableTime => 'Orario';

  @override
  String get templateDefaultTimestampTitle => 'Data e ora';

  @override
  String templateDefaultTimestampBody(Object date, Object time) {
    return '$date, $time:';
  }

  @override
  String get templateDefaultSummaryTitle => 'Resoconto di oggi';

  @override
  String get templateDefaultSummaryBody =>
      '### Riassunto\n- \n\n### Citazioni\n> ';

  @override
  String get templateDefaultReflectionTitle => 'Riflessioni';

  @override
  String get templateDefaultReflectionBody =>
      '### Cos\'hai fatto oggi di memorabile?\n- \n\n### Cos\'è successo di bello?\n- \n\n### Nuovi progetti per il futuro?\n- ';

  @override
  String get settingsTagsTitle => 'Etichette';

  @override
  String get manageTags => 'Gestisci le etichette';

  @override
  String get tagTypeLabelTitle => 'Etichetta';

  @override
  String get tagTypeTrackerTitle => 'Quantità';

  @override
  String get nameHint => 'Nome';

  @override
  String get tagColorLabel => 'Colore';

  @override
  String get iconPickerTitle => 'Scegli un\'icona';

  @override
  String get iconPickerIconsTab => 'Icone';

  @override
  String get iconPickerCustomTab => 'Personalizzato';

  @override
  String get iconPickerSearchHint => 'Cerca icone…';

  @override
  String get colorPickerTitle => 'Scegli un colore';

  @override
  String get colorPickerPaletteTab => 'Colori';

  @override
  String get iconGroupMoodPeople => 'Umori e persone';

  @override
  String get iconGroupHealth => 'Salute';

  @override
  String get iconGroupWorkFinance => 'Lavoro e finanza';

  @override
  String get iconGroupHabitsGoals => 'Abitudini e obiettivi';

  @override
  String get iconGroupNature => 'Ambiente';

  @override
  String get iconGroupFoodDrink => 'Cibo e bevande';

  @override
  String get iconGroupHome => 'Casa';

  @override
  String get iconGroupTravel => 'Viaggio';

  @override
  String get iconGroupSymbols => 'Simboli';

  @override
  String get tagCategoryLabel => 'Categoria';

  @override
  String get tagLabel => 'Annotazione';

  @override
  String get tagCategoryUncategorized => 'Senza categoria';

  @override
  String get newCategoryTitle => 'Nuova categoria';

  @override
  String get shareButtonLabel => 'Condividi';

  @override
  String get importErrorDescription => 'Impossibile importare il file';

  @override
  String get exportErrorDescription => 'Impossibile esportare il file!';

  @override
  String get deleteTitle => 'Elimina';

  @override
  String deleteTagMessage(num count, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' È utilizzata in $count entrate del diario.',
      one: ' È utilizzata in un\'entrata del diario.',
      zero: '',
    );
    return 'Eliminare \"$name\"?$_temp0';
  }

  @override
  String deleteCategoryMessage(num count, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' Anche le sue $count annotazioni (categorie) saranno eliminate.',
      one: ' Verrà eliminata anche una sua annotazione (categoria).',
      zero: '',
    );
    return 'Eliminare \"$name\"?$_temp0';
  }

  @override
  String deleteTemplateMessage(Object name) {
    return 'Eliminare \"$name\"?';
  }

  @override
  String get filterTagsTitle => 'Filtro';

  @override
  String get tagFilterModeAny => 'Qualsiasi annotazione';

  @override
  String get tagFilterModeAll => 'Tutte le annotazioni';

  @override
  String get clearAllFilters => 'Resetta';

  @override
  String get noTagsFilterLabel => 'Senza annotazioni';

  @override
  String get addTagsTitle => 'Aggiungi annotazioni';

  @override
  String get addTagsSearchHint => 'Cerca annotazioni…';

  @override
  String get tagPickerSortManualLabel => 'Ordine predefinito';

  @override
  String get tagPickerSortUsageLabel => 'Per frequenza di utilizzo';

  @override
  String get tagFavoriteName => 'Preferiti';

  @override
  String get tagEnergyName => 'Energia';

  @override
  String get tagCategoryActivitiesName => 'Attività';

  @override
  String get tagExerciseName => 'Esercizio';

  @override
  String get tagSocializingName => 'Compagnia';

  @override
  String get tagHobbyName => 'Passatempo';

  @override
  String get tagEntertainmentName => 'Cinema e teatro';

  @override
  String get tagDiningName => 'Cibo';

  @override
  String get tagChoresName => 'Faccende domestiche';

  @override
  String get tagCategoryEmotionsName => 'Stati d\'animo';

  @override
  String get tagExcitedName => 'Entusiasta';

  @override
  String get tagGratefulName => 'Gratitudine';

  @override
  String get tagCalmName => 'In pace';

  @override
  String get tagTiredName => 'Stanchezza';

  @override
  String get tagAnxiousName => 'Ansia';

  @override
  String get tagAnnoyedName => 'Fastidio';

  @override
  String get welcomeLogBodyText =>
      '## Benvenuto in Daily You\n\n> Ogni giorno merita di essere ricordato, catturalo!\n\n**Daily You** è gratuito e [open source](https://github.com/Demizo/Daily_You) e supportato dagli utenti. Nasce dalla convinzione che il tuo diario debba appartenere solo a te e non essere un prodotto:\n\n- Nessuna pubblicità\n- Nessuna funzionalità a pagamento\n- Nessun tracciamento e nessun dato raccolto\n\nSe vuoi scrivere un diario, tenere nota delle tue giornate, o semplicemente annotare quello che ti ha fatto stare bene, **Daily You** ti offre uno spazio privato che è _davvero solo tuo_.';

  @override
  String get settingsStorageTitle => 'Archiviazione';

  @override
  String get settingsImageQuality => 'Qualità delle immagini';

  @override
  String get settingsMediaQualityTitle => 'Media Quality';

  @override
  String get imageQualityHigh => 'Alta';

  @override
  String get imageQualityMedium => 'Media';

  @override
  String get imageQualityLow => 'Bassa';

  @override
  String get imageQualityNoCompression => 'Qualità originale';

  @override
  String get settingsStorageUsage => 'Storage Usage';

  @override
  String get settingsLogFolder => 'Cartella delle entrate del diario';

  @override
  String get settingsImageFolder => 'Cartella delle immagini';

  @override
  String get settingsExternalSyncTitle => 'Sync with External Location';

  @override
  String get chooseFolderHint => 'Choose a folder';

  @override
  String get warningTitle => 'Attenzione';

  @override
  String get logFolderWarningDescription =>
      'Se la cartella selezionata contiene già un file \'daily_you.db\', verrà utilizzato per sovrascrivere le annotazioni esistenti!';

  @override
  String get errorTitle => 'Errore';

  @override
  String get logFolderErrorDescription =>
      'Impossibile cambiare cartella delle entrate del diario!';

  @override
  String get imageFolderErrorDescription =>
      'Impossibile modificare la cartella delle immagini!';

  @override
  String get syncErrorDescription =>
      'Failed to sync with the external location!';

  @override
  String get backupErrorDescription => 'Impossibile creare il backup!';

  @override
  String get restoreErrorDescription => 'Impossibile ripristinare il backup!';

  @override
  String get settingsBackupRestoreTitle => 'Backup e ripristino';

  @override
  String get settingsBackup => 'Backup';

  @override
  String get settingsRestore => 'Ripristino';

  @override
  String get settingsRestorePromptDescription =>
      'Ripristinare un backup sovrascriverà i dati esistenti!';

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
    return 'Trasferimento… $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'Creazione del backup… $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'Ripristino dal backup… $percent%';
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
  String get cleanUpStatus => 'Sto facendo pulizia…';

  @override
  String migratingImagesStatus(Object current, Object total) {
    return 'Spostando $current foto su $total';
  }

  @override
  String get settingsExport => 'Export';

  @override
  String get settingsExportToAnotherFormat => 'Esporta in un altro formato';

  @override
  String get settingsExportFormatDescription =>
      'Questo non dovrebbe essere usato come backup!';

  @override
  String get exportLogs => 'Export Logs';

  @override
  String get exportImages => 'Export Images';

  @override
  String get exportIncludeTitle => 'Include';

  @override
  String get settingsImport => 'Import';

  @override
  String get settingsImportFromAnotherApp => 'Importa da un\'altra app';

  @override
  String get settingsTranslateCallToAction =>
      'Tutti dovrebbero avere un diario!';

  @override
  String get settingsHelpTranslate => 'Aiuta a tradurre';

  @override
  String get importLogs => 'Import Logs';

  @override
  String get importImages => 'Import Images';

  @override
  String get logFormatTitle => 'Scegli il Formato';

  @override
  String get logFormatDescription =>
      'Il formato di un\'altra app potrebbe non supportare tutte le funzionalità. Riporta qualsiasi problema riscontri poiché i formati di terze parti possono cambiare in qualsiasi momento. Ciò non avrà impatto sulle note esistenti!';

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
  String get settingsDeleteAllLogsTitle =>
      'Cancella tutte le entrate del diario';

  @override
  String get settingsDeleteAllLogsDescription =>
      'Vuoi davvero cancellare tutte le tue entrate del diario?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Inserisci \'$prompt\' per confermare. Questa operazione non può essere annullata!';
  }

  @override
  String get settingsLanguageTitle => 'Lingua';

  @override
  String get settingsAppLanguageTitle => 'Lingua dell\'app';

  @override
  String get settingsOverrideAppLanguageTitle =>
      'Sovrascrivi la lingua dell\'app';

  @override
  String get settingsSecurityTitle => 'Sicurezza';

  @override
  String get settingsSecurityRequirePassword => 'Richiedi una password';

  @override
  String get settingsSecurityEnterPassword => 'Inserisci la password';

  @override
  String get settingsSecuritySetPassword => 'Imposta una password';

  @override
  String get settingsSecurityChangePassword => 'Cambia la password';

  @override
  String get settingsSecurityPassword => 'Password';

  @override
  String get settingsSecurityConfirmPassword => 'Conferma password';

  @override
  String get settingsSecurityOldPassword => 'Vecchia password';

  @override
  String get settingsSecurityIncorrectPassword => 'Password errata';

  @override
  String get settingsSecurityPasswordsDoNotMatch =>
      'Le password non coincidono';

  @override
  String get requiredPrompt => 'Campo richiesto';

  @override
  String get settingsSecurityBiometricUnlock => 'Sblocco biometrico';

  @override
  String get unlockAppPrompt => 'Sblocca l\'app';

  @override
  String get settingsAboutTitle => 'Informazioni';

  @override
  String get settingsVersion => 'Versione';

  @override
  String get settingsLicense => 'Licenza';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'Codice sorgente';

  @override
  String get settingsOpenSourceLicenses => 'Open Source Licenses';

  @override
  String get settingsMadeWithLove => 'Fatto con il ❤️';

  @override
  String get settingsConsiderSupporting =>
      'considera la possibilità di sostenere il progetto';

  @override
  String get imagesTitle => 'Foto';

  @override
  String get audioTitle => 'Audio';

  @override
  String get videoTitle => 'Video';

  @override
  String get tagMoodTitle => 'Stato d\'animo';

  @override
  String get calendarTagDisplayLabel => 'Annotazione';

  @override
  String get selectTagTitle => 'Scegli un\'annotazione';

  @override
  String get labelPresentLabel => 'Presente';

  @override
  String get labelAbsentLabel => 'Assente';

  @override
  String get labelCoverageLabel => 'Periodo';

  @override
  String chartDistributionTitle(Object tag) {
    return 'Distribuzione di $tag';
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
}
