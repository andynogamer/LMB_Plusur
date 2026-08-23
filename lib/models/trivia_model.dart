class Trivia {
  const Trivia({
    required this.id,
    required this.pregunta,
    required this.opciones,
    required this.respuestaCorrecta,
  });

  final int id;
  final String pregunta;
  final List<String> opciones;
  final int respuestaCorrecta;

  factory Trivia.fromJson(Map<String, dynamic> json) {
    return Trivia(
      id: json['id'] as int,
      pregunta: json['pregunta'] as String,
      opciones: (json['opciones'] as List<dynamic>).cast<String>(),
      respuestaCorrecta: json['respuestaCorrecta'] as int,
    );
  }
}
