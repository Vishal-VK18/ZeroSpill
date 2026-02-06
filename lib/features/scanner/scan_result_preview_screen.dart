import 'package:flutter/material.dart';
import 'dart:io';
import 'bill_ocr_parser.dart';
import '../../shared/models/pantry_item.dart';
import '../../shared/services/pantry_service.dart';

class ScanResultPreviewScreen extends StatefulWidget {
  final List<DetectedProduct> products;
  final String billImagePath;

  const ScanResultPreviewScreen({
    super.key,
    required this.products,
    required this.billImagePath,
  });

  @override
  State<ScanResultPreviewScreen> createState() => _ScanResultPreviewScreenState();
}

class _ScanResultPreviewScreenState extends State<ScanResultPreviewScreen> {
  late List<EditableProduct> _editableProducts;
  final PantryService _pantryService = PantryService();

  @override
  void initState() {
    super.initState();
    _editableProducts = widget.products
        .map((p) => EditableProduct(
              name: p.name,
              category: p.category,
              expiryDate: p.expiryDate,
              isExpiryAutoCalculated: p.isExpiryAutoCalculated,
              quantity: p.quantity,
            ))
        .toList();
  }

  Future<void> _selectDate(BuildContext context, int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _editableProducts[index].expiryDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _editableProducts[index].expiryDate = picked;
        _editableProducts[index].isExpiryAutoCalculated = false;
      });
    }
  }

  void _removeProduct(int index) {
    setState(() {
      _editableProducts.removeAt(index);
    });

    if (_editableProducts.isEmpty) {
      Navigator.pop(context);
    }
  }

  void _saveAllProducts() {
    bool hasErrors = false;

    for (final product in _editableProducts) {
      if (product.name.isEmpty) {
        _showError('All products must have a name');
        hasErrors = true;
        break;
      }
      if (product.expiryDate == null) {
        _showError('All products must have an expiry date');
        hasErrors = true;
        break;
      }
    }

    if (hasErrors) return;

    final items = _editableProducts.map((p) {
      return PantryItem(
        id: _pantryService.generateId(),
        name: p.name,
        category: p.category,
        expiryDate: p.expiryDate!,
        quantity: p.quantity,
        unit: p.quantity == 1 ? 'Unit' : 'Units',
      );
    }).toList();

    _pantryService.addMultipleItems(items);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${items.length} items added to pantry'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Review Items (${_editableProducts.length})',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (File(widget.billImagePath).existsSync())
            Container(
              height: 120,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(widget.billImagePath),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Review and edit detected items before saving',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _editableProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(index, colorScheme);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: _saveAllProducts,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Add All to Pantry',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle, color: Colors.black, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(int index, ColorScheme colorScheme) {
    final product = _editableProducts[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeProduct(index),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.category,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quantity',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.onSurface.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      '${product.quantity}',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Expiry Date',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _selectDate(context, index),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: product.isExpiryAutoCalculated
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      product.expiryDate != null
                          ? '${product.expiryDate!.month}/${product.expiryDate!.day}/${product.expiryDate!.year}'
                          : 'Tap to set',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (product.isExpiryAutoCalculated)
                    Icon(
                      Icons.auto_awesome,
                      color: colorScheme.primary,
                      size: 18,
                    ),
                ],
              ),
            ),
          ),
          if (product.isExpiryAutoCalculated)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Auto-calculated expiry date',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class EditableProduct {
  String name;
  String category;
  DateTime? expiryDate;
  bool isExpiryAutoCalculated;
  int quantity;

  EditableProduct({
    required this.name,
    required this.category,
    this.expiryDate,
    this.isExpiryAutoCalculated = false,
    this.quantity = 1,
  });
}
