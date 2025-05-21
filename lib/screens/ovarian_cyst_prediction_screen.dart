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
  final MLPredictionService _mlService = MLPredictionService();
  Map<String, double>? _featureContributions;
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

  // Blood group selection
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

  // Text Controllers for numeric inputs
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _bmiController = TextEditingController();
  final TextEditingController _pulseRateController = TextEditingController();
  final TextEditingController _rrController = TextEditingController();
  final TextEditingController _hbController = TextEditingController();
  final TextEditingController _cycleLengthController = TextEditingController();
  final TextEditingController _marriageStatusController =
      TextEditingController();
  final TextEditingController _abortionsController = TextEditingController();
  final TextEditingController _betaHcg1Controller = TextEditingController();
  final TextEditingController _betaHcg2Controller = TextEditingController();
  final TextEditingController _fshController = TextEditingController();
  final TextEditingController _lhController = TextEditingController();
  final TextEditingController _hipController = TextEditingController();
  final TextEditingController _waistController = TextEditingController();
  final TextEditingController _tshController = TextEditingController();
  final TextEditingController _amhController = TextEditingController();
  final TextEditingController _prlController = TextEditingController();
  final TextEditingController _vitD3Controller = TextEditingController();
  final TextEditingController _prgController = TextEditingController();
  final TextEditingController _rbsController = TextEditingController();
  final TextEditingController _bpSystolicController = TextEditingController();
  final TextEditingController _bpDiastolicController = TextEditingController();
  final TextEditingController _follicleLController = TextEditingController();
  final TextEditingController _follicleRController = TextEditingController();
  final TextEditingController _avgFSizeLController = TextEditingController();
  final TextEditingController _avgFSizeRController = TextEditingController();
  final TextEditingController _endometriumController = TextEditingController();

  bool _cycleRegularity = true; // true for Regular, false for Irregular

  @override
  void initState() {
    super.initState();
    // Add listeners for calculated fields
    _weightController.addListener(_calculateBMI);
    _heightController.addListener(_calculateBMI);
    _waistController.addListener(_calculateWaistHipRatio);
    _hipController.addListener(_calculateWaistHipRatio);
  }

  void _calculateBMI() {
    if (_weightController.text.isNotEmpty &&
        _heightController.text.isNotEmpty) {
      try {
        double weight = double.parse(_weightController.text);
        double height =
            double.parse(_heightController.text) / 100; // convert to meters
        double bmi = weight / (height * height);
        _bmiController.text = bmi.toStringAsFixed(2);
      } catch (e) {
        _bmiController.text = '';
      }
    }
  }

  void _calculateWaistHipRatio() {
    if (_waistController.text.isNotEmpty && _hipController.text.isNotEmpty) {
      try {
        double waist = double.parse(_waistController.text);
        double hip = double.parse(_hipController.text);
        double ratio = waist / hip;
        setState(() {
          _waistHipRatio = ratio;
        });
      } catch (e) {
        setState(() {
          _waistHipRatio = null;
        });
      }
    }
  }

  double? _waistHipRatio;

  Widget _buildNumericField(String label, TextEditingController controller,
      {String? suffix, String? hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          hintText: hint,
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          if (double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildBooleanField(String label) {
    return CheckboxListTile(
      title: Text(label),
      value: _booleanFields[label],
      onChanged: (bool? value) {
        setState(() {
          _booleanFields[label] = value ?? false;
        });
      },
    );
  }

  Widget _buildRecommendationSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: EdgeInsets.only(
                left: item.startsWith('  •') ? 16.0 : 0,
                bottom: 4.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!item.startsWith('  •')) const Text('• '),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _predictionResult = null;
      _stage = null;
      _featureContributions = null;
    });

    try {
      // First validate all required numeric fields
      final requiredFields = {
        'Age': _ageController,
        'Weight': _weightController,
        'Height': _heightController,
        'BMI': _bmiController,
        'Pulse Rate': _pulseRateController,
        'Respiratory Rate': _rrController,
        'Hemoglobin': _hbController,
        'Cycle Length': _cycleLengthController,
        'Marriage Status': _marriageStatusController,
        'Waist': _waistController,
        'Hip': _hipController,
      };

      for (var entry in requiredFields.entries) {
        final value = entry.value.text;
        if (value.isEmpty) {
          throw Exception('${entry.key} is required');
        }
        final numeric = double.tryParse(value);
        if (numeric == null) {
          throw Exception('${entry.key} must be a valid number');
        }
        if (numeric < 0) {
          throw Exception('${entry.key} cannot be negative');
        }
      }

      // Validate specific ranges
      final bmi = double.parse(_bmiController.text);
      if (bmi < 10 || bmi > 100) {
        throw Exception('BMI should be between 10 and 100');
      }

      final waist = double.parse(_waistController.text);
      final hip = double.parse(_hipController.text);
      if (waist >= hip) {
        throw Exception(
            'Waist measurement should be less than hip measurement');
      }

      final result = await _mlService.predictOvarianCyst(
        age: double.parse(_ageController.text),
        weight: double.parse(_weightController.text),
        height: double.parse(_heightController.text),
        bmi: double.parse(_bmiController.text),
        bloodGroup: _bloodGroup,
        pulseRate: double.parse(_pulseRateController.text),
        rr: double.parse(_rrController.text),
        hb: double.parse(_hbController.text),
        cycleLength: double.parse(_cycleLengthController.text),
        cycleRegularity: _cycleRegularity ? 1 : 0,
        marriageStatus: double.parse(_marriageStatusController.text),
        abortions: double.parse(_abortionsController.text),
        pregnant: _booleanFields['Pregnant']! ? 1 : 0,
        waistHipRatio: double.parse(_waistController.text) /
            double.parse(_hipController.text),
        tsh: double.parse(_tshController.text),
        amh: double.parse(_amhController.text),
        prl: double.parse(_prlController.text),
        vitD3: double.parse(_vitD3Controller.text),
        prg: double.parse(_prgController.text),
        rbs: double.parse(_rbsController.text),
        weightGain: _booleanFields['Weight gain']! ? 1 : 0,
        hairGrowth: _booleanFields['Hair growth']! ? 1 : 0,
        skinDarkening: _booleanFields['Skin darkening']! ? 1 : 0,
        hairLoss: _booleanFields['Hair loss']! ? 1 : 0,
        pimples: _booleanFields['Pimples']! ? 1 : 0,
        fastFood: _booleanFields['Fast food']! ? 1 : 0,
        regularExercise: _booleanFields['Regular Exercise']! ? 1 : 0,
        bpSystolic: double.parse(_bpSystolicController.text),
        bpDiastolic: double.parse(_bpDiastolicController.text),
        follicleL: double.parse(_follicleLController.text),
        follicleR: double.parse(_follicleRController.text),
        avgFSizeL: double.parse(_avgFSizeLController.text),
        avgFSizeR: double.parse(_avgFSizeRController.text),
        endometrium: double.parse(_endometriumController.text),
      );

      if (!mounted) return;

      setState(() {
        _predictionResult =
            'Risk Score: ${(result.riskScore * 100).toStringAsFixed(2)}%';
        _stage = result.stage;
        _featureContributions = result.featureContributions;
        _isLoading = false;
      });

      if (!mounted) return;

      if (result.riskScore > 0.7) {
        await _showHighRiskDialog();
      }
    } catch (e) {
      if (!mounted) return;

      // Show error dialog
      await _showErrorDialog(e.toString());

      setState(() {
        _isLoading = false;
        _predictionResult = null;
      });
    }
  }

  Future<void> _showHighRiskDialog() async {
    final shouldBook = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_rounded, color: Colors.red, size: 48),
        title: const Text(
          '⚠️ High Risk Detected - Urgent Action Required',
          style: TextStyle(color: Colors.red),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: const [
              Text(
                'Your test results indicate a high-risk condition that requires immediate medical attention.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('Key Actions Required:'),
              SizedBox(height: 8),
              Text('• 🏥 Schedule an immediate consultation'),
              Text('• 🔬 Complete necessary diagnostic tests'),
              Text('• 📋 Prepare your symptom history'),
              SizedBox(height: 16),
              Text(
                'Would you like to book an urgent appointment with a specialist now?',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              showDialog(
                context: dialogContext,
                builder: (BuildContext confirmContext) => AlertDialog(
                  title: const Text('Confirmation Required'),
                  content: const Text(
                    '⚠️ Delaying medical attention in high-risk cases may lead to complications. Are you sure you want to book later?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(confirmContext);
                        Navigator.pop(dialogContext, true); // Book anyway
                      },
                      child: const Text('Book Now'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(confirmContext);
                        Navigator.pop(dialogContext, false);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                      ),
                      child: const Text('Yes, Later'),
                    ),
                  ],
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text(
              'Book Urgent Appointment',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (shouldBook == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const FacilitySelectionScreen(),
        ),
      );
    }
  }

  Future<void> _showErrorDialog(String error) async {
    String message = error;
    String title = 'Error';

    // Make error messages more user-friendly
    if (error.contains('Unable to connect')) {
      title = 'Connection Error';
      message =
          'Unable to connect to our servers. Please check your internet connection and try again.';
    } else if (error.contains('Invalid response')) {
      title = 'Server Error';
      message =
          'We encountered an issue processing your data. Please try again later.';
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text(message),
              if (!message.contains('try again')) ...[
                const SizedBox(height: 16),
                const Text('Please check your inputs and try again.'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
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
              const Text(
                'Basic Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildNumericField('Age', _ageController, suffix: 'years'),
              _buildNumericField('Weight', _weightController, suffix: 'kg'),
              _buildNumericField('Height', _heightController, suffix: 'cm'),
              _buildNumericField('BMI', _bmiController,
                  hint: 'Calculated automatically'),
              DropdownButtonFormField<String>(
                value: _bloodGroup,
                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  border: OutlineInputBorder(),
                ),
                items: _bloodGroups.map((String group) {
                  return DropdownMenuItem(
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
              const Text(
                'Vital Signs',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildNumericField('Pulse Rate', _pulseRateController,
                  suffix: 'bpm', hint: 'Normal: 60-100 bpm'),
              _buildNumericField('Respiratory Rate', _rrController,
                  suffix: 'breaths/min', hint: 'Normal: 12-20 breaths/min'),
              _buildNumericField('Hemoglobin', _hbController,
                  suffix: 'g/dl', hint: 'Normal: 12-15.5 g/dl'),
              _buildNumericField('BP Systolic', _bpSystolicController,
                  suffix: 'mmHg', hint: 'Normal: 90-120 mmHg'),
              _buildNumericField('BP Diastolic', _bpDiastolicController,
                  suffix: 'mmHg', hint: 'Normal: 60-80 mmHg'),
              const SizedBox(height: 16),
              const Text(
                'Menstrual History',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Cycle Regularity'),
                subtitle: Text(_cycleRegularity ? 'Regular' : 'Irregular'),
                value: _cycleRegularity,
                onChanged: (bool value) {
                  setState(() {
                    _cycleRegularity = value;
                  });
                },
              ),
              _buildNumericField('Cycle Length', _cycleLengthController,
                  suffix: 'days'),
              const SizedBox(height: 16),
              const Text(
                'Physical Measurements',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildNumericField('Waist', _waistController, suffix: 'inch'),
              _buildNumericField('Hip', _hipController, suffix: 'inch'),
              if (_waistHipRatio != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Waist-Hip Ratio: ${_waistHipRatio!.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'Hormonal Tests',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildNumericField('FSH', _fshController,
                  suffix: 'mIU/mL', hint: 'Normal: 4.7-21.5 mIU/mL'),
              _buildNumericField('LH', _lhController,
                  suffix: 'mIU/mL', hint: 'Normal: 1.9-12.5 mIU/mL'),
              _buildNumericField('TSH', _tshController,
                  suffix: 'mIU/L', hint: 'Normal: 0.4-4.0 mIU/L'),
              _buildNumericField('AMH', _amhController,
                  suffix: 'ng/mL', hint: 'Normal: 1.0-4.0 ng/mL'),
              _buildNumericField('Prolactin', _prlController,
                  suffix: 'ng/mL', hint: 'Normal: 4.8-23.3 ng/mL'),
              _buildNumericField('Vitamin D3', _vitD3Controller,
                  suffix: 'ng/mL', hint: 'Normal: 20-50 ng/mL'),
              _buildNumericField('Progesterone', _prgController,
                  suffix: 'ng/mL', hint: 'Normal: 5-20 ng/mL'),
              _buildNumericField('Beta HCG-1', _betaHcg1Controller,
                  suffix: 'mIU/mL', hint: 'Non-pregnant: <5 mIU/mL'),
              _buildNumericField('Beta HCG-2', _betaHcg2Controller,
                  suffix: 'mIU/mL', hint: 'Non-pregnant: <5 mIU/mL'),
              const SizedBox(height: 16),
              const Text(
                'Ultrasound Findings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildNumericField(
                  'Left Ovary Follicle Count', _follicleLController,
                  hint: 'Normal: 8-15 follicles'),
              _buildNumericField(
                  'Right Ovary Follicle Count', _follicleRController,
                  hint: 'Normal: 8-15 follicles'),
              _buildNumericField('Left Follicle Size', _avgFSizeLController,
                  suffix: 'mm', hint: 'Normal: 2-10 mm'),
              _buildNumericField('Right Follicle Size', _avgFSizeRController,
                  suffix: 'mm', hint: 'Normal: 2-10 mm'),
              _buildNumericField(
                  'Endometrium Thickness', _endometriumController,
                  suffix: 'mm', hint: 'Normal: 4-8 mm pre-ovulation'),
              const SizedBox(height: 16),
              const Text(
                'Additional Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildNumericField('Marriage Status', _marriageStatusController,
                  suffix: 'years'),
              _buildNumericField('Number of Abortions', _abortionsController),
              _buildNumericField('Random Blood Sugar', _rbsController,
                  suffix: 'mg/dl', hint: 'Normal: 70-140 mg/dl'),
              const SizedBox(height: 16),
              const Text(
                'Symptoms & Lifestyle',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._booleanFields.keys
                  .map((String key) => _buildBooleanField(key)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.all(16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Calculate Risk',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
              if (_predictionResult != null) ...[
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _predictionResult!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_stage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Stage: $_stage',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],

                        // Recommendations based on risk level
                        if (_stage != null) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Ovarian Cyst Management Guidelines',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Note: These recommendations are for general guidance. Always consult with your healthcare provider for personalized advice.',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Risk Level: $_stage',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _stage == 'Low Risk'
                                  ? Colors.green
                                  : _stage == 'Moderate Risk'
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (_stage == 'Low Risk') ...[
                            _buildRecommendationSection(
                              'Regular Monitoring 🔍',
                              [
                                '📅 Schedule follow-up ultrasound in 4-6 weeks',
                                '📝 Track any pelvic pain or discomfort',
                                '📊 Monitor menstrual cycle changes',
                                '🌡️ Record any new symptoms',
                                '⚕️ Report changes to your healthcare provider',
                              ],
                            ),
                            _buildRecommendationSection(
                              'Lifestyle Management 🌱',
                              [
                                '🚶‍♀️ Gentle exercise (30 minutes daily):',
                                '  • 🏊‍♀️ Swimming',
                                '  • 🧘‍♀️ Yoga',
                                '  • 🚶‍♀️ Walking',
                                '💆‍♀️ Practice stress-reducing activities',
                                '😴 Maintain regular sleep schedule (7-9 hours)',
                                '🥗 Follow anti-inflammatory diet',
                                '� Stay well hydrated (8-10 glasses daily)',
                              ],
                            ),
                            _buildRecommendationSection(
                              'Pain Management & Prevention 💊',
                              [
                                '🌡️ Use warm compresses for discomfort',
                                '� Over-the-counter pain relief options:',
                                '  • 💊 Ibuprofen (400-600mg as needed)',
                                '  • 💊 Acetaminophen (500-1000mg)',
                                '🧘‍♀️ Gentle pelvic floor exercises',
                                '🛋️ Rest when needed',
                              ],
                            ),
                            _buildRecommendationSection(
                              'Supplements & Natural Support 🌿',
                              [
                                '💊 Recommended daily supplements:',
                                '  • 🍊 Vitamin D3 (2000-4000 IU)',
                                '  • 🐟 Omega-3 fatty acids (1000mg)',
                                '  • 🍎 Magnesium (300-400mg)',
                                '  • 🥑 Vitamin B-complex',
                                '🫖 Limit caffeine intake',
                                '🌿 Herbal support:',
                                '  • 🍵 Spearmint tea',
                                '  • 🍃 Green tea',
                                '  • 🌺 Chamomile for relaxation',
                              ],
                            ),
                            _buildRecommendationSection(
                              'Monitoring 📊',
                              [
                                '📝 Track menstrual cycles using an app',
                                '⚖️ Monitor weight changes weekly',
                                '🌡️ Note any new symptoms',
                                '📱 Use fertility tracking apps if planning pregnancy',
                                '💭 Keep mood and energy journal',
                              ],
                            ),
                            _buildRecommendationSection(
                              'Preventive Care & Supplements 🛡️',
                              [
                                '💊 Recommended daily supplements:',
                                '  • 🍊 Vitamin D3 (2000-4000 IU daily)',
                                '  • 🌿 Omega-3 fatty acids (1000mg daily)',
                                '  • 🍎 Magnesium (300-400mg daily)',
                                '  • 🥑 Vitamin B-complex',
                                '🫖 Limit caffeine intake',
                                '🧘‍♀️ Practice stress management',
                                '🌿 Consider herbal teas (spearmint, green tea)',
                              ],
                            ),
                          ] else if (_stage == 'Moderate Risk') ...[
                            _buildRecommendationSection(
                              'Medical Evaluation Priority 🏥',
                              [
                                '👩‍⚕️ Schedule specialist consultations:',
                                '  • 🏥 Gynecologist (within 2 weeks)',
                                '  • 📊 Endocrinologist if needed',
                                '🔬 Essential medical tests:',
                                '  • 📸 Transvaginal ultrasound',
                                '  • 🩸 Complete hormone panel',
                                '  • � CA-125 blood test',
                                '  • � Detailed pelvic examination',
                                '� Keep symptom diary with details:',
                                '  • � Pain intensity (scale 1-10)',
                                '  • 🕒 Symptom timing and duration',
                                '  • � Associated symptoms',
                              ],
                            ),
                            _buildRecommendationSection(
                              'Treatment Protocol �',
                              [
                                '💊 Medication management:',
                                '  • 💊 Prescribed pain medication regimen',
                                '  • 💊 Hormonal therapy options',
                                '  • 🌡️ Anti-inflammatory medications',
                                '🏥 Pain management strategies:',
                                '  • 🔥 Heat therapy (20 min, 3x daily)',
                                '  • 💆‍♀️ Physical therapy sessions',
                                '  • 🧘‍♀️ Relaxation techniques',
                                '📊 Monitoring requirements:',
                                '  • � Daily symptom tracking',
                                '  • 📅 Weekly progress assessment',
                                '  • 🔄 Monthly follow-up visits',
                              ],
                            ),
                            _buildRecommendationSection(
                              'Lifestyle Changes 🔄',
                              [
                                '🏋️‍♀️ Modified exercise routine:',
                                '  • 💪 Strength training (3x weekly)',
                                '  • 🚶‍♀️ Daily walking (45-60 minutes)',
                                '  • 🧘‍♀️ Yoga for hormone balance',
                                '🥗 Anti-inflammatory diet guide:',
                                '  • ✅ Increase: leafy greens, lean proteins',
                                '  • ❌ Avoid: processed foods, refined sugars',
                              ],
                            ),
                          ] else ...[
                            // High Risk
                            _buildRecommendationSection(
                              'Urgent Medical Attention 🚨',
                              [
                                '🏥 Immediate specialist consultation needed',
                                '📋 Required evaluations:',
                                '  • 📸 Advanced imaging (MRI/CT)',
                                '  • 🩸 Complete blood work',
                                '  • 💉 Tumor marker tests',
                                '  • 🔬 Biopsy if needed',
                              ],
                            ),
                            _buildRecommendationSection(
                              'Treatment Protocol 🏥',
                              [
                                '👩‍⚕️ Medical management:',
                                '  • 💉 Prescribed medications',
                                '  • 🌡️ Pain management protocol',
                                '  • 🔄 Hormone therapy',
                                '  • 🎯 Surgical options if needed',
                              ],
                            ),
                            _buildRecommendationSection(
                              'Emergency Guidelines 🚑',
                              [
                                '🚨 Seek immediate care if you experience:',
                                '  • 😫 Severe abdominal pain',
                                '  • 🤢 Severe vomiting',
                                '  • 😵 Fainting or dizziness',
                                '  • 🌡️ High fever',
                                '  • 💫 Sudden severe pain',
                              ],
                            ),
                            _buildRecommendationSection(
                              'Follow-up Care 📋',
                              [
                                '📅 Regular monitoring schedule',
                                '📊 Track symptoms and changes',
                                '👥 Join support groups',
                                '🧠 Mental health support',
                                '👶 Fertility preservation options',
                              ],
                            ),
                          ],

                          // General Guidelines for all risk levels
                          const SizedBox(height: 24),
                          _buildRecommendationSection(
                            'General Guidelines ℹ️',
                            [
                              '🏥 Keep all scheduled medical appointments',
                              '📝 Document any changes in symptoms',
                              '🚫 Avoid strenuous activities when in pain',
                              '💊 Take prescribed medications as directed',
                              '📱 Use symptom tracking apps',
                              '🆘 Know when to seek emergency care',
                            ],
                          ),
                        ],

                        if (_featureContributions != null &&
                            _featureContributions!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Top Contributing Factors:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._featureContributions!.entries.take(5).map(
                                (e) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(e.key),
                                      ),
                                      Text(
                                        '${(e.value * 100).toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
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
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose all controllers
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _bmiController.dispose();
    _pulseRateController.dispose();
    _rrController.dispose();
    _hbController.dispose();
    _cycleLengthController.dispose();
    _marriageStatusController.dispose();
    _abortionsController.dispose();
    _betaHcg1Controller.dispose();
    _betaHcg2Controller.dispose();
    _fshController.dispose();
    _lhController.dispose();
    _hipController.dispose();
    _waistController.dispose();
    _tshController.dispose();
    _amhController.dispose();
    _prlController.dispose();
    _vitD3Controller.dispose();
    _prgController.dispose();
    _rbsController.dispose();
    _bpSystolicController.dispose();
    _bpDiastolicController.dispose();
    _follicleLController.dispose();
    _follicleRController.dispose();
    _avgFSizeLController.dispose();
    _avgFSizeRController.dispose();
    _endometriumController.dispose();
    super.dispose();
  }
}
