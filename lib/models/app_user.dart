/// Pengguna aplikasi beserta hak aksesnya.
///
/// Role disimpan di Firestore pada dokumen `users/{uid}` field `role`
/// dengan nilai 'admin' atau 'kasir'.
class AppUser {
  final String uid;
  final String email;
  final String name;
  final String role;

  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
  });

  bool get isAdmin => role == 'admin';
  bool get isKasir => role == 'kasir';

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: (map['email'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      role: (map['role'] as String?) ?? 'kasir',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'email': email,
      'name': name,
      'role': role,
    };
  }
}
