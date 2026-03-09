import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
import 'package:user_app/extensions/responsive_ext.dart';
import 'package:user_app/models/items.dart';
import 'package:user_app/models/menus.dart';
import 'package:user_app/widgets/items_design.dart';
import 'package:user_app/widgets/progress_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:user_app/widgets/unified_snackbar.dart';

class ItemsScreen extends StatelessWidget {
  final Menus? model;
  const ItemsScreen({super.key, this.model});

  void _openAddItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddItemSheet(menu: model!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brandColors = Theme.of(context).extension<BrandColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: brandColors.navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          model?.title ?? 'Items',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: colorScheme.outline),
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("restaurants")
                    .doc(model!.restaurantID)
                    .collection("menus")
                    .doc(model!.menuID)
                    .collection("items")
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverToBoxAdapter(
                      child: Center(child: circularProgress()),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Text(
                          "Error: ${snapshot.error}",
                          style: TextStyle(color: brandColors.muted),
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.fastfood_rounded,
                                size: 64, color: brandColors.muted),
                            const SizedBox(height: 16),
                            const Text('No items yet',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text('Tap + to add your first item',
                                style: TextStyle(
                                    fontSize: 14, color: brandColors.muted)),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 100),
                    sliver: SliverMasonryGrid.count(
                      crossAxisCount: context.gridCols4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var doc = snapshot.data!.docs[index];
                        Items iModel =
                            Items.fromJson(doc.data()! as Map<String, dynamic>);
                        iModel.itemID = doc.id;
                        iModel.menuID = model!.menuID;
                        iModel.restaurantID = model!.restaurantID;
                        return ItemsDesignWidget(model: iModel);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          Positioned(
            bottom: 28,
            right: 28,
            child: FloatingActionButton.extended(
              onPressed: () => _openAddItemSheet(context),
              backgroundColor: brandColors.navy,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Add Item',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// -- Add item sheet ------------------------------------------------------------

class _AddItemSheet extends StatefulWidget {
  final Menus menu;
  const _AddItemSheet({required this.menu});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _infoController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  final List<String> _tags = [];
  bool _hasDiscount = false;
  String? _tagError;
  Uint8List? _imageBytes;
  String? _imageFileName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Rebuild when price/discount change so the live preview updates
    _priceController.addListener(() => setState(() {}));
    _discountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _infoController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    String? validationResult;

    if (tag.isEmpty) {
      validationResult = 'Please enter a tag';
    } else if (!RegExp(r'^[A-Z]').hasMatch(tag)) {
      validationResult = 'First letter must be capitalized';
    } else if (!RegExp(r'^[a-zA-Z]+$').hasMatch(tag)) {
      validationResult = 'Only letters are allowed';
    } else if (_tags.contains(tag)) {
      validationResult = 'Tag already exists';
    }

    setState(() {
      _tagError = validationResult;
      if (validationResult == null) {
        _tags.add(tag);
        _tagController.clear();
      }
    });
  }

  void _removeTag(String tag) => setState(() => _tags.remove(tag));

  Future<void> _pickImage() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.first.bytes != null) {
      setState(() {
        _imageBytes = result.files.first.bytes;
        _imageFileName = result.files.first.name;
      });
    }
  }

  Future<String> _fetchRestaurantStatus() async {
    try {
      final resDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.menu.restaurantID!)
          .get();

      if (!resDoc.exists) {
        Fluttertoast.showToast(msg: 'Restaurant record not found.');
        return 'Pending';
      }

      return resDoc.data()?['status']?.toString() ?? 'Pending';
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error fetching restaurant status: $e');
      return 'Pending';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBytes == null) {
      unifiedSnackBar(context, 'Please select an item image.', error: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String currentRestaurantStatus = await _fetchRestaurantStatus();
      final String restaurantID = widget.menu.restaurantID!;
      final String menuID = widget.menu.menuID!;
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$_imageFileName';

      final ref = FirebaseStorage.instance
          .ref()
          .child('restaurants')
          .child(restaurantID)
          .child('menus')
          .child(menuID)
          .child('items')
          .child(fileName);

      await ref.putData(_imageBytes!);
      final String imageUrl = await ref.getDownloadURL();

      final double price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final double discount = _hasDiscount
          ? (double.tryParse(_discountController.text.trim()) ?? 0.0)
          : 0.0;

      final docRef = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantID)
          .collection('menus')
          .doc(menuID)
          .collection('items')
          .add({
        'title': _titleController.text.trim(),
        'shortInfo': _infoController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': price,
        'discount': discount,
        'imageUrl': imageUrl,
        'restaurantID': restaurantID,
        'menuID': menuID,
        'createdAt': Timestamp.now(),
        'status': 'Available',
        'restaurantStatus': currentRestaurantStatus,
        'likes': 0,
        'tags': _tags,
      });

      await docRef.update({'itemID': docRef.id});

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Item added successfully',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ]),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            elevation: 6,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
            dismissDirection: DismissDirection.horizontal,
          ),
        );
    } catch (e) {
      if (!mounted) return;
      unifiedSnackBar(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandColors = Theme.of(context).extension<BrandColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(28, 24, 28, 28 + keyboardHeight),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add Item',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: brandColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Image picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: brandColors.navy?.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _imageBytes != null
                          ? brandColors.navy!
                          : colorScheme.outline,
                      width: _imageBytes != null ? 2 : 1,
                    ),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 40, color: brandColors.muted),
                            const SizedBox(height: 8),
                            Text('Upload Item Image',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: brandColors.muted,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text('Click to browse',
                                style: TextStyle(
                                    fontSize: 11, color: brandColors.muted)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Item Title',
                  hintText: 'e.g. Pierogi Ruskie',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // Short info
              TextFormField(
                controller: _infoController,
                decoration: InputDecoration(
                  labelText: 'Short Info',
                  hintText: 'e.g. Crispy and Tasty',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Info is required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the item...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Price (PLN)',
                  hintText: 'e.g. 24.99',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  prefixText: 'PLN ',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Price is required';
                  if (double.tryParse(v.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tags
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tagController,
                      decoration: InputDecoration(
                        labelText: 'Tags',
                        hintText: 'e.g. Vegan',
                        errorText: _tagError,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                      ],
                      onChanged: (_) {
                        if (_tagError != null) {
                          setState(() => _tagError = null);
                        }
                      },
                      onFieldSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: _addTag,
                    style: IconButton.styleFrom(
                      backgroundColor: brandColors.navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags
                      .map((tag) => Chip(
                            label:
                                Text(tag, style: const TextStyle(fontSize: 12)),
                            deleteIcon:
                                const Icon(Icons.close_rounded, size: 14),
                            onDeleted: () => _removeTag(tag),
                            backgroundColor:
                                brandColors.navy?.withValues(alpha: 0.1),
                            side: BorderSide(
                                color:
                                    brandColors.navy?.withValues(alpha: 0.3) ??
                                        Colors.transparent),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),

              // -- Discount toggle ------------------------------------------
              Container(
                decoration: BoxDecoration(
                  color: _hasDiscount
                      ? brandColors.accentGreen?.withValues(alpha: 0.08)
                      : colorScheme.surfaceBright,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _hasDiscount
                        ? brandColors.accentGreen?.withValues(alpha: 0.4) ??
                            colorScheme.outline
                        : colorScheme.outline,
                  ),
                ),
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _hasDiscount = !_hasDiscount),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.local_offer_rounded,
                                size: 18,
                                color: _hasDiscount
                                    ? brandColors.accentGreen
                                    : brandColors.muted),
                            const SizedBox(width: 10),
                            Text(
                              'Apply Discount',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _hasDiscount
                                    ? brandColors.accentGreen
                                    : brandColors.muted,
                              ),
                            ),
                            const Spacer(),
                            Checkbox(
                              value: _hasDiscount,
                              onChanged: (v) =>
                                  setState(() => _hasDiscount = v ?? false),
                              activeColor: brandColors.accentGreen,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_hasDiscount) ...[
                      Divider(
                          height: 1,
                          color:
                              brandColors.accentGreen?.withValues(alpha: 0.2)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: TextFormField(
                          controller: _discountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Discount %',
                            suffixText: '%',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          validator: (v) {
                            if (!_hasDiscount) return null;
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter a discount percentage';
                            }
                            final val = double.tryParse(v.trim());
                            if (val == null || val <= 0 || val > 100) {
                              return 'Enter a value between 1 and 100';
                            }
                            return null;
                          },
                        ),
                      ),
                      // Live discounted price preview
                      if (_priceController.text.isNotEmpty &&
                          _discountController.text.isNotEmpty &&
                          double.tryParse(_priceController.text) != null &&
                          double.tryParse(_discountController.text) != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Row(
                            children: [
                              Text(
                                'PLN ${(double.parse(_priceController.text) * (1 - double.parse(_discountController.text) / 100)).toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: brandColors.accentGreen),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'PLN ${double.parse(_priceController.text).toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: brandColors.muted,
                                    decoration: TextDecoration.lineThrough),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandColors.navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Add Item',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
