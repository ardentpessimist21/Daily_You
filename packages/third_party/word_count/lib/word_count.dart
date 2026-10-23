/// A comprehensive multi-language word counting library for Dart.
///
/// This library provides word counting functionality for 85+ languages including
/// CJK (Chinese, Japanese, Korean), European, South Asian, African, and Middle
/// Eastern languages. It supports configurable punctuation handling and provides
/// multiple output formats.
///
/// ## Usage
///
/// Basic word counting:
/// ```dart
/// import 'package:word_count/word_count.dart';
///
/// int count = wordsCount('Hello World'); // 2
/// List<String> words = wordsSplit('Hello World'); // ['Hello', 'World']
/// WordCountResult result = wordsDetect('Hello World'); // count: 2, words: ['Hello', 'World']
/// ```
///
/// With configuration:
/// ```dart
/// const config = WordCountConfig(punctuationAsBreaker: true);
/// wordsCount("don't", config); // 2
/// ```
library;

export 'src/word_count_base.dart';
