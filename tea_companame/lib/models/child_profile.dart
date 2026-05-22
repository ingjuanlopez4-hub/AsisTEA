class ChildProfile {
  final String childId;
  final String name;
  final String birthDate; // ISO date
  final String diagnosis;
  final String? diagnosisDate;
  final String communicationLevel; // 'pre-verbal' | 'primeras-palabras' | 'frases' | 'verbal-fluido'
  final List<String> sensorySensitivities;
  final List<String> knownTriggers;
  final List<String> effectiveStrategies;
  final List<String> favoriteReinforcers;
  final String? avatar;

  ChildProfile({
    required this.childId,
    required this.name,
    required this.birthDate,
    required this.diagnosis,
    this.diagnosisDate,
    this.communicationLevel = 'frases',
    this.sensorySensitivities = const [],
    this.knownTriggers = const [],
    this.effectiveStrategies = const [],
    this.favoriteReinforcers = const [],
    this.avatar,
  });

  int get age {
    final birth = DateTime.parse(birthDate);
    final now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  Map<String, dynamic> toJson() => {
        'childId': childId,
        'name': name,
        'birthDate': birthDate,
        'diagnosis': diagnosis,
        'diagnosisDate': diagnosisDate,
        'communicationLevel': communicationLevel,
        'sensorySensitivities': sensorySensitivities,
        'knownTriggers': knownTriggers,
        'effectiveStrategies': effectiveStrategies,
        'favoriteReinforcers': favoriteReinforcers,
        'avatar': avatar,
      };

  factory ChildProfile.fromJson(Map<String, dynamic> json) => ChildProfile(
        childId: json['childId'] as String,
        name: json['name'] as String,
        birthDate: json['birthDate'] as String,
        diagnosis: json['diagnosis'] as String,
        diagnosisDate: json['diagnosisDate'] as String?,
        communicationLevel:
            json['communicationLevel'] as String? ?? 'frases',
        sensorySensitivities:
            (json['sensorySensitivities'] as List?)?.cast<String>() ?? [],
        knownTriggers:
            (json['knownTriggers'] as List?)?.cast<String>() ?? [],
        effectiveStrategies:
            (json['effectiveStrategies'] as List?)?.cast<String>() ?? [],
        favoriteReinforcers:
            (json['favoriteReinforcers'] as List?)?.cast<String>() ?? [],
        avatar: json['avatar'] as String?,
      );

  ChildProfile copyWith({
    String? childId,
    String? name,
    String? birthDate,
    String? diagnosis,
    String? diagnosisDate,
    String? communicationLevel,
    List<String>? sensorySensitivities,
    List<String>? knownTriggers,
    List<String>? effectiveStrategies,
    List<String>? favoriteReinforcers,
    String? avatar,
  }) =>
      ChildProfile(
        childId: childId ?? this.childId,
        name: name ?? this.name,
        birthDate: birthDate ?? this.birthDate,
        diagnosis: diagnosis ?? this.diagnosis,
        diagnosisDate: diagnosisDate ?? this.diagnosisDate,
        communicationLevel: communicationLevel ?? this.communicationLevel,
        sensorySensitivities: sensorySensitivities ?? this.sensorySensitivities,
        knownTriggers: knownTriggers ?? this.knownTriggers,
        effectiveStrategies: effectiveStrategies ?? this.effectiveStrategies,
        favoriteReinforcers: favoriteReinforcers ?? this.favoriteReinforcers,
        avatar: avatar ?? this.avatar,
      );
}
