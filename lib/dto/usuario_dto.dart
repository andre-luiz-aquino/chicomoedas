class Usuario {
  final String nomeUsuario;
  final String nomeCompleto;
  final String email;
  final String senha;
  bool isLogado;

  Usuario({
    required this.nomeUsuario,
    required this.nomeCompleto,
    required this.email,
    required this.senha,
    this.isLogado = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'nomeUsuario': nomeUsuario,
      'nomeCompleto': nomeCompleto,
      'email': email,
      'senha': senha,
      'isLogado': isLogado ? 1 : 0,
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      nomeUsuario: map['nomeUsuario'],
      nomeCompleto: map['nomeCompleto'],
      email: map['email'],
      senha: map['senha'],
      isLogado: map['isLogado'] == 1,
    );
  }
}