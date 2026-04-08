class Character {
  final int id;
  final String name;
  final String? avatar;
  final String? greeting;

  Character({required this.id, required this.name, this.avatar, this.greeting});

  factory Character.fromJson(Map<String, dynamic> json) => Character(
    id: json['id'],
    name: json['name'],
    avatar: json['avatar'],
    greeting: json['greeting'],
  );
}
