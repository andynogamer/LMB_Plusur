class TriviaQuestion {
  const TriviaQuestion({
    required this.prompt,
    required this.options,
  });

  final String prompt;
  final List<String> options;
}
