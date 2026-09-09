import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/feedback_service.dart';
import '../services/filter_engine.dart';
import '../theme/app_colors.dart';

class FiltrosPartido extends StatelessWidget {
  const FiltrosPartido({
    super.key,
    required this.seleccionado,
    required this.onChanged,
  });

  final FiltroPartido seleccionado;
  final ValueChanged<FiltroPartido> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filtros del partido',
          style: GoogleFonts.poppins(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        _fila([FiltroPartido.ninguno, ...FilterEngine.familias]),
        const SizedBox(height: 10),
        Text(
          'Personalizados',
          style: GoogleFonts.poppins(
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        _fila(FilterEngine.personalizados),
      ],
    );
  }

  Widget _fila(List<FiltroPartido> filtros) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final filtro in filtros)
          _Chip(
            label: FilterEngine.etiqueta(filtro),
            selected: filtro == seleccionado,
            onTap: () {
              FeedbackService.instance.tap();
              onChanged(filtro);
            },
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.button : AppColors.navyCard,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: selected ? AppColors.navy : AppColors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
