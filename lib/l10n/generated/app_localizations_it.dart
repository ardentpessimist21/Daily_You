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
