import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipo_model.dart';
import '../routes/app_routes.dart';
import '../services/data_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../utils/text_normalize.dart';
import '../widgets/screen_background.dart';

class TeamListScreen extends StatefulWidget {
  const TeamListScreen({super.key});

  @override
  State<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends State<TeamListScreen> {
  final DataService _dataService = DataService();
  final TextEditingController _searchController = TextEditingController();
  late final Future<List<Equipo>> _equiposFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _equiposFuture = _dataService.cargarEquipos();
    _searchController.addListener(() {
      final next = _searchController.text;
      if (next == _query) return;
      setState(() => _query = next);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Equipo> _filtrar(List<Equipo> equipos) {
    final needle = normalizeSearchText(_query);
    if (needle.isEmpty) return equipos;
    return equipos
        .where((equipo) => normalizeSearchText(equipo.nombre).contains(needle))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBackground(
        child: Column(
          children: [
            const AppHeader(
              title: 'Zona Sur',
              subtitle: '10 equipos · temporada actual',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: _TeamSearchField(controller: _searchController),
            ),
            Expanded(
              child: FutureBuilder<List<Equipo>>(
                future: _equiposFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.button),
                    );
                  }

                  final equipos = snapshot.data ?? [];
                  if (equipos.isEmpty) {
                    return Center(
                      child: Text(
                        'No se pudieron cargar los equipos.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: AppColors.white),
                      ),
                    );
                  }

                  final filtrados = _filtrar(equipos);
                  if (filtrados.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Ningún equipo coincide con “$_query”.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    itemCount: filtrados.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final equipo = filtrados[index];
                      final originalIndex = equipos.indexOf(equipo) + 1;
                      return _EquipoTile(
                        index: originalIndex,
                        equipo: equipo,
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.teamMenu,
                            arguments: equipo,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamSearchField extends StatelessWidget {
  const _TeamSearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: GoogleFonts.poppins(
        color: AppColors.white,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      cursorColor: AppColors.button,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar equipo por nombre…',
        hintStyle: GoogleFonts.poppins(
          color: AppColors.muted,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.muted,
        ),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'Limpiar búsqueda',
              onPressed: controller.clear,
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.muted,
              ),
            );
          },
        ),
        filled: true,
        fillColor: AppColors.navyCard.withValues(alpha: 0.85),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.button.withValues(alpha: 0.12),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.button.withValues(alpha: 0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.button.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

class _EquipoTile extends StatelessWidget {
  const _EquipoTile({
    required this.index,
    required this.equipo,
    required this.onTap,
  });

  final int index;
  final Equipo equipo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.button,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.navy,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$index',
                  style: GoogleFonts.poppins(
                    color: AppColors.button,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipo.displayName,
                      style: GoogleFonts.poppins(
                        color: AppColors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.navy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'Desde ${equipo.fundacion}',
                        style: GoogleFonts.poppins(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: AppColors.navy),
            ],
          ),
        ),
      ),
    );
  }
}
