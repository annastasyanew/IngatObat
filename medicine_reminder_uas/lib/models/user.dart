class User {
  final int id;
  final String name;
  final String email;
  final String? profilePicture;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
  });

  /// Get profile picture URL dengan cache busting
  String? getProfilePictureUrl() {
    if (profilePicture == null || profilePicture!.isEmpty) {
      return null;
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = profilePicture!.split('/').last;
    return 'http://localhost/api_UAS/get_profile_picture.php?f=$filename&t=$timestamp';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profilePicture: json['profile_picture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_picture': profilePicture,
    };
  }
}
