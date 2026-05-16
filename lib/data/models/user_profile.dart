class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    required this.badge,
    required this.currentCity,
    required this.language,
  });

  final String id;
  final String displayName;
  final String email;
  final String badge;
  final String currentCity;
  final String language;

  factory UserProfile.fromJson(Map<String, Object?> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Traveler',
      email: json['email'] as String? ?? '',
      badge: json['badge'] as String? ?? 'Local Explorer',
      currentCity: json['currentCity'] as String? ?? 'Seoul',
      language: json['language'] as String? ?? 'English',
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'badge': badge,
      'currentCity': currentCity,
      'language': language,
    };
  }
}
