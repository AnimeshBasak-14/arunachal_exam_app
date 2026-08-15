class UserModel {
  final String name;
  final String email;
  final String phone;
  final String? profilePic;
  final String dob;
  final int rating;
  final String city;

  UserModel({
    required this.name,
    required this.email,
    required this.phone,
    this.profilePic,
    this.dob = '2000-01-01',
    this.rating = 1200,
    this.city = '',
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? profilePic,
    String? dob,
    int? rating,
    String? city,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePic: profilePic ?? this.profilePic,
      dob: dob ?? this.dob,
      rating: rating ?? this.rating,
      city: city ?? this.city,
    );
  }
}
