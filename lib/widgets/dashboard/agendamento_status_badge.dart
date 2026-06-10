import 'package:flutter/material.dart';
import '../../models/agendamento.dart';

class AgendamentoStatusBadge extends StatelessWidget {
  final AgendamentoStatus status;

  const AgendamentoStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Color(status.bgColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
          color: Color(status.textColor),
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}