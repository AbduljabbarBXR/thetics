enum ThemeChoice { dark, light, system }

extension ThemeChoiceX on ThemeChoice {
  String get label => switch (this) {
        ThemeChoice.dark => 'Dark',
        ThemeChoice.light => 'Light',
        ThemeChoice.system => 'System',
      };
}

class AppSettings {
  const AppSettings({
    this.theme = ThemeChoice.dark,
    this.haptics = true,
    this.restAlerts = true,
    this.aiFoodBeta = false,
  });

  final ThemeChoice theme;
  final bool haptics;
  final bool restAlerts;
  final bool aiFoodBeta;

  AppSettings copyWith({
    ThemeChoice? theme,
    bool? haptics,
    bool? restAlerts,
    bool? aiFoodBeta,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      haptics: haptics ?? this.haptics,
      restAlerts: restAlerts ?? this.restAlerts,
      aiFoodBeta: aiFoodBeta ?? this.aiFoodBeta,
    );
  }

  Map<String, dynamic> toJson() => {
        'theme': theme.name,
        'haptics': haptics,
        'restAlerts': restAlerts,
        'aiFoodBeta': aiFoodBeta,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final themeName = json['theme'] as String?;
    return AppSettings(
      theme: ThemeChoice.values.firstWhere(
        (value) => value.name == themeName,
        orElse: () => ThemeChoice.dark,
      ),
      haptics: json['haptics'] as bool? ?? true,
      restAlerts: json['restAlerts'] as bool? ?? true,
      aiFoodBeta: json['aiFoodBeta'] as bool? ?? false,
    );
  }
}
