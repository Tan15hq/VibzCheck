import 'dart:io';
import 'package:just_audio/just_audio.dart';

class PreviewPlayerService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playFile(
    File file, {
    Function()? onComplete,
  }) async {
    await _player.setFilePath(file.path);
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        onComplete?.call();
      }
    });
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
