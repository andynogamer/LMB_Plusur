import '../theme/app_assets.dart';

/// Maps ARCore/ARKit detected image names to stable [Equipo.id] values.
///
/// `ar_flutter_plugin_plus` registers each asset as
/// `path.substringAfterLast("/").substringBeforeLast(".")`, so tracking files
/// in `assets/markers/` are named `{equipoId}.png`.
class MarkerIdMapper {
  static String? equipoIdFromImageName(String imageName) {
    final lower = imageName.replaceAll('\\', '/').toLowerCase();
    final file = lower.split('/').last;
    final stem = file.contains('.')
        ? file.substring(0, file.lastIndexOf('.'))
        : file;

    if (AppAssets.trackingMarkerById.containsKey(stem)) return stem;
    if (AppAssets.teamLogoById.containsKey(stem)) return stem;

    for (final entry in AppAssets.trackingMarkerById.entries) {
      if (lower.endsWith(entry.value.toLowerCase())) return entry.key;
    }
    for (final entry in AppAssets.teamLogoById.entries) {
      if (lower.endsWith(entry.value.toLowerCase())) return entry.key;
    }
    return null;
  }
}
