import 'dart:typed_data';

// Performance optimization constants
const int _maxCodePoint =
    205743; // Maximum Unicode code point we need to support
const int _byteSize = 8; // 8 bits per byte

// Bitmap for fast character classification (word boundary vs word character)
// Each bit represents whether a character code point is a word boundary
final Uint8List _boundaryBitmap = Uint8List((_maxCodePoint ~/ _byteSize) + 1);

// CJK Unicode ranges for character-level tokenization
const List<List<int>> _cjkRanges = [
  [19968, 40959], // CJK Unified Ideographs                     4E00-9FFF
  [13312, 19903], // CJK Unified Ideographs Extension A         3400-4DBF
  [131072, 173791], // CJK Unified Ideographs Extension B       20000-2A6DF
  [173824, 177983], // CJK Unified Ideographs Extension C       2A700–2B73F
  [177984, 178207], // CJK Unified Ideographs Extension D       2B740–2B81F
  [178208, 183983], // CJK Unified Ideographs Extension E       2B820–2CEAF
  [183984, 191471], // CJK Unified Ideographs Extension F       2CEB0–2EBEF
  [196608, 201551], // CJK Unified Ideographs Extension G       30000–3134F
  [201552, 205743], // CJK Unified Ideographs Extension H       31350–323AF
  [63744, 64255], // CJK Compatibility Ideographs               F900-FAFF
  [194560, 195103], // CJK Compatibility Ideographs Supplement  2F800-2FA1F
  [12032, 12255], // CJK Radicals / Kangxi Radicals             2F00–2FDF
  [11904, 12031], // CJK Radicals Supplement                    2E80–2EFF
  [12288, 12351], // CJK Symbols and Punctuation                3000–303F
  [13056, 13311], // CJK Compatibility                          3300-33FF
  [65072, 65103], // CJK Compatibility Forms                     FE30-FE4F
  [12352, 12447], // Hiragana                                   3040-309F
  [12448, 12543], // Katakana                                   30A0-30FF
  [12784, 12799], // Katakana Phonetic Extensions              31F0-31FF
  [12688, 12703], // Kanbun                                     3190-319F
  [4352, 4607], // Hangul Jamo                                1100-11FF
  [12592, 12687], // Hangul Compatibility Jamo                 3130-318F
  [43360, 43391], // Hangul Jamo Extended-A                    A960-A97F
  [44032, 55215], // Hangul Syllables                          AC00-D7AF
  [55216, 55295], // Hangul Jamo Extended-B                    D7B0-D7FF
];

// Initialize bitmap with word boundary characters
bool _bitmapInitialized = false;

void _initializeBitmap() {
  if (_bitmapInitialized) return;

  // Only mark basic whitespace as boundaries in bitmap
  // Punctuation handling should be done via configuration, not bitmap
  final boundaries = [
    32, // space
    9, // tab
    10, // newline
    11, // vertical tab
    13, // carriage return
    3851, // Tibetan tsheg \u0F0B
    4961, // Ethiopic wordspace \u1361
    8203, // Zero-width space \u200b
  ];

  for (final charCode in boundaries) {
    _setBitmapBit(charCode);
  }

  // Mark CJK ranges as character boundaries (each character is a word)
  for (final range in _cjkRanges) {
    _setBitmapRange(range[0], range[1]);
  }

  _bitmapInitialized = true;
}

void _setBitmapBit(int charCode) {
  final byteIndex = charCode ~/ _byteSize;
  final bitIndex = charCode % _byteSize;
  if (byteIndex < _boundaryBitmap.length) {
    _boundaryBitmap[byteIndex] |= (1 << bitIndex);
  }
}

void _setBitmapRange(int from, int to) {
  for (
    int i = from ~/ _byteSize;
    i <= (to ~/ _byteSize) && i < _boundaryBitmap.length;
    i++
  ) {
    _boundaryBitmap[i] = 0xFF; // Mark entire byte
  }
}

bool _isBoundaryChar(int charCode) {
  final byteIndex = charCode ~/ _byteSize;
  final bitIndex = charCode % _byteSize;
  if (byteIndex >= _boundaryBitmap.length) return false;
  final byteAtIndex = _boundaryBitmap[byteIndex];
  return ((byteAtIndex >> bitIndex) & 1) == 1;
}

