class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String preferredLanguage;
  final String preferredCurrency;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.preferredLanguage = 'ar',
    this.preferredCurrency = 'SAR',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['userId'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      preferredLanguage: json['preferredLanguage'] ?? 'ar',
      preferredCurrency: json['preferredCurrency'] ?? 'SAR',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'preferredLanguage': preferredLanguage,
    'preferredCurrency': preferredCurrency,
  };
}
