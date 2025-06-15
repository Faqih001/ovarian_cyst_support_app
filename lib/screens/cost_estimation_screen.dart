import 'package:flutter/material.dart';
import 'package:ovarian_cyst_support_app/services/payment_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';

class CostEstimationScreen extends StatefulWidget {
  const CostEstimationScreen({super.key});

  @override
  State<CostEstimationScreen> createState() => _CostEstimationScreenState();
}

class _CostEstimationScreenState extends State<CostEstimationScreen> {
  final PaymentService _paymentService = PaymentService();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isOffline = false;
  // _errorMessage removed as it was unused

  // Selected services, treatments, etc.
  String _selectedTreatmentType = 'Regular Checkup';
  String _selectedFacility = 'Public Hospital';
  String _selectedLocation = 'Nairobi';
  final List<String> _selectedProcedures = [];

  // Treatment types
  final List<String> _treatmentTypes = [
    'Regular Checkup',
    'Diagnostic Services',
    'Minor Cyst Removal',
    'Major Surgery',
    'Follow-up Visit',
  ];

  // Facility types
  final List<String> _facilityTypes = [
    'Public Hospital',
    'Private Hospital',
    'Specialized Clinic',
    'Mission Hospital',
  ];

  // Locations
  final List<String> _locations = [
    'Nairobi',
    'Mombasa',
    'Kisumu',
    'Nakuru',
    'Eldoret',
    'Other',
  ];

  // Available procedures
  List<Map<String, dynamic>> _availableProcedures = [];

  // Cost summary
  double _baseCost = 0.0;
  double _proceduresCost = 0.0;
  double _medicationCost = 0.0;
  double _estimatedTotal = 0.0;

  // Payment history
  List<Map<String, dynamic>> _paymentHistory = [];
  bool _loadingHistory = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadProcedures();
    _loadPaymentHistory();
    _calculateEstimate();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResults = await Connectivity().checkConnectivity();
    setState(() {
      // Check if we're offline - when the list is empty or contains only ConnectivityResult.none
      _isOffline = connectivityResults.isEmpty ||
          (connectivityResults.contains(ConnectivityResult.none) &&
              connectivityResults.length == 1);
    });

    // Listen for connectivity changes
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      setState(() {
        _isOffline = results.isEmpty ||
            (results.contains(ConnectivityResult.none) && results.length == 1);
      });

