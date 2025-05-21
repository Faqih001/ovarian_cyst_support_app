import 'package:flutter/material.dart';
import 'package:ovarian_cyst_support_app/constants.dart';
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
  final MLPredictionService _mlService = MLPredictionService();
  Map<String, double>? _featureContributions;

  // Form fields for PCOS prediction
  final Map<String, bool> _booleanFields = {
    'Pregnant': false,
    'Weight gain': false,
    'Hair growth': false,
    'Skin darkening': false,
    'Hair loss': false,
    'Pimples': false,
    'Fast food': false,
    'Regular Exercise': false,
  };

  String _bloodGroup = 'A+';
  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-'
  ];

  final TextEditingController _amhController = TextEditingController();
  final TextEditingController _betaHcg1Controller = TextEditingController();
  final TextEditingController _betaHcg2Controller = TextEditingController();

  void _showBookAppointmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('High Risk Detected'),
        content: const Text(
          'Based on the test results, we recommend immediate medical attention. Would you like to book an appointment now?',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PCOS Risk Assessment'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'This screening tool uses various health indicators to assess PCOS risk.',
                      style: TextStyle(color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Blood Group Selection
              DropdownButtonFormField<String>(
                value: _bloodGroup,
                decoration: InputDecoration(
                  labelText: 'Blood Group',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.bloodtype),
                ),
                items: _bloodGroups.map((String group) {
                  return DropdownMenuItem<String>(
                    value: group,
                    child: Text(group),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _bloodGroup = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Boolean Fields
              ..._booleanFields.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SwitchListTile(
                    title: Text(entry.key),
                    value: entry.value,
                    onChanged: (bool value) {
                      setState(() {
                        _booleanFields[entry.key] = value;
                      });
                    },
                    tileColor: Colors.grey.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 24),

              // Beta HCG First Test
              TextFormField(
                controller: _betaHcg1Controller,
                decoration: InputDecoration(
                  labelText: 'Beta HCG - First Test (mIU/mL)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.science),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the first Beta HCG value';
                  }
                  final number = double.tryParse(value);
                  if (number == null || number < 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Beta HCG Second Test
              TextFormField(
                controller: _betaHcg2Controller,
                decoration: InputDecoration(
                  labelText: 'Beta HCG - Second Test (mIU/mL)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.science),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the second Beta HCG value';
                  }
                  final number = double.tryParse(value);
                  if (number == null || number < 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // AMH Level
              TextFormField(
                controller: _amhController,
                decoration: InputDecoration(
                  labelText: 'AMH Level (ng/mL)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.science),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your AMH level';
                  }
                  final number = double.tryParse(value);
                  if (number == null || number < 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Predict Button
              ElevatedButton(
                onPressed: _isLoading ? null : _predict,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Analyzing...')
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.analytics),
                          SizedBox(width: 8),
                          Text('Analyze Risk', style: TextStyle(fontSize: 16)),
                        ],
                      ),
              ),

              if (_predictionResult != null) ...[
                const SizedBox(height: 24),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.medical_information,
                              color: _getStageColor(_stage ?? ''),
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Risk Assessment',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    _stage ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: _getStageColor(_stage ?? ''),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _getStageColor(_stage ?? '')
                                    .withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                _predictionResult ?? '0%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getStageColor(_stage ?? ''),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_featureContributions != null) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Risk Factors',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._featureContributions!.entries.map((entry) {
                            final contribution = entry.value * 100;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(entry.key),
                                      Text(
                                        '${contribution.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _getContributionColor(
                                              entry.value),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: entry.value,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _getContributionColor(entry.value),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                        if (_recommendations != null) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Recommendations',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...(_recommendations ?? []).map((rec) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 20,
                                      color: _getStageColor(_stage ?? ''),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(rec)),
                                  ],
                                ),
                              )),
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

  Color _getStageColor(String stage) {
    switch (stage.toLowerCase()) {
      case 'low risk':
        return Colors.green;
      case 'moderate risk':
        return Colors.orange;
      case 'high risk':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getContributionColor(double value) {
    if (value < 0.3) return Colors.green;
    if (value < 0.7) return Colors.orange;
    return Colors.red;
  }

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Convert blood group to numeric value
      final bloodGroupMap = {
        'A+': 0,
        'A-': 1,
        'B+': 2,
        'B-': 3,
        'O+': 4,
        'O-': 5,
        'AB+': 6,
        'AB-': 7
      };

      final result = await _mlService.predictFromData(
        pregnant: _booleanFields['Pregnant']! ? 1 : 0,
        weightGain: _booleanFields['Weight gain']! ? 1 : 0,
        hairGrowth: _booleanFields['Hair growth']! ? 1 : 0,
        skinDarkening: _booleanFields['Skin darkening']! ? 1 : 0,
        hairLoss: _booleanFields['Hair loss']! ? 1 : 0,
        pimples: _booleanFields['Pimples']! ? 1 : 0,
        fastFood: _booleanFields['Fast food']! ? 1 : 0,
        regularExercise: _booleanFields['Regular Exercise']! ? 1 : 0,
        bloodGroup: bloodGroupMap[_bloodGroup]!,
      );

      setState(() {
        _predictionResult = '${(result.riskScore * 100).toStringAsFixed(1)}%';
        _stage = result.stage;
        _recommendations = result.recommendations;
        _featureContributions = result.featureContributions;
        _isLoading = false;
      });

      // Show appointment booking dialog for high risk cases
      if (result.stage.toLowerCase() == 'high risk') {
        _showBookAppointmentDialog(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _amhController.dispose();
    _betaHcg1Controller.dispose();
    _betaHcg2Controller.dispose();
    super.dispose();
  }
}
