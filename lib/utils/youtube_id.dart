/// Extracts a YouTube video id from a watch, share, or embed URL.
///
/// Returns null when [url] is not a YouTube link. Does not fetch anything.
String? youtubeVideoId(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || uri.host.isEmpty) return null;

  final host = uri.host.replaceFirst(RegExp(r'^www\.'), '');
  if (host == 'youtu.be') {
    if (uri.pathSegments.isEmpty) return null;
    return _idOrNull(uri.pathSegments.first);
  }
  if (host == 'youtube.com' || host == 'm.youtube.com' || host == 'music.youtube.com') {
    final v = uri.queryParameters['v'];
    if (v != null) return _idOrNull(v);
    final paths = uri.pathSegments;
    if (paths.length >= 2 && (paths.first == 'embed' || paths.first == 'shorts')) {
      return _idOrNull(paths[1]);
    }
  }
  return null;
}

String? _idOrNull(String value) {
  if (value.length == 11 && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value)) {
    return value;
  }
  return null;
}
