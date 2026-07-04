class VachanamrutQuote {
  const VachanamrutQuote({
    required this.reference,
    required this.title,
    required this.quote,
    required this.meaning,
  });

  factory VachanamrutQuote.fromJson(Map<String, Object?> json) {
    return VachanamrutQuote(
      reference: json['reference'] as String,
      title: json['title'] as String,
      quote: json['quote'] as String,
      meaning: json['meaning'] as String,
    );
  }

  final String reference;
  final String title;
  final String quote;
  final String meaning;
}
