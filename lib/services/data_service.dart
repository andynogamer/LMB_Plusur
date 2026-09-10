import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/equipo_model.dart';
import '../models/marcador_model.dart';
import '../models/video_archivo.dart';

class DataService {
  static List<Equipo>? _equipos;
  static List<VideoArchivo>? _videos;
  static List<Marcador>? _marcadores;

  Future<List<Equipo>> cargarEquipos() async {
    final cached = _equipos;
    if (cached != null) return cached;
    try {
      final String jsonString = await rootBundle.loadString('assets/data.json');
      final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
      final list = decoded
          .map((item) => Equipo.fromJson(item as Map<String, dynamic>))
          .toList();
      _equipos = list;
      return list;
    } catch (e) {
      // ignore: avoid_print
      print('Error al cargar equipos: $e');
      return [];
    }
  }

  /// Local video archive. Metadata stays on device; playback uses [VideoArchivo.url].
  Future<List<VideoArchivo>> cargarVideos() async {
    final cached = _videos;
    if (cached != null) return cached;
    try {
      final String jsonString = await rootBundle.loadString('assets/videos.json');
      final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
      final list = decoded
          .map((item) => VideoArchivo.fromJson(item as Map<String, dynamic>))
          .toList();
      _videos = list;
      return list;
    } catch (e) {
      // ignore: avoid_print
      print('Error al cargar videos: $e');
      return [];
    }
  }

  /// Loads the active D-20 markers. The printable spare is not in this file.
  Future<List<Marcador>> cargarMarcadores() async {
    final cached = _marcadores;
    if (cached != null) return cached;
    try {
      final String jsonString =
          await rootBundle.loadString('assets/ar_markers.json');
      final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
      final list = decoded
          .map((item) => Marcador.fromJson(item as Map<String, dynamic>))
          .toList();
      _marcadores = list;
      return list;
    } catch (e) {
      // ignore: avoid_print
      print('Error al cargar marcadores: $e');
      return [];
    }
  }
}
