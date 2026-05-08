enum UserRole { administrador, gerente, operario }

class UserProfile {
  final String cpf;
  final String nome;
  final UserRole role;

  const UserProfile({
    required this.cpf,
    required this.nome,
    required this.role,
  });
}
