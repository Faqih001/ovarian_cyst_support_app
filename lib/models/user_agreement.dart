class UserAgreement {
  final String userId;
  final bool hasAcceptedTerms;
  final bool hasAcceptedPrivacy;
  final DateTime acceptedAt;

  UserAgreement({
    required this.userId,
    required this.hasAcceptedTerms,
    required this.hasAcceptedPrivacy,
    required this.acceptedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'hasAcceptedTerms': hasAcceptedTerms,
      'hasAcceptedPrivacy': hasAcceptedPrivacy,
      'acceptedAt': acceptedAt.toIso8601String(),
    };
  }

  factory UserAgreement.fromMap(Map<String, dynamic> map) {
    return UserAgreement(
      userId: map['userId'] as String,
      hasAcceptedTerms: map['hasAcceptedTerms'] as bool,
      hasAcceptedPrivacy: map['hasAcceptedPrivacy'] as bool,
      acceptedAt: DateTime.parse(map['acceptedAt'] as String),
    );
  }
}
