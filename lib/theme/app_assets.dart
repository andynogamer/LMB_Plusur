abstract final class AppAssets {
  static const String logo = 'assets/images/LMB_plusur.png';

  /// Maps stable [Equipo.id] values to bundled logo marker images (D-04).
  static const Map<String, String> teamLogoById = {
    'diablos_rojos':
        'assets/images/team-logos/diablos_rojos_mexico/logo_base.png',
    'bravos_leon': 'assets/images/team-logos/bravos_leon/bravos_leon.png',
    'conspiradores_queretaro':
        'assets/images/team-logos/conspiradores_queretaro/Logoconspiradores.png',
    'aguila_veracruz':
        'assets/images/team-logos/el_aguila_veracruz/logo_base.png',
    'guerreros_oaxaca':
        'assets/images/team-logos/guerreros_oaxaca/guerreros_oaxaca.png',
    'leones_yucatan':
        'assets/images/team-logos/leones_yucatan/logo_base.png',
    'olmecas_tabasco':
        'assets/images/team-logos/olmecas_tabasco/logo_base.png',
    'pericos_puebla':
        'assets/images/team-logos/pericos_puebla/pericos_puebla.png',
    'piratas_campeche':
        'assets/images/team-logos/piratas_campeche/logo_base.png',
    'tigres_quintana_roo':
        'assets/images/team-logos/tigres_quintana_roo/tigres_quintanaroo.jpg',
  };

  static String? logoForEquipo(String equipoId) => teamLogoById[equipoId];

  /// Unique AR tracking cards (logo + per-team feature pattern).
  /// Five clubs share `logo_base.png` in [teamLogoById], so those paths cannot
  /// be registered as tracking images without colliding.
  ///
  /// Scan these cards (print or another screen). Raw merch wordmarks look
  /// alike to ARCore and Guerreros (white on black) steals those matches.
  static const Map<String, String> trackingMarkerById = {
    'diablos_rojos': 'assets/markers/diablos_rojos.png',
    'bravos_leon': 'assets/markers/bravos_leon.png',
    'conspiradores_queretaro': 'assets/markers/conspiradores_queretaro.png',
    'aguila_veracruz': 'assets/markers/aguila_veracruz.png',
    'guerreros_oaxaca': 'assets/markers/guerreros_oaxaca.png',
    'leones_yucatan': 'assets/markers/leones_yucatan.png',
    'olmecas_tabasco': 'assets/markers/olmecas_tabasco.png',
    'pericos_puebla': 'assets/markers/pericos_puebla.png',
    'piratas_campeche': 'assets/markers/piratas_campeche.png',
    'tigres_quintana_roo': 'assets/markers/tigres_quintana_roo.png',
  };

  static List<String> get trackingImagePaths =>
      trackingMarkerById.values.toList(growable: false);

  static List<String> trackingImagePathsFor(String? equipoId) {
    if (equipoId == null) return trackingImagePaths;
    final path = trackingMarkerById[equipoId];
    if (path == null) return trackingImagePaths;
    return [path];
  }
}
