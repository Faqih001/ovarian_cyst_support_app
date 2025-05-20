import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ovarian_cyst_support_app/constants.dart';
import 'package:ovarian_cyst_support_app/services/auth_service.dart';
import 'package:ovarian_cyst_support_app/screens/facility_selection_screen.dart';

class OvarianCystPredictionScreen extends StatefulWidget {
  const OvarianCystPredictionScreen({super.key});

  @override
  State<OvarianCystPredictionScreen> createState() =>
      _OvarianCystPredictionScreenState();
}

class _OvarianCystPredictionScreenState
    extends State<OvarianCystPredictionScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _predictionResult;
  String? _stage;
  List<String>? _recommendations;

  // Form fields
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _cystSizeController = TextEditingController();
  int _painLevel = 3;
  bool _irregularBleeding = false;
  bool _abdominalPain = false;
  bool _bloating = false;
  bool _urinarySymptoms = false;
  bool _weightLoss = false;

  Future<void> _predictCyst() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _predictionResult = null;
      _stage = null;
      _recommendations = null;
    });

    try {
      // TODO: Replace with actual ML model integration
      // This is a mock prediction for demonstration
      await Future.delayed(const Duration(seconds: 2));

      final age = int.parse(_ageController.text);
      final cystSize = double.parse(_cystSizeController.text);

      // Mock prediction logic
      String prediction;
      String stage;
      List<String> recommendations;

      if (cystSize > 10 ||
          (_painLevel > 4 && _irregularBleeding && _abdominalPain)) {
        prediction = "High Risk - Immediate Medical Attention Required";
        stage = "Severe";
        recommendations = [
          "Schedule an immediate appointment with a gynecologist",
          "Consider emergency care if pain is severe",
          "Complete rest and avoid physical strain",
          "Keep track of all symptoms",
          "Book an ultrasound scan"
        ];
        // Navigate to appointment booking if severe
        if (mounted) {
          _showBookAppointmentDialog();
        }
      } else if (cystSize > 5 ||
          (_painLevel > 3 && (_irregularBleeding || _abdominalPain))) {
        prediction = "Moderate Risk - Medical Consultation Recommended";
        stage = "Moderate";
        recommendations = [
          "Schedule a check-up within the next week",
          "Monitor symptoms daily",
          "Gentle exercise is allowed but avoid strenuous activities",
          "Apply heat therapy for pain relief",
          "Consider over-the-counter pain medication if needed"
        ];
      } else {
        prediction = "Low Risk - Regular Monitoring Advised";
        stage = "Mild";
        recommendations = [
          "Schedule a routine check-up",
          "Keep track of any changes in symptoms",
          "Maintain healthy lifestyle habits",
          "Regular mild exercise is beneficial",
          "Stay hydrated and maintain a balanced diet"
        ];
      }

      setState(() {
        _predictionResult = prediction;
        _stage = stage;
        _recommendations = recommendations;
        _isLoading = false;
      });

      // Save prediction to Firestore
      final userId =
          Provider.of<AuthService>(context, listen: false).currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('predictions')
            .add({
          'timestamp': Timestamp.now(),
          'age': age,
          'cystSize': cystSize,
          'painLevel': _painLevel,
          'irregularBleeding': _irregularBleeding,
          'abdominalPain': _abdominalPain,
          'bloating': _bloating,
          'urinarySymptoms': _urinarySymptoms,
          'weightLoss': _weightLoss,
          'prediction': prediction,
          'stage': stage,
          'recommendations': recommendations,
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _predictionResult = "Error: Unable to make prediction";
      });
    }
  }

  void _showBookAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('High Risk Detected'),
        content: const Text(
            'Based on the symptoms and cyst size, we recommend immediate medical attention. Would you like to book an appointment now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FacilitySelectionScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Book Now'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ageController.dispose();
    _cystSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ovarian Cyst Prediction'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your symptoms and measurements for analysis',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Age input
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 0 || age > 120) {
                    return 'Please enter a valid age';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Cyst size input
              TextFormField(
                controller: _cystSizeController,
                decoration: const InputDecoration(
                  labelText: 'Cyst Size (cm)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the cyst size';
                  }
                  final size = double.tryParse(value);
                  if (size == null || size < 0) {
                    return 'Please enter a valid size';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Pain level slider
              const Text('Pain Level', style: TextStyle(fontSize: 16)),
              Slider(
                value: _painLevel.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: _painLevel.toString(),
                onChanged: (value) {
                  setState(() {
                    _painLevel = value.round();
                  });
                },
              ),
              const SizedBox(height: 16),

              // Symptoms checkboxes
              const Text('Additional Symptoms', style: TextStyle(fontSize: 16)),
              CheckboxListTile(
                title: const Text('Irregular Bleeding'),
                value: _irregularBleeding,
                onChanged: (value) {
                  setState(() {
                    _irregularBleeding = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Abdominal Pain'),
                value: _abdominalPain,
                onChanged: (value) {
                  setState(() {
                    _abdominalPain = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Bloating'),
                value: _bloating,
                onChanged: (value) {
                  setState(() {
                    _bloating = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Urinary Symptoms'),
                value: _urinarySymptoms,
                onChanged: (value) {
                  setState(() {
                    _urinarySymptoms = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Unexplained Weight Loss'),
                value: _weightLoss,
                onChanged: (value) {
                  setState(() {
                    _weightLoss = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Predict button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _predictCyst,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Analyze Symptoms'),
                ),
              ),
              const SizedBox(height: 24),

              // Prediction results
              if (_predictionResult != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prediction Result:',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _predictionResult!,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _stage == 'Severe'
                                ? Colors.red
                                : _stage == 'Moderate'
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                        ),
                        if (_stage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Stage: $_stage',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                        if (_recommendations != null) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Recommendations:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...(_recommendations ?? []).map(
                            (rec) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(rec),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
