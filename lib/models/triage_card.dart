enum UrgencyLevel {
  green,
  yellow,
  red;

  static UrgencyLevel fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'GREEN':
        return UrgencyLevel.green;
      case 'RED':
        return UrgencyLevel.red;
      case 'YELLOW':
      default:
        return UrgencyLevel.yellow;
    }
  }

  String toFormattedString() {
    switch (this) {
      case UrgencyLevel.green:
        return 'GREEN';
      case UrgencyLevel.yellow:
        return 'YELLOW';
      case UrgencyLevel.red:
        return 'RED';
    }
  }
}

class TriageCard {
  final UrgencyLevel urgencyLevel;
  final String summary;
  final List<String> possibleCauses;
  final List<String> immediateActions;
  final List<String> vetQuestions;

  const TriageCard({
    required this.urgencyLevel,
    required this.summary,
    required this.possibleCauses,
    required this.immediateActions,
    required this.vetQuestions,
  });

  factory TriageCard.fromMap(Map<String, dynamic> map) {
    return TriageCard(
      urgencyLevel: UrgencyLevel.fromString(map['urgencyLevel'] as String?),
      summary: (map['summary'] as String?) ?? '',
      possibleCauses: (map['possibleCauses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      immediateActions: (map['immediateActions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      vetQuestions: (map['vetQuestions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'urgencyLevel': urgencyLevel.toFormattedString(),
      'summary': summary,
      'possibleCauses': possibleCauses,
      'immediateActions': immediateActions,
      'vetQuestions': vetQuestions,
    };
  }
}

