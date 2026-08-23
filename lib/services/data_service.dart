import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/equipo_model.dart';

class DataService {
  Future<List<Equipo>> cargarEquipos() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data.json');
      final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
      return decoded
          .map((item) => Equipo.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error al cargar equipos: $e');
      return [];
    }
  }
}
