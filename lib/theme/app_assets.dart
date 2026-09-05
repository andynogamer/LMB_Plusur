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
}
