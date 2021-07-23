import 'dart:async';

import 'package:flutter/services.dart';
import 'package:google_speech/google_speech.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sound_stream/sound_stream.dart';
import 'package:logging/logging.dart';


class AudioRecognize {
  final Logger log = new Logger('Speech_To_Text') ;
  final RecorderStream _recorder = RecorderStream();
  String keyContext;
  bool is_recognized = false ; // it is done recognizing or not
  String text = '';
  StreamSubscription<List<int>> _audioStreamSubscription;
  BehaviorSubject<List<int>> _audioStream;

  void streamingRecognize() async {
    // initializing recorder
    await _recorder.initialize();

    _audioStream = BehaviorSubject<List<int>>();
    _audioStreamSubscription = _recorder.audioStream.listen((event) {
      _audioStream.add(event);
    });


    await _recorder.start();

    final serviceAccount = ServiceAccount.fromString(
        '${(await rootBundle.loadString('assets/speech_to_text.json'))}');
    final speechToText = SpeechToText.viaServiceAccount(serviceAccount);
    final config = _getConfig();

    final responseStream =  speechToText.streamingRecognize(
        StreamingRecognitionConfig(config: config, interimResults: true),
        _audioStream);

    responseStream.listen((data) {
      text =
          data.results.map((e) => e.alternatives.first.transcript).join('\n');
    }, onDone: () {
      is_recognized = true ;
    });
  }

  Future stopRecording() async {
    is_recognized = false ;
    await _recorder.stop();
    await _audioStreamSubscription?.cancel();
    await _audioStream?.close();
  }

  RecognitionConfig _getConfig() => RecognitionConfig(
      encoding: AudioEncoding.LINEAR16,
      model: RecognitionModel.basic,
      enableAutomaticPunctuation: true,
      sampleRateHertz: 16000,
      languageCode: 'ar-EG');

  AudioRecognize(this.keyContext);

  String getText() {
    return text ;
  }
}
