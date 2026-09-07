import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/equipo_model.dart';
import '../models/marcador_model.dart';

class DataService {
  Future<List<Equipo>> cargarEquipos() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data.json');
      final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
      return decoded
          .map((item) => Equipo.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error al cargar equipos: $e');
      return [];
    }
  }

  Future<List<Marcador>> cargarMarcadores() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/ar_markers.json');
      final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
      final marcadores = decoded
          .map((item) => Marcador.fromJson(item as Map<String, dynamic>))
          .toList();
      debugPrint(
        'AR marcadores cargados: ${marcadores.length} '
        '(${marcadores.map((m) => m.id).join(', ')})',
      );
      return marcadores;
    } catch (e) {
      debugPrint('Error al cargar marcadores: $e');
      return [];
    }
  }

  Future<Marcador?> marcadorPorId(String id) async {
    final marcadores = await cargarMarcadores();
    for (final marcador in marcadores) {
      if (marcador.id == id) return marcador;
    }
    return null;
  }

  Future<Marcador?> marcadorPorEquipoId(String equipoId) async {
    final marcadores = await cargarMarcadores();
    for (final marcador in marcadores) {
      if (marcador.equipoId == equipoId) return marcador;
    }
    return null;
  }
}
