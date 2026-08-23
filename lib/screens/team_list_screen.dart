import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipo_model.dart';
import '../routes/app_routes.dart';
import '../services/data_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';

class TeamListScreen extends StatefulWidget {
  const TeamListScreen({super.key});

  @override
  State<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends State<TeamListScreen> {
  final DataService _dataService = DataService();
  late final Future<List<Equipo>> _equiposFuture;

  @override
  void initState() {
    super.initState();
    _equiposFuture = _dataService.cargarEquipos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Column(
        children: [
          const AppHeader(title: 'Zona Sur'),
          Expanded(
            child: FutureBuilder<List<Equipo>>(
              future: _equiposFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.white),
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

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: equipos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final equipo = equipos[index];
                    return _EquipoTile(
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
    );
  }
}

class _EquipoTile extends StatelessWidget {
  const _EquipoTile({
    required this.equipo,
    required this.onTap,
  });

  final Equipo equipo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.button,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipo.displayName,
                      style: GoogleFonts.poppins(
                        color: AppColors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Fundado en ${equipo.fundacion}',
                      style: GoogleFonts.poppins(
                        color: const Color(0xA6111111),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.black),
            ],
          ),
        ),
      ),
    );
  }
}
