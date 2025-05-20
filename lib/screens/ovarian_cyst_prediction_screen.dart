import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ovarian_cyst_support_app/constants.dart';
import 'package:ovarian_cyst_support_app/services/auth_service.dart';
import 'package:ovarian_cyst_support_app/services/ml_prediction_service.dart';
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
  File? _selectedImage;
  Map<String, dynamic>? _imageAnalysisResult;
  final MLPredictionService _mlService = MLPredictionService();
  Map<String, double>? _featureContributions;

  // Form fields
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _cystSizeController = TextEditingController();
  int _painLevel = 3;
  bool _irregularBleeding = false;
  bool _abdominalPain = false;
  bool _bloating = false;
  bool _urinarySymptoms = false;
  bool _weightLoss = false;

  void _showBookAppointmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('High Risk Detected'),
        content: const Text(
          'Based on the symptoms and cyst size, we recommend immediate medical attention. Would you like to book an appointment now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.push(
                dialogContext,
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _imageAnalysisResult = null;
      });

      try {
        setState(() => _isLoading = true);
        final result = await _mlService.analyzeUltrasoundImage(_selectedImage!);
        setState(() {
          _imageAnalysisResult = result;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _imageAnalysisResult = null;
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error analyzing image: \${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _predictCyst() async {
    if (!_formKey.currentState!.validate()) return;

    // Capture the auth service user ID before async operations
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser?.uid;

    setState(() {
      _isLoading = true;
      _predictionResult = null;
      _stage = null;
      _recommendations = null;
      _featureContributions = null;
    });

    try {
      final age = int.parse(_ageController.text);
      final cystSize = double.parse(_cystSizeController.text);

      // Get prediction from ML service
      final prediction = await _mlService.predictFromData(
        age: age,
        cystSize: cystSize,
        painLevel: _painLevel,
        irregularBleeding: _irregularBleeding,
        abdominalPain: _abdominalPain,
        bloating: _bloating,
        urinarySymptoms: _urinarySymptoms,
        weightLoss: _weightLoss,
      );

      if (mounted && userId != null) {
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
          'prediction': prediction.stage,
          'riskScore': prediction.riskScore,
          'recommendations': prediction.recommendations,
          'featureContributions': prediction.featureContributions,
          'imageAnalysis': _imageAnalysisResult,
        });
      }

      if (mounted) {
        setState(() {
          _predictionResult =
              '\${prediction.stage} Risk - Risk Score: \${prediction.riskScore.toStringAsFixed(1)}%';
          _stage = prediction.stage;
          _recommendations = prediction.recommendations;
          _featureContributions = prediction.featureContributions;
          _isLoading = false;
        });

        if (prediction.stage == 'Severe') {
          _showBookAppointmentDialog(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _predictionResult = "Error: Unable to make prediction";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: \${e.toString()}')),
        );
      }
    }
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

              // Image upload section
              const Text(
                'Upload Ultrasound Image (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (_selectedImage != null) ...[
                        Image.file(
                          _selectedImage!,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(height: 8),
                      ],
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _pickImage,
                        icon: const Icon(Icons.upload),
                        label: Text(_selectedImage == null
                            ? 'Select Image'
                            : 'Change Image'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      if (_imageAnalysisResult != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Image Analysis Result:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _imageAnalysisResult!['isCystic']
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                        Text(
                          'Confidence: ${(_imageAnalysisResult!['confidence'] as double).toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
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
                        if (_featureContributions != null) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Risk Factors Analysis:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...(_featureContributions!.entries
                              .where((e) => e.value > 0)
                              .toList()
                                ..sort((a, b) => b.value.compareTo(a.value)))
                              .map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.key,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      LinearProgressIndicator(
                                        value: e.value / 100,
                                        backgroundColor: Colors.grey[200],
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          e.value > 75
                                              ? Colors.red
                                              : e.value > 50
                                                  ? Colors.orange
                                                  : Colors.green,
                                        ),
                                      ),
                                      Text(
                                        '\${e.value.toStringAsFixed(1)}% contribution',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
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
