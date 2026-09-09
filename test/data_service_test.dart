import 'package:flutter_test/flutter_test.dart';
import 'package:lmb_plusur/models/equipo_model.dart';
import 'package:lmb_plusur/models/video_archivo.dart';
import 'package:lmb_plusur/services/data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DataService carga los 10 equipos de Zona Sur', () async {
    final equipos = await DataService().cargarEquipos();
    expect(equipos, hasLength(10));
    expect(equipos.every((e) => e.nombre.isNotEmpty), isTrue);
    expect(equipos.any((e) => e.id == 'diablos_rojos'), isTrue);
    expect(
      equipos.firstWhere((e) => e.id == 'guerreros_oaxaca').trivias,
      isNotEmpty,
    );
  });

  test('Equipo.fromJson mapea campos españoles', () {
    final equipo = Equipo.fromJson({
      'id': 'demo',
      'nombre': 'Demo FC',
      'historia': 'Historia de prueba',
      'fundacion': 2000,
      'trivias': [
        {
          'id': 1,
          'pregunta': '¿Año?',
          'opciones': ['2000', '2001'],
          'respuestaCorrecta': 0,
        },
      ],
    });

    expect(equipo.id, 'demo');
    expect(equipo.fundacion, 2000);
    expect(equipo.trivias.single.respuestaCorrecta, 0);
  });

  test('VideoArchivo.fromJson mapea el catálogo en español', () {
    final video = VideoArchivo.fromJson({
      'id': 'video_demo',
      'titulo': 'Jonrón de muestra',
      'descripcion': 'Clip del archivo.',
      'url': 'https://example.com/clip.mp4',
      'equipoId': 'leones_yucatan',
    });

    expect(video.titulo, 'Jonrón de muestra');
    expect(video.url, 'https://example.com/clip.mp4');
    expect(video.equipoId, 'leones_yucatan');
  });

  test('DataService carga el archivo de videos local', () async {
    final videos = await DataService().cargarVideos();

    expect(videos, isNotEmpty);
    expect(videos.every((v) => v.titulo.isNotEmpty && v.url.startsWith('https://')), isTrue);
    expect(videos.any((v) => v.equipoId == null), isTrue);
    expect(videos.any((v) => v.equipoId == 'leones_yucatan'), isTrue);
  });
}
