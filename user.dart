class User {
  final String id;
  final String name;
  final String username;

  User({required this.id, required this.name, required this.username});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
    };
  }
}

// OLD Version Delete on completion
// class User {
//   final String id;
//   final String name;
//   final String username;
//
//   User({required this.id, required this.name, required this.username});
//
//   factory User.fromJson(Map<String, dynamic> json) {
//     return User(
//       id: json['id']?.toString() ?? '',
//       name: json['name']?.toString() ?? '',
//       username: json['username']?.toString() ?? '',
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//       'username': username,
//     };
//   }
// }