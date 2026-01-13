import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/foundation.dart';

class VoiceCommandService {
  static final VoiceCommandService instance = VoiceCommandService._();
  VoiceCommandService._();

  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speechToText.initialize(
        onStatus: (status) => debugPrint('Voice status: $status'),
        onError: (error) => debugPrint('Voice error: $error'),
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('Failed to initialize speech recognition: $e');
      return false;
    }
  }

  Future<void> startListening({
    required Function(String) onCommand,
    List<String> triggers = const ['clip this', 'save clip', 'clip that'],
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    if (_isListening) return;

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            final recognizedWords = result.recognizedWords.toLowerCase();
            debugPrint('Voice recognized: $recognizedWords');

            for (final trigger in triggers) {
              if (recognizedWords.contains(trigger)) {
                onCommand(trigger);
                break;
              }
            }
          }
        },
        listenMode: ListenMode.dictation,
        cancelOnError: false,
        partialResults: false,
        listenFor: const Duration(minutes: 10),
      );
      _isListening = true;
    } catch (e) {
      debugPrint('Failed to start listening: $e');
      _isListening = false;
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
    } catch (e) {
      debugPrint('Failed to stop listening: $e');
    }
  }

  Future<bool> checkPermission() async {
    return await _speechToText.hasPermission;
  }

  void dispose() {
    _speechToText.cancel();
    _isListening = false;
  }
}