bool _isCjkChar(int charCode) {
  final byteIndex = charCode ~/ _byteSize;
  if (byteIndex >= _boundaryBitmap.length) return false;
  final byteAtIndex = _boundaryBitmap[byteIndex];
  return byteAtIndex == 0xFF; // CJK ranges are marked with full bytes
}

bool _isLetterOrDigit(int charCode) {
  // ASCII letters and digits
  if ((charCode >= 48 && charCode <= 57) || // 0-9
      (charCode >= 65 && charCode <= 90) || // A-Z
      (charCode >= 97 && charCode <= 122)) {
    // a-z
    return true;
  }

  // Extended Latin characters (matching original RegExp ranges)
  if ((charCode >= 0x00C0 && charCode <= 0x00FF) || // Latin-1 Supplement
      (charCode >= 0x0100 && charCode <= 0x017F) || // Latin Extended-A
      (charCode >= 0x0180 && charCode <= 0x024F) || // Latin Extended-B
      (charCode >= 0x0250 && charCode <= 0x02AF) || // IPA Extensions
      (charCode >= 0x1E00 && charCode <= 0x1EFF) || // Latin Extended Additional
      (charCode >= 0x0400 && charCode <= 0x04FF) || // Cyrillic
      (charCode >= 0x0500 && charCode <= 0x052F) || // Cyrillic Supplement
      (charCode >= 0x0D00 && charCode <= 0x0D7F)) {
    // Malayalam
    return true;
  }

  // Arabic script
  if ((charCode >= 0x0600 && charCode <= 0x06FF) || // Arabic
      (charCode >= 0x0750 && charCode <= 0x077F) || // Arabic Supplement
      (charCode >= 0x08A0 && charCode <= 0x08FF) || // Arabic Extended-A
      (charCode >= 0xFB50 &&
          charCode <= 0xFDFF) || // Arabic Presentation Forms-A
      (charCode >= 0xFE70 && charCode <= 0xFEFF)) {
    // Arabic Presentation Forms-B
    return true;
  }

  // Hebrew script
  if ((charCode >= 0x0590 && charCode <= 0x05FF)) {
    // Hebrew
    return true;
  }

  // Devanagari (Hindi and other Indic languages)
  if ((charCode >= 0x0900 && charCode <= 0x097F) || // Devanagari
      (charCode >= 0x0980 && charCode <= 0x09FF) || // Bengali
      (charCode >= 0x0A00 && charCode <= 0x0A7F) || // Gurmukhi
      (charCode >= 0x0A80 && charCode <= 0x0AFF) || // Gujarati
      (charCode >= 0x0B00 && charCode <= 0x0B7F) || // Oriya
      (charCode >= 0x0B80 && charCode <= 0x0BFF) || // Tamil
      (charCode >= 0x0C00 && charCode <= 0x0C7F) || // Telugu
      (charCode >= 0x0C80 && charCode <= 0x0CFF) || // Kannada
      (charCode >= 0x0D80 && charCode <= 0x0DFF) || // Sinhala
      (charCode >= 0x0E00 && charCode <= 0x0E7F) || // Thai
      (charCode >= 0x0E80 && charCode <= 0x0EFF) || // Lao
      (charCode >= 0x1000 && charCode <= 0x109F)) {
    // Myanmar
    return true;
  }

  // Additional scripts
  if ((charCode >= 0x0370 && charCode <= 0x03FF) || // Greek
      (charCode >= 0x0530 && charCode <= 0x058F) || // Armenian
      (charCode >= 0x10A0 && charCode <= 0x10FF) || // Georgian
      (charCode >= 0x1100 &&
          charCode <= 0x11FF) || // Hangul Jamo (already covered in CJK)
      (charCode >= 0x1200 && charCode <= 0x137F) || // Ethiopic
      (charCode >= 0x13A0 && charCode <= 0x13FF) || // Cherokee
      (charCode >= 0x1400 &&
          charCode <= 0x167F) || // Unified Canadian Aboriginal Syllabics
      (charCode >= 0x1680 && charCode <= 0x169F) || // Ogham
      (charCode >= 0x16A0 && charCode <= 0x16FF) || // Runic
      (charCode >= 0x1700 && charCode <= 0x171F) || // Tagalog
      (charCode >= 0x1720 && charCode <= 0x173F) || // Hanunoo
      (charCode >= 0x1740 && charCode <= 0x175F) || // Buhid
      (charCode >= 0x1760 && charCode <= 0x177F)) {
    // Tagbanwa
    return true;
  }

  return false;
}

