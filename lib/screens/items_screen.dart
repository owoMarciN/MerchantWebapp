import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
import 'package:user_app/extensions/extensions_import.dart';
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
          model?.title ?? context.l10n.items_app_bar_fallback,
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
                          context.l10n.items_error(snapshot.error.toString()),
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
                            Text(context.l10n.items_empty_title,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text(context.l10n.items_empty_subtitle,
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
              label: Text(context.l10n.items_fab,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// -- Add item sheet -----------------------------------------------------------

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
      validationResult = context.l10n.items_tag_error_empty;
    } else if (!RegExp(r'^[A-Z]').hasMatch(tag)) {
      validationResult = context.l10n.items_tag_error_capitalize;
    } else if (!RegExp(r'^[a-zA-Z]+$').hasMatch(tag)) {
      validationResult = context.l10n.items_tag_error_letters;
    } else if (_tags.contains(tag)) {
      validationResult = context.l10n.items_tag_error_duplicate;
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
      unifiedSnackBar(context, context.l10n.items_no_image, error: true);
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
      final addedMsg = context.l10n.items_added;
      Navigator.pop(context);
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(addedMsg,
                  style: const TextStyle(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.l10n.items_sheet_title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
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
                            Text(context.l10n.items_image_upload_label,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: brandColors.muted,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text(context.l10n.items_image_browse,
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
                  labelText: context.l10n.items_field_title_label,
                  hintText: context.l10n.items_field_title_hint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? context.l10n.items_field_title_required
                    : null,
              ),
              const SizedBox(height: 16),

              // Short info
              TextFormField(
                controller: _infoController,
                decoration: InputDecoration(
                  labelText: context.l10n.items_field_info_label,
                  hintText: context.l10n.items_field_info_hint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? context.l10n.items_field_info_required
                    : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: context.l10n.items_field_desc_label,
                  hintText: context.l10n.items_field_desc_hint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? context.l10n.items_field_desc_required
                    : null,
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: context.l10n.items_field_price_label,
                  hintText: context.l10n.items_field_price_hint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  prefixText: 'PLN ',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return context.l10n.items_field_price_required;
                  }
                  if (double.tryParse(v.trim()) == null) {
                    return context.l10n.items_field_price_invalid;
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
                        labelText: context.l10n.items_field_tags_label,
                        hintText: context.l10n.items_field_tags_hint,
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

              // Discount toggle
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
                              context.l10n.items_discount_toggle,
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
                            labelText: context.l10n.items_discount_label,
                            suffixText: '%',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          validator: (v) {
                            if (!_hasDiscount) return null;
                            if (v == null || v.trim().isEmpty) {
                              return context.l10n.items_discount_required;
                            }
                            final val = double.tryParse(v.trim());
                            if (val == null || val <= 0 || val > 100) {
                              return context.l10n.items_discount_invalid;
                            }
                            return null;
                          },
                        ),
                      ),
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
                      : Text(context.l10n.items_submit,
                          style: const TextStyle(
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