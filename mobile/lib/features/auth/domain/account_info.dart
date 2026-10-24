class AccountInfo {
  const AccountInfo({
    required this.hasProfile,
    this.userId,
    this.email,
    this.createdAt,
  });

  final int? userId;
  final String? email;
  final DateTime? createdAt;
  final bool hasProfile;
}
