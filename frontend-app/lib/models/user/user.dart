/// The signed-in customer's profile.
class User {
  final String id;
  final String name;
  final String email;
  final String phone; // empty when not provided
  final DateTime memberSince;

  const User({required this.id, required this.name, required this.email, this.phone = '', required this.memberSince});

  /// "Alex Morgan" → "AM"
  String get initials => name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();

  User copyWith({String? name, String? email, String? phone}) =>
      User(id: id, name: name ?? this.name, email: email ?? this.email, phone: phone ?? this.phone, memberSince: memberSince);

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String? ?? '',
        memberSince: DateTime.parse(json['memberSince'] as String),
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'phone': phone, 'memberSince': memberSince.toIso8601String()};
}
