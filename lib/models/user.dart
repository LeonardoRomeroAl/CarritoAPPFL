class User {
  final int id;
  final String username;
  final int clienteId;

  User({required this.id, required this.username, required this.clienteId});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['apiUsuarioId'],
      username: json['nombreUsuario'],
      clienteId: json['clienteId'],
    );
  }
}