      if (!_isOffline) {
        // Refresh data when back online
        _loadProcedures();
        _loadPaymentHistory();
      }
    });
  }

  Future<void> _loadProcedures() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // This would be replaced with an API call to get available procedures based on selections
      // Simulating a network delay
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _availableProcedures = [
          {
            'name': 'Ultrasound',
            'cost': 2000.0,
            'description': 'Pelvic ultrasound to visualize cysts',
          },
          {
            'name': 'Blood Tests',
            'cost': 1500.0,
            'description': 'Complete blood count, hormone tests',
          },
          {
            'name': 'Consultation',
            'cost': 1000.0,
            'description': 'Specialist consultation',
          },
          {
            'name': 'MRI Scan',
            'cost': 10000.0,
            'description': 'Detailed imaging of pelvic region',
          },
          {
            'name': 'Laparoscopy',
            'cost': 30000.0,
            'description': 'Minimally invasive diagnostic procedure',
          },
          {
            'name': 'Medication (1 month)',
            'cost': 3000.0,
            'description': 'Pain management and hormone therapy',
          },
        ];

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('Failed to load procedures. Please try again.');
    }
  }

  Future<void> _loadPaymentHistory() async {
    setState(() {
      _loadingHistory = true;
    });

    try {
      final paymentHistory = await _paymentService.getPaymentHistory();

      setState(() {
        _paymentHistory = paymentHistory;
        _loadingHistory = false;
      });
    } catch (e) {
      setState(() {
        _loadingHistory = false;
      });
    }
  }

  void _calculateEstimate() {
    // Reset costs
    _baseCost = 0.0;
    _proceduresCost = 0.0;
    _medicationCost = 0.0;

    // Calculate base cost based on treatment type and facility
    switch (_selectedTreatmentType) {
      case 'Regular Checkup':
        _baseCost = _selectedFacility == 'Public Hospital' ? 500.0 : 1500.0;
        break;
      case 'Diagnostic Services':
        _baseCost = _selectedFacility == 'Public Hospital' ? 1000.0 : 3000.0;
        break;
      case 'Minor Cyst Removal':
        _baseCost = _selectedFacility == 'Public Hospital' ? 10000.0 : 25000.0;
        break;
      case 'Major Surgery':
        _baseCost = _selectedFacility == 'Public Hospital' ? 30000.0 : 80000.0;
        break;
      case 'Follow-up Visit':
        _baseCost = _selectedFacility == 'Public Hospital' ? 300.0 : 1000.0;
        break;
    }

    // Adjust for location
    if (_selectedLocation == 'Nairobi') {
      _baseCost *= 1.2; // 20% higher in Nairobi
    } else if (_selectedLocation == 'Mombasa') {
      _baseCost *= 1.1; // 10% higher in Mombasa
    }

    // Calculate procedures cost
    for (var procedureName in _selectedProcedures) {
      final procedure = _availableProcedures.firstWhere(
        (p) => p['name'] == procedureName,
        orElse: () => {'cost': 0.0},
      );

      if (procedure['name'] == 'Medication (1 month)') {
        _medicationCost += procedure['cost'] ?? 0;
      } else {
        _proceduresCost += procedure['cost'] ?? 0;
      }
    }

    // Calculate total
    _estimatedTotal = _baseCost + _proceduresCost + _medicationCost;

    setState(() {});
  }

  Future<void> _makePayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_estimatedTotal <= 0) {
      _showMessage('Please select services to estimate cost');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Process payment
      final paymentResult = await _paymentService.processPayment(
        _estimatedTotal,
        'USD',
        'Pre-payment for $_selectedTreatmentType at $_selectedFacility',
      );

      setState(() {
        _isLoading = false;
      });

      // Show payment result
      if (paymentResult['success']) {
        _showMessage(
          'Payment request sent. Please check your phone to complete.',
        );

        // Reload payment history after a delay to allow processing
        Future.delayed(const Duration(seconds: 3), () {
          _loadPaymentHistory();
        });
      } else {
        _showMessage('Payment failed: ${paymentResult['message']}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _showMessage('Payment error: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cost Estimation'), elevation: 0),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Offline indicator
            if (_isOffline)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.wifi_off,
                      size: 20,
                      color: Colors.orange.shade800,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You\'re offline. Estimates may not be accurate.',
                        style: TextStyle(color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ),
              ),

            // Treatment type selection
            const Text(
              'Treatment Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedTreatmentType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              items: _treatmentTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTreatmentType = value;
                    _calculateEstimate();
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Facility type selection
            const Text(
              'Facility Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedFacility,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              items: _facilityTypes.map((facility) {
                return DropdownMenuItem<String>(
                  value: facility,
                  child: Text(facility),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFacility = value;
                    _calculateEstimate();
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Location selection
            const Text(
              'Location',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedLocation,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              items: _locations.map((location) {
                return DropdownMenuItem<String>(
                  value: location,
                  child: Text(location),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedLocation = value;
                    _calculateEstimate();
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            // Procedures selection
            const Text(
              'Select Procedures & Services',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Column(
                    children: _availableProcedures.map((procedure) {
                      final isSelected = _selectedProcedures.contains(
                        procedure['name'],
                      );

                      return CheckboxListTile(
                        title: Text(procedure['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              procedure['description'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              PaymentService.formatCurrency(
                                procedure['cost'] ?? 0,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        value: isSelected,
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedProcedures.add(procedure['name']);
                            } else {
                              _selectedProcedures.remove(procedure['name']);
                            }
                            _calculateEstimate();
                          });
                        },
                        activeColor: Theme.of(context).primaryColor,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 24),

            // Cost summary
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estimated Cost Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Base Cost ($_selectedTreatmentType)'),
                        Text(
                          PaymentService.formatCurrency(_baseCost),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Procedures & Tests'),
                        Text(
                          PaymentService.formatCurrency(_proceduresCost),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Medication'),
                        Text(
                          PaymentService.formatCurrency(_medicationCost),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Estimated Total',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          PaymentService.formatCurrency(_estimatedTotal),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info,
                                color: Colors.blue.shade700,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Important Note',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This is an estimate only. Actual costs may vary based on your specific medical needs, insurance coverage, and unforeseen complications.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Pre-payment section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Make a Pre-payment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pre-paying for your treatment can help you budget and reduce wait times. You can pay the full amount or a deposit.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'M-Pesa Phone Number *',
                        hintText: 'e.g., 254712345678',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter phone number';
                        }
                        // Simple validation for Kenya numbers
                        if (!value.startsWith('254') || value.length != 12) {
                          return 'Enter valid number format: 254XXXXXXXXX';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _makePayment,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Pay Now',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Payment history
            const Text(
              'Payment History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _loadingHistory
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _paymentHistory.isEmpty
                    ? const Card(
                        elevation: 1,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'No payment history available',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: _paymentHistory.map((payment) {
                          final status = payment['status'] ?? 'pending';
                          final timestamp =
                              DateTime.parse(payment['timestamp']);
                          final amount = payment['amount'] ?? 0.0;
                          final description =
                              payment['description'] ?? 'Payment';

                          // Set status color
                          Color statusColor;
                          switch (status) {
                            case 'completed':
                              statusColor = Colors.green;
                              break;
                            case 'failed':
                              statusColor = Colors.red;
                              break;
                            case 'processing':
                              statusColor = Colors.orange;
                              break;
                            default:
                              statusColor = Colors.blue;
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(description),
                              subtitle: Text(
                                DateFormat(
                                  'MMM d, yyyy - h:mm a',
                                ).format(timestamp),
                              ),
                              trailing: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    PaymentService.formatCurrency(amount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withAlpha(
                                        25,
                                      ), // Replaced withOpacity(0.1)
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                // Show payment details
                                _showPaymentDetails(payment);
                              },
                            ),
                          );
                        }).toList(),
                      ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showPaymentDetails(Map<String, dynamic> payment) {
    final status = payment['status'] ?? 'pending';
    final timestamp = DateTime.parse(payment['timestamp']);
    final amount = payment['amount'] ?? 0.0;
    final description = payment['description'] ?? 'Payment';
    final transactionId = payment['transactionId'] ?? 'Not available';
    final phoneNumber = payment['phoneNumber'] ?? 'Not available';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildDetailRow(
                'Date',
                DateFormat('MMM d, yyyy').format(timestamp),
              ),
              _buildDetailRow('Time', DateFormat('h:mm a').format(timestamp)),
              _buildDetailRow('Amount', PaymentService.formatCurrency(amount)),
              _buildDetailRow('Description', description),
              _buildDetailRow('Transaction ID', transactionId),
              _buildDetailRow('Phone Number', phoneNumber),
              _buildDetailRow('Status', status.toUpperCase()),
              const SizedBox(height: 20),
              if (status == 'completed')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Generate receipt
                      _generateReceipt(transactionId);
                    },
                    child: const Text('View Receipt'),
                  ),
                ),
              if (status == 'failed' || status == 'pending')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Retry payment
                      Navigator.pop(context);
                      _phoneController.text = phoneNumber;
                      _makePayment();
                    },
                    child: const Text('Retry Payment'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateReceipt(String transactionId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final receiptUrl = await _paymentService.getPaymentReceipt(transactionId);

      setState(() {
        _isLoading = false;
      });

      // Check if widget is still mounted after async operation
      if (!mounted) return;

      // Close bottom sheet
      Navigator.pop(context);

      // Show receipt or URL
      _showMessage('Receipt generated: $receiptUrl');

      // In a real app, this would open the receipt in a webview or PDF viewer
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('Failed to generate receipt: ${e.toString()}');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }
}
