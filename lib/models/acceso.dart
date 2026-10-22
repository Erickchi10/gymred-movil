/// Respuesta de POST /api/movil/acceso
class ResultadoAcceso {
  final bool permitido;
  final String? motivo;
  final String? cliente;
  final String? gimnasio;
  final String? plan;
  final int? visitasRestantesHoy;

  ResultadoAcceso({
    required this.permitido,
    this.motivo,
    this.cliente,
    this.gimnasio,
    this.plan,
    this.visitasRestantesHoy,
  });

  factory ResultadoAcceso.fromJson(Map<String, dynamic> json) => ResultadoAcceso(
        permitido: json['permitido'] == true,
        motivo: json['motivo'] as String?,
        cliente: json['cliente'] as String?,
        gimnasio: json['gimnasio'] as String?,
        plan: json['plan'] as String?,
        visitasRestantesHoy: json['visitasRestantesHoy'] == null
            ? null
            : int.tryParse('${json['visitasRestantesHoy']}'),
      );
}
