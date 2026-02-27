import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
import 'package:user_app/models/items.dart';
import 'package:user_app/widgets/edit_sheet_components.dart'; 

class ItemsDesignWidget extends StatelessWidget {
  final Items? model;
  const ItemsDesignWidget({super.key, this.model});

  void _openEditSheet(BuildContext context) {
    if (model == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditItemSheet(item: model!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brandColors = Theme.of(context).extension<BrandColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final bool hasImage = model?.imageUrl != null && model!.imageUrl!.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openEditSheet(context),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: hasImage
                      ? Image.network(
                          model!.imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: brandColors.navy?.withValues(alpha: 0.05),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  color: brandColors.navy,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => customImagePlaceholder(brandColors), 
                        )
                      : customImagePlaceholder(brandColors),
                ),
                // Discount Badge
                if (model?.hasDiscount == true)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: brandColors.accentGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-${model!.discount!.toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                // Likes Badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite_rounded, size: 18, color: Colors.redAccent),
                        const SizedBox(width: 4),
                        Text(
                          '${model?.likes ?? 0}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model?.title ?? 'Untitled Item',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          model?.shortInfo ?? '',
                          style: TextStyle(fontSize: 12, color: brandColors.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              'PLN ${model?.discountedPrice.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            if (model?.hasDiscount == true) ...[
                              const SizedBox(width: 8),
                              Text(
                                'PLN ${model!.price!.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: brandColors.muted,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style:  ElevatedButton.styleFrom(
                      backgroundColor: brandColors.muted!.withValues(alpha: 0.3)
                    ),
                    onPressed: () => _openEditSheet(context),
                    child: Row(
                      children: [
                        Text(
                          "Edit Item", 
                          style: TextStyle(
                            color: brandColors.accentGreen,
                            fontWeight: FontWeight.bold
                          )
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.change_circle, color: brandColors.accentGreen),
                      ]
                    )
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditItemSheet extends StatefulWidget {
  final Items item;
  const _EditItemSheet({required this.item});

  @override
  State<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends State<_EditItemSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _shortInfoController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _discountController;
  late final TextEditingController _tagController;

  late List<String> _tags;
  late bool _hasDiscount;
  Uint8List? _imageBytes;
  String? _imageFileName;
  bool _isLoading = false;

  String? _tagError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title ?? '');
    _shortInfoController = TextEditingController(text: widget.item.shortInfo ?? '');
    _descriptionController = TextEditingController(text: widget.item.description ?? '');
    _priceController = TextEditingController(text: widget.item.price?.toString() ?? '');
    _discountController = TextEditingController(text: widget.item.discount?.toString() ?? '');
    _tagController = TextEditingController();
    _tags = List<String>.from(widget.item.tags ?? []);
    _hasDiscount = widget.item.hasDiscount;
    _priceController.addListener(() => setState(() {}));
    _discountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shortInfoController.dispose();
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
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.first.bytes != null) {
      setState(() {
        _imageBytes = result.files.first.bytes;
        _imageFileName = result.files.first.name;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String imageUrl = widget.item.imageUrl ?? '';
      String? oldUrl = widget.item.imageUrl;

      if (_imageBytes != null) {
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_$_imageFileName';
        final ref = FirebaseStorage.instance
            .ref()
            .child('restaurants')
            .child(widget.item.restaurantID!)
            .child('menus')
            .child(widget.item.menuID!)
            .child('items')
            .child(fileName);
            
        await ref.putData(_imageBytes!);
        imageUrl = await ref.getDownloadURL();

        if (oldUrl != null && oldUrl.isNotEmpty) {
          try {
            await FirebaseStorage.instance.refFromURL(oldUrl).delete();
          } catch (e) {
            String message = "Update failed";
            if (e is FirebaseException) {
              if (e.code == 'permission-denied') message = "You don't have permission to edit this.";
              if (e.code == 'network-request-failed') message = "Check your internet connection.";
            }

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }

      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.item.restaurantID)
          .collection('menus')
          .doc(widget.item.menuID)
          .collection('items')
          .doc(widget.item.itemID)
          .update({
        'title': _titleController.text.trim(),
        'shortInfo': _shortInfoController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'discount': _hasDiscount ? (double.tryParse(_discountController.text.trim()) ?? 0.0) : 0.0,
        'tags': _tags,
        'imageUrl': imageUrl,
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _isLoading = true);

    try {
      if (widget.item.imageUrl != null && widget.item.imageUrl!.isNotEmpty) {
        final storageRef = FirebaseStorage.instance.refFromURL(widget.item.imageUrl!);
        await storageRef.delete();
      }
      
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.item.restaurantID)
          .collection('menus')
          .doc(widget.item.menuID)
          .collection('items')
          .doc(widget.item.itemID)
          .delete();

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
      );
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
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(28, 24, 28, 28 + keyboardHeight),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                
                  Row(
                    children: [
                      ElevatedButton(
                        style:  ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink.withValues(alpha: 0.3)
                        ),
                        onPressed: _delete,
                        child: Row(
                          children: [
                            Text(
                              "Delete Item", 
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold
                              )
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.delete_rounded, color: Colors.redAccent),
                          ]
                        )
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: brandColors.muted),
                      ),
                    ],
                  )
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
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _imageBytes != null ? brandColors.navy! : colorScheme.outline,
                      width: _imageBytes != null ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imageBytes != null
                      ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                      : widget.item.imageUrl != null
                          ? Image.network(widget.item.imageUrl!, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => customImagePlaceholder(brandColors))
                          : customImagePlaceholder(brandColors),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('Tap to change image', style: TextStyle(fontSize: 11, color: brandColors.muted)),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _titleController, 
                decoration: customInputDecoration(
                  label: 'Item Title', 
                  colorScheme: colorScheme, 
                  brandColors: brandColors
                ),
                
                validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _shortInfoController,
                decoration: customInputDecoration(
                  label: 'Short Info',
                  hint: 'e.g. Crispy and Tasty',
                  colorScheme: colorScheme, 
                  brandColors: brandColors
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'shortInfo is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: customInputDecoration(
                  label: 'Description',
                  colorScheme: colorScheme, 
                  brandColors: brandColors
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: customInputDecoration(
                  label: 'Price (PLN)',
                  prefixText: 'PLN ',
                  colorScheme: colorScheme, 
                  brandColors: brandColors
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Price is required';
                  if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
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
                      decoration: customInputDecoration(
                        label: 'Tags',
                        hint: 'e.g. Vegan',
                        colorScheme: colorScheme,
                        brandColors: brandColors,
                        errorText: _tagError,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                      ],
                      onChanged: (value) {
                        if (_tagError != null) { setState(() => _tagError = null); }
                      },
                      onFieldSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: _addTag,
                    style: IconButton.styleFrom(
                      backgroundColor: brandColors.navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  children: _tags.map((tag) => Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close_rounded, size: 14),
                    onDeleted: () => _removeTag(tag),
                    backgroundColor: brandColors.navy?.withValues(alpha: 0.1),
                    side: BorderSide(color: brandColors.navy?.withValues(alpha: 0.3) ?? Colors.transparent),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  )).toList(),
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
                        ? brandColors.accentGreen?.withValues(alpha: 0.4) ?? colorScheme.outline
                        : colorScheme.outline,
                  ),
                ),
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _hasDiscount = !_hasDiscount),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.local_offer_rounded, size: 18,
                                color: _hasDiscount ? brandColors.accentGreen : brandColors.muted),
                            const SizedBox(width: 10),
                            Text('Apply Discount',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _hasDiscount ? brandColors.accentGreen : brandColors.muted,
                                )),
                            const Spacer(),
                            Checkbox(
                              value: _hasDiscount,
                              onChanged: (v) => setState(() => _hasDiscount = v ?? false),
                              activeColor: brandColors.accentGreen,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_hasDiscount) ...[
                      Divider(height: 1, color: brandColors.accentGreen?.withValues(alpha: 0.2)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: TextFormField(
                          controller: _discountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Discount %',
                            suffixText: '%',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          validator: (v) {
                            if (!_hasDiscount) return null;
                            if (v == null || v.trim().isEmpty) return 'Enter a discount percentage';
                            final val = double.tryParse(v.trim());
                            if (val == null || val <= 0 || val > 100) return 'Enter a value between 1 and 100';
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
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: brandColors.accentGreen),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'PLN ${double.parse(_priceController.text).toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 12, color: brandColors.muted, decoration: TextDecoration.lineThrough),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandColors.navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}