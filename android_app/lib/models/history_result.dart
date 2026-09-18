class HistoryResult {
  const HistoryResult({
    this.id,
    required this.date,
    this.weekday,
    required this.draw,
    required this.time,
    required this.prize,
    required this.thousand,
    required this.hundred,
    required this.ten,
    required this.group,
    required this.animal,
    this.source,
    this.publishedGroup,
    this.publishedAnimal,
  });

  final int? id;
  final String date;
  final String? weekday;
  final String draw;
  final String time;
  final int prize;
  final String thousand;
  final String hundred;
  final String ten;
  final int group;
  final String animal;
  final String? source;
  final int? publishedGroup;
  final String? publishedAnimal;

  factory HistoryResult.fromMap(Map<String, Object?> map) {
    return HistoryResult(
      id: map['id'] as int?,
      date: map['data'] as String,
      weekday: map['dia_semana'] as String?,
      draw: map['sorteio'] as String,
      time: map['hora'] as String,
      prize: map['premio'] as int,
      thousand: map['milhar'] as String,
      hundred: map['centena'] as String,
      ten: map['dezena'] as String,
      group: map['grupo'] as int,
      animal: map['bicho'] as String,
      source: map['fonte'] as String?,
      publishedGroup: map['grupo_publicado'] as int?,
      publishedAnimal: map['bicho_publicado'] as String?,
    );
  }

  Map<String, Object?> toMap() => {
        'data': date,
        'dia_semana': weekday,
        'sorteio': draw,
        'hora': time,
        'premio': prize,
        'milhar': thousand,
        'centena': hundred,
        'dezena': ten,
        'grupo': group,
        'bicho': animal,
        'fonte': source,
        'grupo_publicado': publishedGroup,
        'bicho_publicado': publishedAnimal,
      };
}