bool _isNonWordCharacter(int charCode) {
  // Characters that the original RegExp would NOT match as word characters
  // This includes punctuation and symbols that should split words
  // when not explicitly configured as punctuation

  // But for config cases where default punctuation is disabled,
  // we should be more permissive and only split on what was actually
  // specified in the original RegExp word boundaries

  // The original RegExp only matched specific character ranges, so anything
  // outside those ranges would be treated as word boundaries
  return !_isLetterOrDigit(charCode) && !_isCjkChar(charCode);
}

WordCountResult _fastAsciiWordCount(String text, WordCountConfig config) {
  // Optimized ASCII-only word counting using simple splitting
  // This mimics the performance of split() while maintaining compatibility

  String processedText = text;

  // Handle punctuation according to config
  if (config.punctuationAsBreaker) {
    // Replace punctuation with spaces
    for (final punct in defaultPunctuation) {
      processedText = processedText.replaceAll(punct, ' ');
    }
  } else {
    // Remove punctuation
    for (final punct in defaultPunctuation) {
      processedText = processedText.replaceAll(punct, '');
    }
  }

  // Split on whitespace and filter empty words
  final words = processedText
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();

  return WordCountResult(words: words, count: words.length);
}

/// Default punctuation characters from multiple languages.
///
/// Includes punctuation from Latin, CJK, and other writing systems:
/// - Basic punctuation: comma, period, colon, semicolon
/// - Brackets and quotes: (), [], {}, "", ''
/// - CJK punctuation: 、，。：；【】《》
/// - Currency and symbols: $, ￥, *, /, \, &, %, @, #, ^
/// - Word separators: apostrophe ('), hyphen (-)
///
/// These characters are converted to spaces by default (when
/// [WordCountConfig.punctuationAsBreaker] is true), or removed when false.
const List<String> defaultPunctuation = [
  ',',
  '，',
  '.',
  '。',
  ':',
  '：',
  ';',
  '；',
  '[',
  ']',
  '【',
  ']',
  '】',
  '{',
  '｛',
  '}',
  '｝',
  '(',
  '（',
  ')',
  '）',
  '<',
  '《',
  '>',
  '》',
  '\$',
  '￥',
  '!',
  '！',
  '?',
  '？',
  '~',
  '～',
  "'",
  "'",
  '"',
  '"',
  '"',
  '*',
  '/',
  '\\',
  '&',
  '%',
  '@',
  '#',
  '^',
  '-', // Added hyphen to default punctuation
  '、',
  '、',
  '、',
  '、',
];

/// Configuration options for word counting behavior.
///
/// Controls how punctuation is handled during word counting and allows
/// customization of the punctuation character set.
///
/// Example:
/// ```dart
/// // Default behavior (punctuation is removed)
/// wordsCount("don't"); // Returns 1 (["dont"])
/// wordsCount("multi-word"); // Returns 1 (["multiword"])
///
/// // Split on punctuation instead of removing
/// const config1 = WordCountConfig(punctuationAsBreaker: true);
/// wordsCount("don't", config1); // Returns 2 (["don", "t"])
///
/// // Add custom punctuation
/// const config2 = WordCountConfig(punctuation: ['_']);
/// wordsCount('under_score', config2); // Returns 1 (["underscore"])
///
/// // Use only custom punctuation
/// const config3 = WordCountConfig(
///   punctuation: ['_'],
///   disableDefaultPunctuation: true
/// );
/// wordsCount("don't_test", config3); // Returns 2 (["don't", "test"])
/// ```
class WordCountConfig {
  /// Whether to treat punctuation as word separators instead of removing them.
  ///
  /// When `false` (default), punctuation is simply removed, allowing contractions
  /// to be treated as single words. When `true`, punctuation creates word boundaries.
  ///
  /// Examples:
  /// - `false`: "don't" → ["dont"] (1 word)
  /// - `true`: "don't" → ["don", "t"] (2 words)
  final bool punctuationAsBreaker;

  /// Whether to disable the default punctuation list.
  ///
  /// When `true`, only characters specified in [punctuation] are treated as
  /// punctuation. When `false`, [punctuation] is added to [defaultPunctuation].
  final bool disableDefaultPunctuation;

