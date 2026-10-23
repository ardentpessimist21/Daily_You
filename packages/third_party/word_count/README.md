# word_count

Fastest multi-language word counting library (8.0 million words/s) for Dart that supports 85+ languages including CJK (Chinese, Japanese, Korean), European, South Asian, African, and Middle Eastern languages.

## Features

- **Multi-language support**: Count words in 85+ languages with proper handling for different writing systems
- **CJK language support**: Proper tokenization for Chinese, Japanese, and Korean text
- **Configurable punctuation**: Choose to treat punctuation as word separators or remove them entirely
- **Custom punctuation**: Add your own punctuation characters or disable defaults
- **Multiple output formats**: Get word count, word array, or both
- **Comprehensive testing**: 118+ tests covering all supported languages and edge cases

## Performance

| Method | Words/s | GB/s | Relative Speed |
|--------|---------|------|----------------|
| New Implementation (Bitmap) | 8.0M | 0.044 | 1.0x |
| Old Implementation (RegExp) | 0.5M | 0.003 | 0.06x |
| Regex | 9.7M | 0.053 | 1.21x |
| Split | 20.9M | 0.115 | 2.61x |
| StringStats | 2.2M | 0.012 | 0.27x |

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  word_count: ^1.0.0
```

Then run:
```bash
dart pub get
```

## Usage

### Basic Usage

```dart
import 'package:word_count/word_count.dart';

// Count words (returns int)
int count = wordsCount('Hello World'); // 2
int chineseCount = wordsCount('你好，世界'); // 4
int mixedCount = wordsCount('Hello, 你好。'); // 3

// Get word array (returns List<String>)
List<String> words = wordsSplit('Hello World'); // ['Hello', 'World']

// Get both count and words (returns WordCountResult)
WordCountResult result = wordsDetect('Hello World');
print('Count: ${result.count}'); // Count: 2
print('Words: ${result.words}'); // Words: [Hello, World]
```

### Configuration Options

```dart
// Treat punctuation as word separators instead of removing them
const config1 = WordCountConfig(punctuationAsBreaker: true);
wordsCount("don't", config1); // 2 words: ['don', 't']

// Add custom punctuation
const config2 = WordCountConfig(punctuation: ['-']);
wordsCount('multi-word', config2); // 1 word: ['multiword']

// Use only custom punctuation (disable defaults)
const config3 = WordCountConfig(
  punctuation: ['-'], 
  disableDefaultPunctuation: true
);
wordsCount("multi-word text!", config3); // 2 words: ['multiword', 'text!']
```

## Supported Languages

The library supports proper word counting for:

- **East Asian**: Chinese (Simplified/Traditional), Japanese (Hiragana, Katakana, Kanji), Korean
- **European**: English, French, German, Spanish, Italian, Russian, Polish, Dutch, and 40+ more
- **South Asian**: Hindi, Bengali, Urdu, Telugu, Tamil, Gujarati, Punjabi, and more
- **Southeast Asian**: Thai, Vietnamese, Indonesian, Malay, Filipino
- **Middle Eastern**: Arabic, Hebrew, Persian, Turkish, Kurdish
- **African**: Swahili, Amharic, Yoruba, Hausa, Igbo, and more
- **Other**: Armenian, Georgian, Estonian, Welsh, Irish, and many more

## API Reference

### Functions

- `wordsCount(String? text, [WordCountConfig config])` → `int`
  - Returns the word count for the given text
  
- `wordsSplit(String? text, [WordCountConfig config])` → `List<String>`
  - Returns an array of words from the given text
  
- `wordsDetect(String? text, [WordCountConfig config])` → `WordCountResult`
  - Returns both word count and word array in a structured result

### Classes

- `WordCountConfig` - Configuration options for word counting behavior
- `WordCountResult` - Result object containing both count and words array

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.