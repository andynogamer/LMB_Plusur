import '../models/highlight.dart';
import '../models/team.dart';
import '../models/trivia_question.dart';

abstract final class MockData {
  static const String historyPlaceholder = '''
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor
incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis
nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.

Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu
fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
culpa qui officia deserunt mollit anim id est laborum.

Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac
turpis egestas. Vestibulum tortor quam, feugiat vitae, ultricies eget, tempor
sit amet, ante. Donec eu libero sit amet quam egestas semper.
''';

  static const List<TriviaQuestion> defaultTrivia = [
    TriviaQuestion(
      prompt: '¿En qué año fue fundado el equipo?',
      options: ['1996', '2004', '1826', '2010'],
    ),
    TriviaQuestion(
      prompt: '¿En qué estadio juega de local?',
      options: [
        'Estadio Eduardo Vasconcelos',
        'Estadio de Béisbol Monterrey',
        'Parque Kukulcán Alamo',
        'Estadio Fray Nano',
      ],
    ),
    TriviaQuestion(
      prompt: '¿A qué zona de la LMB pertenece?',
      options: ['Zona Sur', 'Zona Norte', 'Zona Centro', 'Zona Pacífico'],
    ),
  ];

  static const List<Highlight> defaultHighlights = [
    Highlight(title: 'HOME RUN!!!'),
    Highlight(title: 'SAFE!!!'),
    Highlight(title: 'PONCHE CLAVE'),
  ];

  static const Team guerrerosOaxaca = Team(
    id: 'guerreros_oaxaca',
    name: 'Guerreros de Oaxaca',
    city: 'Oaxaca',
    history: historyPlaceholder,
    triviaQuestions: defaultTrivia,
    highlights: defaultHighlights,
  );

  static const List<Team> zonaSur = [
    guerrerosOaxaca,
    Team(
      id: 'diablos_mexico',
      name: 'Diablos Rojos del México',
      city: 'Ciudad de México',
      history: historyPlaceholder,
      triviaQuestions: defaultTrivia,
      highlights: defaultHighlights,
    ),
    Team(
      id: 'leones_yucatan',
      name: 'Leones de Yucatán',
      city: 'Mérida',
      history: historyPlaceholder,
      triviaQuestions: defaultTrivia,
      highlights: defaultHighlights,
    ),
    Team(
      id: 'olmecas_tabasco',
      name: 'Olmecas de Tabasco',
      city: 'Villahermosa',
      history: historyPlaceholder,
      triviaQuestions: defaultTrivia,
      highlights: defaultHighlights,
    ),
    Team(
      id: 'pericos_puebla',
      name: 'Pericos de Puebla',
      city: 'Puebla',
      history: historyPlaceholder,
      triviaQuestions: defaultTrivia,
      highlights: defaultHighlights,
    ),
    Team(
      id: 'piratas_campeche',
      name: 'Piratas de Campeche',
      city: 'Campeche',
      history: historyPlaceholder,
      triviaQuestions: defaultTrivia,
      highlights: defaultHighlights,
    ),
    Team(
      id: 'aguila_veracruz',
      name: 'El Águila de Veracruz',
      city: 'Veracruz',
      history: historyPlaceholder,
      triviaQuestions: defaultTrivia,
      highlights: defaultHighlights,
    ),
    Team(
      id: 'tigres_quintana_roo',
      name: 'Tigres de Quintana Roo',
      city: 'Cancún',
      history: historyPlaceholder,
      triviaQuestions: defaultTrivia,
      highlights: defaultHighlights,
    ),
  ];

  static Team byId(String id) {
    return zonaSur.firstWhere(
      (team) => team.id == id,
      orElse: () => guerrerosOaxaca,
    );
  }
}