  /// Custom punctuation characters to use in addition to or instead of defaults.
  ///
  /// These characters will be processed according to [punctuationAsBreaker].
  /// If [disableDefaultPunctuation] is `true`, only these characters are
  /// treated as punctuation.
  final List<String> punctuation;

  /// Creates a new word count configuration.
  const WordCountConfig({
    this.punctuationAsBreaker =
        false, // Default: punctuation is removed, not used as breaker
    this.disableDefaultPunctuation = false,
    this.punctuation = const [],
  });
}

/// Result object containing both word count and word array.
///
/// Returned by [wordsDetect] to provide both pieces of information
/// in a single function call.
///
/// Example:
/// ```dart
/// WordCountResult result = wordsDetect('Hello World');
/// print('Found ${result.count} words: ${result.words}');
/// // Output: Found 2 words: [Hello, World]
/// ```
class WordCountResult {
  /// The array of words found in the text.
  ///
  /// Words are extracted according to the language-specific rules and
  /// configuration options provided.
  final List<String> words;

  /// The total number of words found.
  ///
  /// This is always equal to `words.length`.
  final int count;

  /// Creates a new word count result.
  const WordCountResult({required this.words, required this.count});
}

/// Predefined empty result for null or empty text inputs.
const WordCountResult emptyResult = WordCountResult(words: [], count: 0);

/// Detects and counts words in text, returning both count and word array.
///
/// This is the core function that performs word detection and counting for
/// 85+ languages including CJK (Chinese, Japanese, Korean), European, South
/// Asian, African, and Middle Eastern languages.
///
/// The function handles different writing systems appropriately:
/// - CJK languages: Character-level tokenization
/// - European languages: Space-separated word tokenization
/// - Mixed text: Proper handling of multilingual content
///
/// Returns [emptyResult] for null, empty, or whitespace-only text.
///
/// Example:
/// ```dart
/// // Basic usage
/// WordCountResult result = wordsDetect('Hello World');
/// print('${result.count} words: ${result.words}'); // 2 words: [Hello, World]
///
/// // Chinese text
/// WordCountResult chinese = wordsDetect('你好世界');
/// print('${chinese.count} words: ${chinese.words}'); // 4 words: [你, 好, 世, 界]
///
/// // With configuration
/// const config = WordCountConfig(punctuationAsBreaker: true);
/// WordCountResult result2 = wordsDetect("don't", config);
/// print('${result2.count} words: ${result2.words}'); // 2 words: [don, t]
/// ```
WordCountResult wordsDetect(
  String? text, [
  WordCountConfig config = const WordCountConfig(),
]) {
  if (text == null || text.isEmpty) return emptyResult;
  if (text.trim().isEmpty) return emptyResult;

  // Initialize bitmap if not already done
  _initializeBitmap();

  // Pre-compute punctuation lookup for custom punctuation
  final customPunctuationSet = <int>{};
  final defaultPunctuationSet = <int>{};

  if (!config.disableDefaultPunctuation) {
    for (final punct in defaultPunctuation) {
      if (punct.isNotEmpty) {
        defaultPunctuationSet.add(punct.codeUnitAt(0));
      }
    }
  }

  for (final punct in config.punctuation) {
    if (punct.isNotEmpty) {
      customPunctuationSet.add(punct.codeUnitAt(0));
    }
  }

  // Check for ASCII-only fast path optimization
  bool isAsciiOnly = true;
  for (int i = 0; i < text.length && isAsciiOnly; i++) {
    if (text.codeUnitAt(i) > 127) {
      isAsciiOnly = false;
    }
  }

  if (isAsciiOnly &&
      config.disableDefaultPunctuation == false &&
      config.punctuation.isEmpty) {
    // Fast path for ASCII-only text with default configuration
    return _fastAsciiWordCount(text, config);
  }

  // Single-pass algorithm with state machine
  final words = <String>[];
  final wordBuffer = StringBuffer();
  int wordCount = 0;
  bool inWord = false;

  for (int i = 0; i < text.length; i++) {
    final charCode = text.codeUnitAt(i);
    bool isBoundary = false;
    bool isCjk = false;

    // Check if character is a boundary using bitmap
    if (charCode < _maxCodePoint) {
      isBoundary = _isBoundaryChar(charCode);
      isCjk = _isCjkChar(charCode);
    }

    // Check custom punctuation
    final isCustomPunctuation =
        customPunctuationSet.contains(charCode) ||
        defaultPunctuationSet.contains(charCode);

    if (isCustomPunctuation) {
      if (config.punctuationAsBreaker) {
        // Treat punctuation as word boundary
        if (inWord && wordBuffer.isNotEmpty) {
          words.add(wordBuffer.toString());
          wordBuffer.clear();
          wordCount++;
          inWord = false;
        }
      }
      // Skip punctuation character (either remove it or it acts as boundary)
      continue;
    }

    // Handle Unicode symbols (similar to original logic)
    if (charCode >= 0xFF00 && charCode <= 0xFFEF ||
        charCode >= 0x2000 && charCode <= 0x206F) {
      if (inWord && wordBuffer.isNotEmpty) {
        words.add(wordBuffer.toString());
        wordBuffer.clear();
        wordCount++;
        inWord = false;
      }
      continue;
    }

    // Handle CJK characters (each character is a word)
    if (isCjk) {
      // End current word if any
      if (inWord && wordBuffer.isNotEmpty) {
        words.add(wordBuffer.toString());
        wordBuffer.clear();
        wordCount++;
      }
      // Add CJK character as individual word
      words.add(String.fromCharCode(charCode));
      wordCount++;
      inWord = false;
      continue;
    }

    // Handle regular word boundaries (spaces, tabs, etc.)
    if (isBoundary) {
      if (inWord && wordBuffer.isNotEmpty) {
        words.add(wordBuffer.toString());
        wordBuffer.clear();
        wordCount++;
        inWord = false;
      }
      continue;
    }

    // For characters that are not CJK, not configured punctuation, and not basic boundaries,
    // we need to determine if they should be word characters or boundaries
    // This handles the case where only specific punctuation is configured
    if (!isCjk && !isCustomPunctuation && !isBoundary) {
      // Check if this character would be treated as punctuation in the original RegExp approach
      final isNonWordChar = _isNonWordCharacter(charCode);

      if (isNonWordChar && !_isLetterOrDigit(charCode)) {
        // This is a character that would split words in the original implementation
        if (inWord && wordBuffer.isNotEmpty) {
          words.add(wordBuffer.toString());
          wordBuffer.clear();
          wordCount++;
          inWord = false;
        }
        continue;
      }
    }

    // Regular character - add to current word
    wordBuffer.writeCharCode(charCode);
    inWord = true;
  }

  // Handle final word
  if (inWord && wordBuffer.isNotEmpty) {
    words.add(wordBuffer.toString());
    wordCount++;
  }

  return WordCountResult(words: words, count: wordCount);
}

