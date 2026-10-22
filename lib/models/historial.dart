class ItemHistorial {
  final DateTime fecha;
  final bool permitido;
  final String? motivo;
  final String gimnasio;

  const ItemHistorial({
    required this.fecha,
    required this.permitido,
    this.motivo,
    required this.gimnasio,
  });

  factory ItemHistorial.fromJson(Map<String, dynamic> json) {
    final fechaTexto = '${json['registrado_en'] ?? ''}';
    return ItemHistorial(
      fecha: (DateTime.tryParse(fechaTexto) ?? DateTime.now()).toLocal(),
      permitido: json['resultado'] == 'permitido',
      motivo: json['motivo'] as String?,
      gimnasio: '${json['gimnasio'] ?? 'Gimnasio'}',
    );
  }
}

