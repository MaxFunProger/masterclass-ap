class UserProfile {
  final String id;
  final String phone;
  final String fullName;
  final String telegramNick;

  UserProfile({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.telegramNick,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      phone: json['phone'],
      fullName: json['full_name'],
      telegramNick: json['telegram_nick'] ?? '',
    );
  }
}
