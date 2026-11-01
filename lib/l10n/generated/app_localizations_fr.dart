// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Daily You';

  @override
  String get dailyReminderTitle => 'Notez votre journée !';

  @override
  String get dailyReminderDescription =>
      'N\'oubliez pas d\'enregistrer votre journée…';

  @override
  String get actionTakePhoto => 'Prendre une photo';

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
  String get actionToday => 'Aujourd\'hui';

  @override
  String get actionOtherDay => 'Autre jour';

  @override
  String get pageHomeTitle => 'Accueil';

  @override
  String get jumpToMonthTitle => 'Aller au mois';

  @override
  String get jumpToLogTitle => 'Aller à l’entrée';

  @override
  String get flashbacksTitle => 'Souvenirs';

  @override
  String get settingsFlashbacksExcludeBadDays => 'Exclure les mauvais jours';

  @override
  String get flaskbacksEmpty => 'Pas encore de souvenirs…';

  @override
  String get flashbackGoodDay => 'Une bonne journée';

  @override
  String get flashbackRandomDay => 'Une journée ordinaire';

  @override
  String flashbackWeek(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semaines',
      one: '$count semaine',
    );
    return '$_temp0';
  }

  @override
  String flashbackMonth(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mois',
      one: '$count mois',
    );
    return '$_temp0';
  }

  @override
  String flashbackYear(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ans',
      one: '$count an',
    );
    return '$_temp0';
  }

  @override
  String get flashbackOnThisDay => 'Il y a 1 an';

  @override
  String get pageGalleryTitle => 'Galerie';

  @override
  String get searchLogsHint => 'Rechercher des souvenirs…';

  @override
  String logCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enregistrements',
      one: '$count enregistrement',
    );
    return '$_temp0';
  }

  @override
  String dayCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '$count jour',
    );
    return '$_temp0';
  }

  @override
  String wordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mots',
      one: '$count mot',
    );
    return '$_temp0';
  }

  @override
  String get noLogs => 'Aucun souvenir…';

  @override
  String get noResults => 'Aucun résultat…';

  @override
  String get sortDateTitle => 'Date';

  @override
  String get sortOrderAscendingTitle => 'Ascendant';

  @override
  String get sortOrderDescendingTitle => 'Descendant';

  @override
  String get pageStatisticsTitle => 'Statistiques';

  @override
  String get statisticsNotEnoughData => 'Pas assez de données…';

  @override
  String get statisticsRangeOneMonth => '1 mois';

  @override
  String get statisticsRangeSixMonths => '6 mois';

  @override
  String get statisticsRangeOneYear => '1 an';

  @override
  String get statisticsRangeAllTime => 'Historique complet';

  @override
  String chartSummaryTitle(Object tag) {
    return 'Résumé $tag';
  }

  @override
  String chartByDayTitle(Object tag) {
    return '$tag par jour';
  }

  @override
  String chartOverTimeTitle(Object tag) {
    return '$tag sur la durée';
  }

  @override
  String get chartGroupingLabel => 'Grouper par';

  @override
  String get chartGroupingDay => 'Jour';

  @override
  String get chartGroupingWeek => 'Semaine';

  @override
  String get chartGroupingMonth => 'Mois';

  @override
  String get chartGroupingYear => 'Année';

  @override
  String get chartSmoothingLabel => 'Lissage';

  @override
  String streakCurrent(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Série actuelle $count',
    );
    return '$_temp0';
  }

  @override
  String streakLongest(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Série la plus longue $count',
    );
    return '$_temp0';
  }

  @override
  String streakGreatDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bonnes journées $count',
    );
    return '$_temp0';
  }

  @override
  String streakSinceBadDay(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jours depuis une mauvaise journée $count',
    );
    return '$_temp0';
  }

  @override
  String get errorExternalStorageAccessTitle =>
      'Impossible d\'accéder au stockage externe';

  @override
  String get errorExternalStorageAccessDescription =>
      'Si vous utilisez le stockage en réseau, assurez-vous que le service est en ligne et que vous avez accès au réseau.\n\nDans le cas contraire, l\'application peut avoir perdu les autorisations pour le dossier externe. Allez dans les paramètres et resélectionnez le dossier externe pour lui accorder l\'accès.\n\nAttention, les modifications ne seront pas synchronisées tant que vous n\'aurez pas rétabli l\'accès à l\'emplacement de stockage externe !';

  @override
  String get errorExternalStorageAccessContinue =>
      'Poursuivre avec la base de données locale';

  @override
  String get databaseMigrationErrorTitle =>
      'Déplacement des données impossible';

  @override
  String get databaseMigrationErrorDescription =>
      'Vos entrées sont en sécurité mais n\'ont pas pu être déplacées dans le stockage applicatif.\n\nEssayez de nouveau et signaler ce souci s’il continue de se produire.';

  @override
  String get databaseMigrationErrorRetry => 'Réessayer';

  @override
  String get databaseNewerErrorTitle => 'Update Required';

  @override
  String get databaseNewerErrorDescription =>
      'Your data was saved by a newer version of Daily You. This version can\'t open it safely. Update the app to continue.';

  @override
  String get errorReport => 'Signaler un problème';

  @override
  String get lastModified => 'Modification';

  @override
  String get writeSomethingHint => 'Écrivez quelque chose…';

  @override
  String get titleHint => 'Titre…';

  @override
  String get deleteLogTitle => 'Supprimer le souvenir';

  @override
  String get deleteLogDescription => 'Voulez-vous supprimer ce souvenir ?';

  @override
  String get deletePhotoTitle => 'Supprimer la photo';

  @override
  String get deletePhotoDescription => 'Voulez-vous supprimer cette photo ?';

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
  String get pageSettingsTitle => 'Paramètres';

  @override
  String get settingsAppearanceTitle => 'Apparence';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeAmoled => 'AMOLED';

  @override
  String get settingsFirstDayOfWeek => '1er jour de la semaine';

  @override
  String get settingsCalendarSystem => 'Système calendaire';

  @override
  String get calendarSystemGregorian => 'Grégorien';

  @override
  String get calendarSystemJalali => 'Jalali';

  @override
  String get settingsUseSystemAccentColor =>
      'Utiliser la couleur d\'appui du système';

  @override
  String get settingsCustomAccentColor => 'Couleur d\'appui personnalisée';

  @override
  String get settingsShowMarkdownToolbar =>
      'Afficher la barre d\'outils Markdown';

  @override
  String get settingsShowFlashbacks => 'Afficher les souvenirs';

  @override
  String get settingsChangeMoodIcons => 'Modifier les icônes d\'humeur';

  @override
  String get moodIconPrompt => 'Saisir une icône';

  @override
  String get settingsFlashbacksViewLayout =>
      'Disposition de la vue des flashbacks';

  @override
  String get settingsGalleryViewLayout => 'Disposition de la galerie';

  @override
  String get settingsHideImagesInGallery => 'Cacher les images dans la galerie';

  @override
  String get settingsHideImages => 'Masquer les images';

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
  String get pageCalendarTitle => 'Agenda';

  @override
  String get viewLayoutList => 'Liste';

  @override
  String get viewLayoutGrid => 'Grille';

  @override
  String get settingsNotificationsTitle => 'Notifications';

  @override
  String get settingsDailyReminderOnboarding =>
      'Activer le rappel quotidien pour être consistant !';

  @override
  String get settingsNotificationsPermissionsPrompt =>
      'On demandera l\'autorisation « alarme planifiée » pour envoyer un rappel à un moment au hasard ou au moment que vous souhaitez.';

  @override
  String get settingsDailyReminderTitle => 'Rappel quotidien';

  @override
  String get settingsOnThisDayDescription => 'Revisiter des mémoires d\'avant';

  @override
  String get settingsDailyReminderDescription =>
      'Un simple rappel tous les jours';

  @override
  String get settingsReminderTime => 'Heure du rappel';

  @override
  String get settingsFixedReminderTimeTitle => 'Heure fixe du rappel';

  @override
  String get settingsFixedReminderTimeDescription =>
      'Choisir une heure fixe pour le rappel';

  @override
  String get settingsAlwaysSendReminderTitle => 'Toujours envoyer un rappel';

  @override
  String get settingsAlwaysSendReminderDescription =>
      'Envoyer un rappel même si une entrée est déjà commencée';

  @override
  String get settingsCustomizeNotificationTitle =>
      'Personnaliser les notifications';

  @override
  String get settingsTemplatesTitle => 'Modèles';

  @override
  String get settingsDefaultTemplate => 'Modèle par défaut';

  @override
  String get manageTemplates => 'Gérer les modèles';

  @override
  String get addTemplate => 'Ajouter un modèle';

  @override
  String get newTemplate => 'Nouveau modèle';

  @override
  String get noTemplateTitle => 'Aucun';

  @override
  String get noTemplatesDescription => 'Aucun modèle créé pour l\'instant…';

  @override
  String get templateVariableTime => 'Heure';

  @override
  String get templateDefaultTimestampTitle => 'Horodatage';

  @override
  String templateDefaultTimestampBody(Object date, Object time) {
    return '$date – $time :';
  }

  @override
  String get templateDefaultSummaryTitle => 'Résumé du jour';

  @override
  String get templateDefaultSummaryBody => '### Résumé\n- \n\n### Avis\n> ';

  @override
  String get templateDefaultReflectionTitle => 'Remarque';

  @override
  String get templateDefaultReflectionBody =>
      '### Qu\'est-ce qui vous a plu aujourd\'hui ?\n- \n\n### Pour quoi avez-vous de la reconnaissance ?\n- \n\n### Qu\'est-ce qu\'il vous tarde ?\n- ';

  @override
  String get settingsTagsTitle => 'Étiquettes';

  @override
  String get manageTags => 'Gestion des étiquettes';

  @override
  String get tagTypeLabelTitle => 'Label';

  @override
  String get tagTypeTrackerTitle => 'Compteur';

  @override
  String get nameHint => 'Nom';

  @override
  String get tagColorLabel => 'Couleur';

  @override
  String get iconPickerTitle => 'Choisir une icône';

  @override
  String get iconPickerIconsTab => 'Icône';

  @override
  String get iconPickerCustomTab => 'Personnalisée';

  @override
  String get iconPickerSearchHint => 'Chercher des icônes…';

  @override
  String get colorPickerTitle => 'Choisir une couleur';

  @override
  String get colorPickerPaletteTab => 'Couleurs';

  @override
  String get iconGroupMoodPeople => 'Humeur et gens';

  @override
  String get iconGroupHealth => 'Santé';

  @override
  String get iconGroupWorkFinance => 'Travail et finance';

  @override
  String get iconGroupHabitsGoals => 'Habitudes et objectifs';

  @override
  String get iconGroupNature => 'Nature';

  @override
  String get iconGroupFoodDrink => 'Boire et manger';

  @override
  String get iconGroupHome => 'Maison';

  @override
  String get iconGroupTravel => 'Voyage';

  @override
  String get iconGroupSymbols => 'Symboles';

  @override
  String get tagCategoryLabel => 'Catégorie';

  @override
  String get tagLabel => 'Étiquette';

  @override
  String get tagCategoryUncategorized => 'Sans catégorie';

  @override
  String get newCategoryTitle => 'Nouvelle catégorie';

  @override
  String get shareButtonLabel => 'Partager';

  @override
  String get importErrorDescription => 'Échec de l\'import du fichier !';

  @override
  String get exportErrorDescription => 'Échec de l\'export du fichier !';

  @override
  String get deleteTitle => 'Supprimer';

  @override
  String deleteTagMessage(num count, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' Il est utilisé dans $count enregistrements.',
      one: ' Il est utilisé dans 1 enregistrement.',
      zero: '',
    );
    return 'Supprimer « $name » ?$_temp0';
  }

  @override
  String deleteCategoryMessage(num count, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' Les $count étiquettes seront aussi supprimées.',
      one: ' Son étiquette sera aussi supprimée.',
      zero: '',
    );
    return 'Supprimer « $name » ?$_temp0';
  }

  @override
  String deleteTemplateMessage(Object name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get filterTagsTitle => 'Filtrer';

  @override
  String get tagFilterModeAny => 'N’importe quelle étiquette';

  @override
  String get tagFilterModeAll => 'Toutes les étiquettes';

  @override
  String get clearAllFilters => 'Tout effacer';

  @override
  String get noTagsFilterLabel => 'Aucune étiquette';

  @override
  String get addTagsTitle => 'Ajouter des étiquettes';

  @override
  String get addTagsSearchHint => 'Chercher des étiquettes…';

  @override
  String get tagPickerSortManualLabel => 'Ordre manuel';

  @override
  String get tagPickerSortUsageLabel => 'Trier par utilisation';

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
  String get tagFavoriteName => 'Favoris';

  @override
  String get tagEnergyName => 'Énergie';

  @override
  String get tagCategoryActivitiesName => 'Activités';

  @override
  String get tagExerciseName => 'Exercice';

  @override
  String get tagSocializingName => 'Vie sociale';

  @override
  String get tagHobbyName => 'Loisir';

  @override
  String get tagEntertainmentName => 'Divertissement';

  @override
  String get tagDiningName => 'Dîner';

  @override
  String get tagChoresName => 'Tâches ménagères';

  @override
  String get tagCategoryEmotionsName => 'Émotions';

  @override
  String get tagExcitedName => 'Impatience';

  @override
  String get tagGratefulName => 'Reconnaissance';

  @override
  String get tagCalmName => 'Calme';

  @override
  String get tagTiredName => 'Fatigue';

  @override
  String get tagAnxiousName => 'Anxiété';

  @override
  String get tagAnnoyedName => 'Ennui';

  @override
  String get welcomeLogBodyText =>
      '## Bienvenue dans Daily You\n\n> Chaque jour mérite qu\'on s\'en souvienne, immortalisez-le !\n\n**Daily You** est gratuit, [open source](https://github.com/Demizo/Daily_You) et soutenu par la communauté. Conçu avec la conviction que votre journal doit vous appartenir, et non être un produit :\n\n- Aucune publicité\n- Aucune fonctionnalité verrouillée\n- Aucun suivi ni collecte de données\n\nQue vous teniez un journal, que vous fassiez de l\'introspection ou que vous notiez simplement ce qui vous a fait sourire, **Daily You** vous offre un espace privé qui est _vraiment le vôtre_.';

  @override
  String get settingsStorageTitle => 'Stockage';

  @override
  String get settingsImageQuality => 'Qualité d\'image';

  @override
  String get settingsMediaQualityTitle => 'Media Quality';

  @override
  String get imageQualityHigh => 'Élevée';

  @override
  String get imageQualityMedium => 'Moyenne';

  @override
  String get imageQualityLow => 'Basse';

  @override
  String get imageQualityNoCompression => 'Sans compression';

  @override
  String get settingsStorageUsage => 'Storage Usage';

  @override
  String get settingsLogFolder => 'Dossier d\'enregistrement';

  @override
  String get settingsImageFolder => 'Dossier d\'images';

  @override
  String get settingsExternalSyncTitle => 'Sync with External Location';

  @override
  String get chooseFolderHint => 'Choose a folder';

  @override
  String get warningTitle => 'Attention';

  @override
  String get logFolderWarningDescription =>
      'Si le dossier sélectionné contient déjà un fichier \'daily_you.db\', celui-ci sera utilisé pour écraser vos enregistrements existants !';

  @override
  String get errorTitle => 'Erreur';

  @override
  String get logFolderErrorDescription =>
      'Échec de la modification du dossier d\'enregistrement !';

  @override
  String get imageFolderErrorDescription =>
      'Échec de la modification du dossier de l\'image !';

  @override
  String get syncErrorDescription =>
      'Failed to sync with the external location!';

  @override
  String get backupErrorDescription =>
      'Échec de la création de la sauvegarde !';

  @override
  String get restoreErrorDescription =>
      'Échec de la restauration de la sauvegarde !';

  @override
  String get settingsBackupRestoreTitle => 'Sauvegarde et restauration';

  @override
  String get settingsBackup => 'Sauvegarde';

  @override
  String get settingsRestore => 'Restauration';

  @override
  String get settingsRestorePromptDescription =>
      'La restauration d’une sauvegarde remplacera vos données existantes !';

  @override
  String get settingsBackupPasswordProtect =>
      'Sauvegardes protégées par mot de passe';

  @override
  String get backupEncryptedTitle => 'Sauvegarde chiffrée';

  @override
  String get backupEncryptedContent =>
      'Cette sauvegarde est protégée par mot de passe.';

  @override
  String get settingsAutoBackup => 'Sauvegardes automatiques';

  @override
  String get settingsAutoBackupLocation => 'Emplacement de sauvegarde';

  @override
  String get settingsAutoBackupInterval => 'Intervalle de sauvegarde';

  @override
  String get settingsAutoBackupIntervalDaily => 'Quotidienne';

  @override
  String get settingsAutoBackupIntervalWeekly => 'Hebdomadaire';

  @override
  String get settingsAutoBackupIntervalMonthly => 'Mensuelle';

  @override
  String get settingsAutoBackupMaxCount => 'Sauvegardes à conserver';

  @override
  String get settingsAutoBackupRequireCharging => 'Seulement en charge';

  @override
  String settingsBackupLast(Object time) {
    return 'Dernière sauvegarde $time';
  }

  @override
  String get settingsBackupNever => 'Jamais sauvegardé';

  @override
  String settingsAutoBackupNext(Object time) {
    return 'Prochaine sauvegarde $time';
  }

  @override
  String get settingsAutoBackupKeepAll => 'Toutes';

  @override
  String get autoBackupFailedTitle => 'Échec de la sauvegarde';

  @override
  String tranferStatus(Object percent) {
    return 'Transfert… $percent%';
  }

  @override
  String creatingBackupStatus(Object percent) {
    return 'Création de la sauvegarde… $percent%';
  }

  @override
  String restoringBackupStatus(Object percent) {
    return 'Restauration de ka sauvegarde… $percent%';
  }

  @override
  String encryptingBackupStatus(Object percent) {
    return 'Chiffrement de la sauvegarde… $percent%';
  }

  @override
  String decryptingBackupStatus(Object percent) {
    return 'Déchiffrement de la sauvegarde… $percent%';
  }

  @override
  String get cleanUpStatus => 'Nettoyage…';

  @override
  String migratingImagesStatus(Object current, Object total) {
    return 'Migration des photos… $current/$total';
  }

  @override
  String get settingsExport => 'Exporter';

  @override
  String get settingsExportToAnotherFormat => 'Exporter dans un autre format';

  @override
  String get settingsExportFormatDescription =>
      'Ne doit pas être utilisé comme sauvegarde !';

  @override
  String get exportLogs => 'Exporter les enregistrements';

  @override
  String get exportImages => 'Exporter les images';

  @override
  String get exportIncludeTitle => 'Include';

  @override
  String get settingsImport => 'Importer';

  @override
  String get settingsImportFromAnotherApp => 'Import d’une autre application';

  @override
  String get settingsTranslateCallToAction =>
      'Tout le monde devrait avoir accès à un journal !';

  @override
  String get settingsHelpTranslate => 'Aider à traduire';

  @override
  String get importLogs => 'Importer les enregistrements';

  @override
  String get importImages => 'Importer les images';

  @override
  String get logFormatTitle => 'Choisissez le format';

  @override
  String get logFormatDescription =>
      'Le format d’un autre application peut ne pas prendre en charge toutes les fonctionnalités. Merci de signaler tout problème étant donné que les formats tiers peuvent changer avec le temps. Cela n’affectera pas les journaux existants !';

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
  String get settingsDeleteAllLogsTitle => 'Supprimer tous les enregistrements';

  @override
  String get settingsDeleteAllLogsDescription =>
      'Voulez-vous supprimer tous vos enregistrements ?';

  @override
  String settingsDeleteAllLogsPrompt(Object prompt) {
    return 'Écrivez \'$prompt\' pour confirmer. Cette action est irréversible !';
  }

  @override
  String get settingsLanguageTitle => 'Langue';

  @override
  String get settingsAppLanguageTitle => 'Ajouter une langue';

  @override
  String get settingsOverrideAppLanguageTitle =>
      'Surcharger la langue de l\'application';

  @override
  String get settingsSecurityTitle => 'Sécurité';

  @override
  String get settingsSecurityRequirePassword => 'Exiger un mot de passe';

  @override
  String get settingsSecurityEnterPassword => 'Entrer le mot de passe';

  @override
  String get settingsSecuritySetPassword => 'Définir le mot de passe';

  @override
  String get settingsSecurityChangePassword => 'Modifier le mot de passe';

  @override
  String get settingsSecurityPassword => 'Mot de passe';

  @override
  String get settingsSecurityConfirmPassword => 'Confirmer le mot de passe';

  @override
  String get settingsSecurityOldPassword => 'Ancien mot de passe';

  @override
  String get settingsSecurityIncorrectPassword => 'Mot de passe incorrect';

  @override
  String get settingsSecurityPasswordsDoNotMatch =>
      'Les mots de passe sont différents';

  @override
  String get requiredPrompt => 'Requis';

  @override
  String get settingsSecurityBiometricUnlock => 'Déverrouillage biométrique';

  @override
  String get unlockAppPrompt => 'Déverrouiller l\'application';

  @override
  String get settingsAboutTitle => 'À propos';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLicense => 'Licence';

  @override
  String get licenseGPLv3 => 'GPL-3.0';

  @override
  String get settingsSourceCode => 'Code source';

  @override
  String get settingsOpenSourceLicenses => 'Licences Open Source';

  @override
  String get settingsMadeWithLove => 'Fait avec ❤️';

  @override
  String get settingsConsiderSupporting => 'pensez à soutenir';

  @override
  String get imagesTitle => 'Images';

  @override
  String get audioTitle => 'Audio';

  @override
  String get videoTitle => 'Video';

  @override
  String get tagMoodTitle => 'Humeur';

  @override
  String get calendarTagDisplayLabel => 'Étiquette';

  @override
  String get selectTagTitle => 'Sélectionner une étiquette';

  @override
  String get labelPresentLabel => 'Présent';

  @override
  String get labelAbsentLabel => 'Absent';

  @override
  String get labelCoverageLabel => 'Couverture';

  @override
  String chartDistributionTitle(Object tag) {
    return 'Distribution de $tag';
  }

  @override
  String get shareAddToLogPickerTitle => 'Choisir un enregistrement';

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
