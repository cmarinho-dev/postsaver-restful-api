/// Formata uma data como tempo relativo em português ("há 2 dias").
String relativeTime(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date.toLocal());

  if (diff.inSeconds < 60) return 'agora mesmo';
  if (diff.inMinutes < 60) {
    return 'há ${diff.inMinutes} min';
  }
  if (diff.inHours < 24) {
    return diff.inHours == 1 ? 'há 1 hora' : 'há ${diff.inHours} horas';
  }
  if (diff.inDays < 7) {
    return diff.inDays == 1 ? 'ontem' : 'há ${diff.inDays} dias';
  }
  if (diff.inDays < 30) {
    final weeks = (diff.inDays / 7).floor();
    return weeks == 1 ? 'há 1 semana' : 'há $weeks semanas';
  }
  if (diff.inDays < 365) {
    final months = (diff.inDays / 30).floor();
    return months == 1 ? 'há 1 mês' : 'há $months meses';
  }
  final years = (diff.inDays / 365).floor();
  return years == 1 ? 'há 1 ano' : 'há $years anos';
}
