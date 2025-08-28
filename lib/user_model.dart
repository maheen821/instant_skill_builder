class User {
  String username; // final hataya
  String email;
  String? profileImage;

  User({required this.username, required this.email, this.profileImage});

  factory User.fromJson(Map<String, dynamic> json) => User(
    username: json['username'],
    email: json['email'],
    profileImage: json['profileImage'],
  );

  Map<String, dynamic> toJson() => {
    'username': username,
    'email': email,
    'profileImage': profileImage,
  };
}
