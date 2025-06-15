import 'package:flutter/material.dart';
import 'package:ovarian_cyst_support_app/constants.dart';
import 'package:ovarian_cyst_support_app/services/ml_prediction_service.dart';

class OvarianCystPredictionScreen extends StatefulWidget {
  const OvarianCystPredictionScreen({super.key});

  @override
  State<OvarianCystPredictionScreen> createState() =>
      _OvarianCystPredictionScreenState();
}

class _OvarianCystPredictionScreenState
    extends State<OvarianCystPredictionScreen> {
  bool _isLoading = false;
  final MLPredictionService _mlService = MLPredictionService();

  // Simple information message to guide users
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('About PCOS Risk Assessment'),
        content: const SingleChildScrollView(
          child: ListBody(
            children: [
              Text(
                'This tool helps assess your risk of having Polycystic Ovary Syndrome (PCOS).',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'When you click "Continue to Assessment", you\'ll be taken to our AI-powered prediction tool that will:',
              ),
              SizedBox(height: 8),
              Text('• Ask for your health information'),
              Text('• Analyze your risk factors'),
              Text('• Provide personalized recommendations'),
              SizedBox(height: 16),
              Text(
                'All information is processed securely and not stored permanently.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Open the Streamlit UI in WebView
  void _openPredictionUI() {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the WebView approach to show prediction UI
      _mlService.showPredictionUI(context);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PCOS Risk Assessment'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),

            // Information card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.medical_services_outlined,
                          color: AppColors.primary,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'PCOS Risk Assessment Tool',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'This tool uses artificial intelligence to assess your risk of having Polycystic Ovary Syndrome (PCOS) based on your medical information and symptoms.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Benefits of assessment:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Early detection of potential PCOS',
                      style: TextStyle(fontSize: 16),
                    ),
                    const Text(
                      '• Personalized risk assessment',
                      style: TextStyle(fontSize: 16),
                    ),
                    const Text(
                      '• Customized recommendations',
                      style: TextStyle(fontSize: 16),
                    ),
                    const Text(
                      '• Better informed healthcare decisions',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),

                    // Action button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _openPredictionUI,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Continue to Assessment',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Disclaimer section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.shade50,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Important Disclaimer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This tool is not a substitute for professional medical advice, diagnosis, or treatment. Always consult with a qualified healthcare provider for any medical conditions.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
