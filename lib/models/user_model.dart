class UserModel {
  final String name;
  final String email;
  final String phone;
  final String? profilePic;

  UserModel({
    required this.name,
    required this.email,
    required this.phone,
    this.profilePic,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? profilePic,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePic: profilePic ?? this.profilePic,
    );
  }
}
