import 'package:flutter/material.dart';
import 'package:ovarian_cyst_support_app/models/treatment_item.dart';
import 'package:ovarian_cyst_support_app/services/database_service.dart';
import 'package:ovarian_cyst_support_app/services/firestore_database_service.dart';
import 'package:ovarian_cyst_support_app/services/sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';

// Create an alias for backward compatibility
typedef TreatmentType = TreatmentItemType;

class InventoryManagementScreen extends StatefulWidget {
  final String? facilityId;
  final bool isAdmin;

  const InventoryManagementScreen({
    super.key,
    this.facilityId,
    this.isAdmin = false,
  });

  @override
  State<InventoryManagementScreen> createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  final DatabaseService _databaseService = FirestoreDatabaseService();
  final SyncService _syncService = SyncService();

  List<TreatmentItem> _inventory = [];
  List<TreatmentItem> _filteredInventory = [];
  bool _isLoading = true;
  bool _isOffline = false;
  String _errorMessage = '';
  String _searchQuery = '';

  // Filter state
  String _selectedType = 'All Types';
  bool _showLowStock = false;
  bool _requiresPrescription = false;

  // Get display text for type enum
  String getTypeString(TreatmentItemType type) {
    switch (type) {
      case TreatmentItemType.medication:
        return 'Medication';
      case TreatmentItemType.therapy:
        return 'Therapy';
      case TreatmentItemType.surgery:
        return 'Surgery';
      case TreatmentItemType.consultation:
        return 'Consultation';
      case TreatmentItemType.procedure:
        return 'Procedure';
      case TreatmentItemType.equipment:
        return 'Equipment';
      case TreatmentItemType.service:
        return 'Service';
      case TreatmentItemType.test:
        return 'Test';
      case TreatmentItemType.other:
        return 'Other';
    }
  }

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadInventory();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = connectivityResult.contains(ConnectivityResult.none);
    });

    // Listen for connectivity changes
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      setState(() {
        _isOffline = results.contains(ConnectivityResult.none);
      });

      if (!_isOffline) {
        // Sync data when back online
        _syncInventoryData();
      }
    });
  }

  Future<void> _loadInventory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final items = await _databaseService.getTreatmentItems(
        facilityId: widget.facilityId,
      );

      setState(() {
        _inventory = items;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading inventory: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _syncInventoryData() async {
    if (!_isOffline) {
      await _syncService.manualSync();
      _loadInventory();
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredInventory = _inventory.where((item) {
        // Apply type filter
        if (_selectedType != 'All Types' &&
            getTypeString(item.type) != _selectedType) {
          return false;
        }

        // Apply low stock filter
        if (_showLowStock && (item.stockLevel ?? 0) > 10) {
          return false;
        }

        // Apply prescription filter
        if (_requiresPrescription && !item.requiresPrescription) {
          return false;
        }

        // Apply search query
        if (_searchQuery.isNotEmpty) {
          final String query = _searchQuery.toLowerCase();
          return item.name.toLowerCase().contains(query) ||
              item.description.toLowerCase().contains(query) ||
              (item.manufacturer?.toLowerCase().contains(query) ?? false);
        }

        return true;
      }).toList();
    });
  }

  void _searchInventory(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  Future<void> _updateItemStock(TreatmentItem item, int newStock) async {
    try {
      // Create a copy with updated stock
      final updatedItem = TreatmentItem(
        id: item.id,
        name: item.name,
        type: item.type,
        description: item.description,
        cost: item.cost,
        requiresPrescription: item.requiresPrescription,
        stockLevel: newStock,
        facilityId: item.facilityId,
        manufacturer: item.manufacturer,
        dosageInfo: item.dosageInfo,
        sideEffects: item.sideEffects,
      );

      // Save to database
      await _databaseService.saveTreatmentItem(updatedItem);

      // Refresh inventory
      _loadInventory();

      _showMessage('Stock updated successfully');
    } catch (e) {
      _showMessage('Error updating stock: ${e.toString()}');
    }
  }

  Future<void> _addNewItem() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TreatmentItemForm(facilityId: widget.facilityId),
      ),
    );

    if (result == true) {
      // Refresh inventory if an item was added
      _loadInventory();
    }
  }

  Future<void> _editItem(TreatmentItem item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TreatmentItemForm(
          facilityId: widget.facilityId,
          editItem: item,
        ),
      ),
    );

    if (result == true) {
      // Refresh inventory if the item was edited
      _loadInventory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _isOffline ? null : _syncInventoryData,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterBottomSheet();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline indicator
          if (_isOffline)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  Icon(Icons.wifi_off, size: 20, color: Colors.orange.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You\'re offline. Changes will be synced when you reconnect.',
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search inventory...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onChanged: _searchInventory,
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('All'),
                _buildFilterChip('Medication'),
                _buildFilterChip('Procedure'),
                _buildFilterChip('Equipment'),
                _buildFilterChip('Supplies'),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Low Stock'),
                  selected: _showLowStock,
                  onSelected: (selected) {
                    setState(() {
                      _showLowStock = selected;
                      _applyFilters();
                    });
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: Colors.red.withAlpha((0.2 * 255).toInt()),
                  labelStyle: TextStyle(
                    color: _showLowStock ? Colors.red : Colors.black87,
                    fontWeight:
                        _showLowStock ? FontWeight.bold : FontWeight.normal,
                  ),
                  checkmarkColor: Colors.red,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Prescription Only'),
                  selected: _requiresPrescription,
                  onSelected: (selected) {
                    setState(() {
                      _requiresPrescription = selected;
                      _applyFilters();
                    });
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: Colors.purple.withAlpha((0.2 * 255).toInt()),
                  labelStyle: TextStyle(
                    color:
                        _requiresPrescription ? Colors.purple : Colors.black87,
                    fontWeight: _requiresPrescription
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  checkmarkColor: Colors.purple,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Inventory list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadInventory,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredInventory.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.inventory_2,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No inventory items found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your filters or add new items',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 16),
                                if (widget.isAdmin)
                                  ElevatedButton.icon(
                                    onPressed: _addNewItem,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Item'),
                                  ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredInventory.length,
                            padding: const EdgeInsets.all(8),
                            itemBuilder: (context, index) {
                              final item = _filteredInventory[index];
                              return _buildInventoryItemCard(item);
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              onPressed: _addNewItem,
              tooltip: 'Add Item',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected =
        label == 'All' ? _selectedType == 'All Types' : _selectedType == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedType =
                selected ? (label == 'All' ? 'All Types' : label) : 'All Types';
            _applyFilters();
          });
        },
        backgroundColor: Colors.grey[100],
        selectedColor: Theme.of(
          context,
        ).primaryColor.withAlpha((0.2 * 255).toInt()),
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildInventoryItemCard(TreatmentItem item) {
    // Determine stock level color
    Color stockColor;
    if ((item.stockLevel ?? 0) <= 0) {
      stockColor = Colors.red;
    } else if ((item.stockLevel ?? 0) < 10) {
      stockColor = Colors.orange;
    } else {
      stockColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Item name and badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (item.requiresPrescription)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.withAlpha(
                                  (0.1 * 255).toInt(),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Prescription',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple[700],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        getTypeString(item.type),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // Cost
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormat.currency(
                        symbol: 'KES ',
                        decimalDigits: 0,
                      ).format(item.cost),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: stockColor.withAlpha((0.1 * 255).toInt()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Stock: ${item.stockLevel}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: stockColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Description
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.description,
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Additional info
            if (item.manufacturer != null || item.dosageInfo != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (item.manufacturer != null) ...[
                    Icon(Icons.business, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      item.manufacturer!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (item.dosageInfo != null) ...[
                    Icon(
                      Icons.medical_information,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.dosageInfo!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ],

            // Actions
            if (widget.isAdmin) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      _showStockUpdateDialog(item);
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Update Stock'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      _editItem(item);
                    },
                    icon: const Icon(Icons.edit_note, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Filter Inventory',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Type filter
                  const Text(
                    'Item Type',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All Types'),
                        selected: _selectedType == 'All Types',
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = 'All Types';
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Medication'),
                        selected: _selectedType == 'Medication',
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = 'Medication';
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Procedure'),
                        selected: _selectedType == 'Procedure',
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = 'Procedure';
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Equipment'),
                        selected: _selectedType == 'Equipment',
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = 'Equipment';
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Supplies'),
                        selected: _selectedType == 'Supplies',
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = 'Supplies';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stock filter
                  CheckboxListTile(
                    title: const Text('Show only low stock items'),
                    value: _showLowStock,
                    onChanged: (value) {
                      setState(() {
                        _showLowStock = value ?? false;
                      });
                    },
                  ),

                  // Prescription filter
                  CheckboxListTile(
                    title: const Text('Prescription only items'),
                    value: _requiresPrescription,
                    onChanged: (value) {
                      setState(() {
                        _requiresPrescription = value ?? false;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedType = 'All Types';
                            _showLowStock = false;
                            _requiresPrescription = false;
                          });
                        },
                        child: const Text('Reset'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          this.setState(() {
                            _selectedType = _selectedType;
                            _showLowStock = _showLowStock;
                            _requiresPrescription = _requiresPrescription;
                            _applyFilters();
                          });
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showStockUpdateDialog(TreatmentItem item) {
    int newStock = item.stockLevel ?? 0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Stock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Current Stock:'),
                  const Spacer(),
                  Text(
                    '${item.stockLevel}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (newStock > 0) newStock--;
                      });
                    },
                    icon: const Icon(Icons.remove_circle),
                  ),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        labelText: 'New Stock Level',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          newStock =
                              int.tryParse(value) ?? item.stockLevel ?? 0;
                        });
                      },
                      controller: TextEditingController(
                        text: newStock.toString(),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        newStock++;
                      });
                    },
                    icon: const Icon(Icons.add_circle),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateItemStock(item, newStock);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}

// Form to add/edit treatment items
class TreatmentItemForm extends StatefulWidget {
  final String? facilityId;
  final TreatmentItem? editItem;

  const TreatmentItemForm({super.key, this.facilityId, this.editItem});

  @override
  State<TreatmentItemForm> createState() => _TreatmentItemFormState();
}

class _TreatmentItemFormState extends State<TreatmentItemForm> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = FirestoreDatabaseService();

  late String _name;
  late TreatmentType _type;
  late String _description;
  late double _cost;
  late bool _requiresPrescription;
  late int _stockLevel;
  String? _manufacturer;
  String? _dosageInfo;
  List<String> _sideEffects = [];

  bool _isLoading = false;

  final TextEditingController _sideEffectController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // If editing, initialize with existing item data
    if (widget.editItem != null) {
      _name = widget.editItem!.name;
      _type = widget.editItem!.type;
      _description = widget.editItem!.description;
      _cost = widget.editItem!.cost ?? 0.0;
      _requiresPrescription = widget.editItem!.requiresPrescription;
      _stockLevel = widget.editItem!.stockLevel ?? 0;
      _manufacturer = widget.editItem!.manufacturer;
      _dosageInfo = widget.editItem!.dosageInfo;
      _sideEffects = widget.editItem!.sideEffects ?? [];
    } else {
      // Default values for new item
      _name = '';
      _type = TreatmentType.medication;
      _description = '';
      _cost = 0.0;
      _requiresPrescription = false;
      _stockLevel = 0;
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final item = TreatmentItem(
        id: widget.editItem?.id ??
            'item_${DateTime.now().millisecondsSinceEpoch}',
        name: _name,
        type: _type,
        description: _description,
        cost: _cost,
        requiresPrescription: _requiresPrescription,
        stockLevel: _stockLevel,
        facilityId: widget.facilityId ?? 'default_facility',
        manufacturer: _manufacturer,
        dosageInfo: _dosageInfo,
        sideEffects: _sideEffects.isNotEmpty ? _sideEffects : null,
      );

      await _databaseService.saveTreatmentItem(item);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _showMessage('Error saving item: ${e.toString()}');
    }
  }

  void _addSideEffect() {
    final sideEffect = _sideEffectController.text.trim();
    if (sideEffect.isNotEmpty) {
      setState(() {
        _sideEffects.add(sideEffect);
        _sideEffectController.clear();
      });
    }
  }

  void _removeSideEffect(int index) {
    setState(() {
      _sideEffects.removeAt(index);
    });
  }

  @override
  void dispose() {
    _sideEffectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editItem != null ? 'Edit Item' : 'Add New Item'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(
                labelText: 'Item Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter item name';
                }
                return null;
              },
              onSaved: (value) {
                _name = value!;
              },
            ),
            const SizedBox(height: 16),

            // Type
            DropdownButtonFormField<TreatmentType>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Item Type *',
                border: OutlineInputBorder(),
              ),
              items: TreatmentType.values.map((type) {
                return DropdownMenuItem<TreatmentType>(
                  value: type,
                  child: Text(_getTreatmentTypeString(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _type = value!;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a type';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              initialValue: _description,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
              onSaved: (value) {
                _description = value!;
              },
            ),
            const SizedBox(height: 16),

            // Cost
            TextFormField(
              initialValue: _cost.toString(),
              decoration: const InputDecoration(
                labelText: 'Cost (KES) *',
                border: OutlineInputBorder(),
                prefixText: 'KES ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a cost';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
              onSaved: (value) {
                _cost = double.parse(value!);
              },
            ),
            const SizedBox(height: 16),

            // Stock Level
            TextFormField(
              initialValue: _stockLevel.toString(),
              decoration: const InputDecoration(
                labelText: 'Stock Level *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter stock level';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
              onSaved: (value) {
                _stockLevel = int.parse(value!);
              },
            ),
            const SizedBox(height: 16),

            // Prescription Required
            SwitchListTile(
              title: const Text('Requires Prescription'),
              subtitle: const Text(
                'Item can only be dispensed with a valid prescription',
              ),
              value: _requiresPrescription,
              onChanged: (value) {
                setState(() {
                  _requiresPrescription = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Manufacturer (optional)
            TextFormField(
              initialValue: _manufacturer,
              decoration: const InputDecoration(
                labelText: 'Manufacturer',
                border: OutlineInputBorder(),
                helperText: 'Optional',
              ),
              onSaved: (value) {
                _manufacturer = value!.trim().isEmpty ? null : value;
              },
            ),
            const SizedBox(height: 16),

            // Dosage Info (optional)
            TextFormField(
              initialValue: _dosageInfo,
              decoration: const InputDecoration(
                labelText: 'Dosage Information',
                border: OutlineInputBorder(),
                helperText: 'Optional',
              ),
              onSaved: (value) {
                _dosageInfo = value!.trim().isEmpty ? null : value;
              },
            ),
            const SizedBox(height: 16),

            // Side Effects (optional)
            const Text(
              'Side Effects',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sideEffectController,
                    decoration: const InputDecoration(
                      labelText: 'Add Side Effect',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: _addSideEffect,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _sideEffects.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'No side effects added',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    children: List.generate(
                      _sideEffects.length,
                      (index) => Chip(
                        label: Text(_sideEffects[index]),
                        deleteIcon: const Icon(Icons.cancel, size: 16),
                        onDeleted: () => _removeSideEffect(index),
                      ),
                    ),
                  ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveItem,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.editItem != null ? 'Update Item' : 'Add Item',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTreatmentTypeString(TreatmentType type) {
    switch (type) {
      case TreatmentType.medication:
        return 'Medication';
      case TreatmentType.therapy:
        return 'Therapy';
      case TreatmentType.surgery:
        return 'Surgery';
      case TreatmentType.consultation:
        return 'Consultation';
      case TreatmentType.procedure:
        return 'Procedure';
      case TreatmentType.equipment:
        return 'Equipment';
      case TreatmentType.service:
        return 'Service';
      case TreatmentType.test:
        return 'Test';
      case TreatmentType.other:
        return 'Other';
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }
}
