import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PreviewCacheService {
  static const _dirName = 'spotify_previews';

  Future<File> _fileFor(String trackId) async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/$_dirName');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return File('${cacheDir.path}/$trackId.mp3');
  }

  Future<File?> getOrDownload({
    required String trackId,
    required String? previewUrl,
  }) async {
    if (previewUrl == null) return null;

    final file = await _fileFor(trackId);
    if (await file.exists()) return file;

    final resp = await http.get(Uri.parse(previewUrl));
    if (resp.statusCode != 200) return null;

    await file.writeAsBytes(resp.bodyBytes, flush: true);
    return file;
  }
}
