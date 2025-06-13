class UserProfile {
  final String id;
  final String username;
  final String? bio;

  UserProfile({required this.id, required this.username, this.bio});

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['\$id'] ?? json['id'],
        username: json['username'],
        bio: json['bio'],
      );

  Map<String, dynamic> toJson() => {
        '\$id': id,
        'username': username,
        'bio': bio,
      };
}
