class SymptomPrediction {
  final DateTime predictionDate;
  final double severityScore; // 0-10 scale
  final String riskLevel; // Low, Medium, High
  final List<String> potentialIssues;
  final String recommendation;
  final bool requiresMedicalAttention;

  SymptomPrediction({
    required this.predictionDate,
    required this.severityScore,
    required this.riskLevel,
    required this.potentialIssues,
    required this.recommendation,
    required this.requiresMedicalAttention,
  });

  // Create risk level from severity score
  static String getRiskLevelFromScore(double score) {
    if (score < 3.0) {
      return 'Low';
    } else if (score < 7.0) {
      return 'Medium';
    } else {
      return 'High';
    }
  }

  // Create recommendation based on severity
  static String getRecommendationFromScore(double score) {
    if (score < 3.0) {
      return 'Continue monitoring your symptoms. No immediate action required.';
    } else if (score < 7.0) {
      return 'Consider scheduling a check-up with your healthcare provider within the next 1-2 weeks.';
    } else {
      return 'Please contact your healthcare provider as soon as possible or visit an emergency room if symptoms are severe.';
    }
  }

  // Factory method for creating from JSON
  factory SymptomPrediction.fromJson(Map<String, dynamic> json) {
    return SymptomPrediction(
      predictionDate: DateTime.parse(json['predictionDate']),
      severityScore: json['severityScore'],
      riskLevel: json['riskLevel'],
      potentialIssues: List<String>.from(json['potentialIssues']),
      recommendation: json['recommendation'],
      requiresMedicalAttention: json['requiresMedicalAttention'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'predictionDate': predictionDate.toIso8601String(),
      'severityScore': severityScore,
      'riskLevel': riskLevel,
      'potentialIssues': potentialIssues,
      'recommendation': recommendation,
      'requiresMedicalAttention': requiresMedicalAttention,
    };
  }
}
