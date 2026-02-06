import 'package:flutter/material.dart';
import '../../shared/models/pantry_item.dart';
import '../../shared/models/scanned_product.dart';
import '../../shared/services/pantry_service.dart';
import '../../shared/services/barcode_service.dart';
import '../scanner/barcode_scanner_screen.dart';
import '../scanner/bill_scanner_screen.dart';
import '../scanner/package_scan_screen.dart';

class AddItemScreen extends StatefulWidget {
  final PantryItem? editItem;
  final ScannedProduct? scannedProduct;
  
  const AddItemScreen({super.key, this.editItem, this.scannedProduct});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final PantryService _pantryService = PantryService();
  final BarcodeService _barcodeService = BarcodeService();
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  String _selectedCategory = 'Select category';
  DateTime? _selectedDate;
  int _quantity = 1;
  bool _showExpiryWarning = false;

  final List<String> _quickAddItems = ['Milk', 'Bread', 'Eggs', 'Butter', 'Cheese', 'Yogurt', 'Tomatoes', 'Onion'];
  final List<String> _categories = ['Vegetable', 'Fruit', 'Grain', 'Dairy', 'Meat', 'Packaged', 'Frozen', 'Beverages', 'Spices', 'Other'];

  bool get _isEditing => widget.editItem != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.editItem!.name;
      _selectedCategory = widget.editItem!.category;
      _selectedDate = widget.editItem!.expiryDate;
      _quantity = widget.editItem!.quantity;
    } else if (widget.scannedProduct != null) {
      _autofillFromScan(widget.scannedProduct!);
    }
    
    // Auto-focus name field if not editing and not scanned
    if (!_isEditing && widget.scannedProduct == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_nameFocusNode);
      });
    }
  }

  void _autofillFromScan(ScannedProduct product) {
    if (product.hasProductName) {
      _nameController.text = product.productName!;
    }
    if (product.hasCategory) {
      _selectedCategory = product.category!;
    }
    if (product.hasExpiryDate) {
      _selectedDate = product.expiryDate;
    } else {
      _showExpiryWarning = true;
    }
    setState(() {});
  }

  Future<void> _scanBill() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BillScannerScreen()),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _scanBarcode() async {
    final barcodeResult = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );
    
    if (barcodeResult == null || !mounted) return;

    final String? rawValue = barcodeResult['rawValue'] as String?;
    final String? format = barcodeResult['format'] as String?;
    
    if (rawValue == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Barcode captured! Scanning package...'),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF00FF7F),
        ),
      );
    }

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final packageResult = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => PackageScanScreen(
          barcode: rawValue,
          barcodeFormat: format ?? 'UNKNOWN',
        ),
      ),
    );

    if (packageResult == null || !mounted) return;

    final String? ocrText = packageResult['ocrText'] as String?;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Processing package data...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }

    final product = await _barcodeService.parseBarcode(
      rawValue,
      format: format,
      ocrText: ocrText,
    );
    
    if (mounted) {
      _autofillFromScan(product);
      
      if (!product.hasExpiryDate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expiry date not detected. Please set manually.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  void dispose() { 
    _nameController.dispose(); 
    _nameFocusNode.dispose();
    super.dispose(); 
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context, 
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 7)), 
      firstDate: DateTime.now(), 
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _showCategoryPicker(ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context, 
      backgroundColor: colorScheme.surface, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20), 
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Text('Select Category', style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)), 
            const SizedBox(height: 16),
            SizedBox(
              height: 300, 
              child: ListView.builder(
                itemCount: _categories.length, 
                itemBuilder: (context, index) {
                  final c = _categories[index];
                  final isSelected = _selectedCategory == c;
                  return ListTile(
                    title: Text(c, style: TextStyle(color: colorScheme.onSurface)), 
                    onTap: () { 
                      setState(() => _selectedCategory = c); 
                      Navigator.pop(context); 
                    }, 
                    trailing: isSelected ? Icon(Icons.check, color: colorScheme.primary) : null
                  );
                }
              )
            ),
          ]
        )
      )
    );
  }

  void _saveItem() {
    if (_nameController.text.isEmpty) { _showError('Please enter product name'); return; }
    if (_selectedCategory == 'Select category') { _showError('Please select a category'); return; }
    if (_selectedDate == null) { _showError('Please select expiry date'); return; }

    final item = PantryItem(
      id: _isEditing ? widget.editItem!.id : _pantryService.generateId(),
      name: _nameController.text.trim(),
      category: _selectedCategory,
      expiryDate: _selectedDate!,
      quantity: _quantity,
      unit: _quantity == 1 ? 'Unit' : 'Units',
    );

    if (_isEditing) {
      _pantryService.updateItem(item);
    } else {
      _pantryService.addItem(item);
    }
    Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface, 
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: colorScheme.onSurface), onPressed: () => Navigator.pop(context)), 
        title: Text(_isEditing ? 'Edit Item' : 'Add New Item', style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w600)), 
        centerTitle: true
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!_isEditing) GestureDetector(
            onTap: _scanBarcode,
            child: Container(
              padding: const EdgeInsets.all(20), 
              decoration: BoxDecoration(gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12), 
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)), 
                    child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 32)
                  ), 
                  const SizedBox(width: 16), 
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Text('Scan Barcode', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), 
                      Text('Auto-fill product details', style: TextStyle(color: Colors.white70, fontSize: 13))
                    ]
                  )
                ]
              )
            ),
          ),
          if (!_isEditing) const SizedBox(height: 16),
          if (!_isEditing) GestureDetector(
            onTap: _scanBill,
            child: Container(
              padding: const EdgeInsets.all(20), 
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.primary, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12), 
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1), 
                      borderRadius: BorderRadius.circular(12)
                    ), 
                    child: Icon(Icons.receipt_long, color: colorScheme.primary, size: 32)
                  ), 
                  const SizedBox(width: 16), 
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        Text(
                          'Scan Bill', 
                          style: TextStyle(
                            color: colorScheme.onSurface, 
                            fontSize: 18, 
                            fontWeight: FontWeight.bold
                          )
                        ), 
                        Text(
                          'Extract multiple items from bill', 
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.6), 
                            fontSize: 13
                          )
                        )
                      ]
                    ),
                  )
                ]
              )
            ),
          ),
          if (!_isEditing) const SizedBox(height: 24),
          if (_showExpiryWarning) Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withValues(alpha: 0.5))),
            child: Row(children: [const Icon(Icons.warning_amber, color: Colors.orange), const SizedBox(width: 12), const Expanded(child: Text('Expiry date estimated. Please verify.', style: TextStyle(color: Colors.orange, fontSize: 13)))]),
          ),
          if (!_isEditing) Row(children: [Expanded(child: Divider(color: colorScheme.onSurface.withValues(alpha: 0.1))), Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('OR ENTER DETAILS', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12, letterSpacing: 1))), Expanded(child: Divider(color: colorScheme.onSurface.withValues(alpha: 0.1)))]),
          if (!_isEditing) const SizedBox(height: 24),
          Text('Product Name', style: TextStyle(color: colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600)), const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1))), 
            child: TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              style: TextStyle(color: colorScheme.onSurface), 
              decoration: InputDecoration(hintText: 'e.g. Greek Yogurt', hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4)), border: InputBorder.none, contentPadding: const EdgeInsets.all(16))
            )
          ),
          const SizedBox(height: 20),
          Text('Category', style: TextStyle(color: colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600)), const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showCategoryPicker(colorScheme), 
            child: Container(
              padding: const EdgeInsets.all(16), 
              decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1))), 
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                children: [
                  Text(_selectedCategory, style: TextStyle(color: _selectedCategory == 'Select category' ? colorScheme.onSurface.withValues(alpha: 0.4) : colorScheme.onSurface)), 
                  Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurface.withValues(alpha: 0.4))
                ]
              )
            )
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Expiry Date', style: TextStyle(color: colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600)), 
              const SizedBox(height: 8), 
              GestureDetector(
                onTap: () => _selectDate(context), 
                child: Container(
                  padding: const EdgeInsets.all(16), 
                  decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1))), 
                  child: Row(
                    children: [
                      Text(_selectedDate == null ? 'mm/dd/yyyy' : '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}', style: TextStyle(color: _selectedDate == null ? colorScheme.onSurface.withValues(alpha: 0.4) : colorScheme.onSurface)), 
                      const Spacer(), 
                      Icon(Icons.calendar_today_outlined, color: colorScheme.onSurface.withValues(alpha: 0.4), size: 20)
                    ]
                  )
                )
              )
            ])),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Qty', style: TextStyle(color: colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600)), 
              const SizedBox(height: 8), 
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), 
                decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1))), 
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: [
                    GestureDetector(onTap: () { if (_quantity > 1) setState(() => _quantity--); }, child: Icon(Icons.remove, color: colorScheme.onSurface, size: 18)), 
                    Text('$_quantity', style: TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600)), 
                    GestureDetector(onTap: () => setState(() => _quantity++), child: Icon(Icons.add, color: colorScheme.onSurface, size: 18))
                  ]
                )
              )
            ])),
          ]),
          if (!_isEditing) ...[
            const SizedBox(height: 24),
            Text('QUICK ADD SUGGESTIONS', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600)), const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: _quickAddItems.map((item) => GestureDetector(
              onTap: () => setState(() => _nameController.text = item), 
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), 
                decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.2))), 
                child: Text(item, style: TextStyle(color: colorScheme.onSurface, fontSize: 14))
              )
            )).toList()),
          ],
          const SizedBox(height: 40),
          GestureDetector(
            onTap: _saveItem, 
            child: Container(
              width: double.infinity, 
              padding: const EdgeInsets.symmetric(vertical: 16), 
              decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(30)), 
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  Text(_isEditing ? 'Update Item' : 'Add to Pantry', style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)), 
                  const SizedBox(width: 8), 
                  const Icon(Icons.check_circle, color: Colors.black, size: 20)
                ]
              )
            )
          ),
        ]),
      ),
    );
  }
}
