class UserProfile {
  final String id;
  final String username;
  final String? displayName;
  final String? profilePicture;
  final String? bio;

  UserProfile({
    required this.id,
    required this.username,
    this.displayName,
    this.profilePicture,
    this.bio,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['\$id'] ?? json['id'],
        username: json['username'],
        displayName: json['displayname'],
        profilePicture: json['profilePicture'] ?? json['profile_picture'],
        bio: json['bio'],
      );

  Map<String, dynamic> toJson() => {
        '\$id': id,
        'username': username,
        'displayname': displayName,
        'profilePicture': profilePicture,
        'bio': bio,
      };
}
