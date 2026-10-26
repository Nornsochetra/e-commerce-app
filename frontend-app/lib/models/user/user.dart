/// The signed-in customer's profile.
class User {
  final String id;
  final String name;
  final String email;
  final String phone; // empty when not provided
  final DateTime memberSince;
  final UserCounts counts; // from GET /auth/me, so badges and Profile numbers need no extra requests

  const User({required this.id, required this.name, required this.email, this.phone = '', required this.memberSince, this.counts = const UserCounts()});

  /// "Alex Morgan" → "AM"
  String get initials => name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();

  User copyWith({String? name, String? email, String? phone}) =>
      User(id: id, name: name ?? this.name, email: email ?? this.email, phone: phone ?? this.phone, memberSince: memberSince, counts: counts);

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String? ?? '',
        memberSince: DateTime.parse(json['memberSince'] as String),
        counts: UserCounts.fromJson(json['counts'] as Map<String, dynamic>? ?? const {}),
      );
}

/// How many orders, saved products and cart items the customer has (`counts` in GET /auth/me).
class UserCounts {
  final int orders;
  final int wishlistItems;
  final int cartItems;

  const UserCounts({this.orders = 0, this.wishlistItems = 0, this.cartItems = 0});

  factory UserCounts.fromJson(Map<String, dynamic> json) => UserCounts(
        orders: (json['orders'] as num?)?.toInt() ?? 0,
        wishlistItems: (json['wishlistItems'] as num?)?.toInt() ?? 0,
        cartItems: (json['cartItems'] as num?)?.toInt() ?? 0,
      );
}