/// Counts words in text and returns the count as an integer.
///
/// This is a convenience function that calls [wordsDetect] and returns only
/// the word count. Use this when you only need the number of words.
///
/// Supports 85+ languages with proper handling for different writing systems.
/// Returns 0 for null, empty, or whitespace-only text.
///
/// Example:
/// ```dart
/// int count = wordsCount('Hello World'); // 2
/// int chinese = wordsCount('你好世界'); // 4
/// int mixed = wordsCount('Hello, 你好!'); // 3
///
/// // With configuration
/// const config = WordCountConfig(punctuationAsBreaker: true);
/// int count2 = wordsCount("don't", config); // 2
/// ```
int wordsCount(
  String? text, [
  WordCountConfig config = const WordCountConfig(),
]) {
  final result = wordsDetect(text, config);
  return result.count;
}

/// Splits text into words and returns them as a list of strings.
///
/// This is a convenience function that calls [wordsDetect] and returns only
/// the word array. Use this when you need access to the individual words.
///
/// Supports 85+ languages with proper handling for different writing systems.
/// Returns an empty list for null, empty, or whitespace-only text.
///
/// Example:
/// ```dart
/// List<String> words = wordsSplit('Hello World'); // ['Hello', 'World']
/// List<String> chinese = wordsSplit('你好世界'); // ['你', '好', '世', '界']
/// List<String> mixed = wordsSplit('Hello, 你好!'); // ['Hello', '你', '好']
///
/// // With configuration
/// const config = WordCountConfig(punctuationAsBreaker: true);
/// List<String> words2 = wordsSplit("don't", config); // ['don', 't']
/// ```
List<String> wordsSplit(
  String? text, [
  WordCountConfig config = const WordCountConfig(),
]) {
  final result = wordsDetect(text, config);
  return result.words;
}
