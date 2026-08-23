import 'highlight.dart';
import 'trivia_question.dart';

class Team {
  const Team({
    required this.id,
    required this.name,
    required this.city,
    required this.history,
    required this.triviaQuestions,
    required this.highlights,
  });

  final String id;
  final String name;
  final String city;
  final String history;
  final List<TriviaQuestion> triviaQuestions;
  final List<Highlight> highlights;

  String get displayName => name.toUpperCase();
}
