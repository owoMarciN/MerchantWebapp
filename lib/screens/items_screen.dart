import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
import 'package:user_app/models/items.dart';
import 'package:user_app/models/menus.dart';
import 'package:user_app/widgets/items_design.dart';
import 'package:user_app/widgets/progress_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
                    .orderBy("publishedDate", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Center(child: Text("Error: ${snapshot.error}")),
                    );
                  }

                  if (!snapshot.hasData) {
                    return SliverToBoxAdapter(child: Center(child: circularProgress()));
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.fastfood_rounded, size: 64, color: brandColors.muted),
                            const SizedBox(height: 16),
                            const Text('No items yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text('Tap + to add your first item', style: TextStyle(fontSize: 14, color: brandColors.muted)),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 100),
                    sliver: SliverMasonryGrid.count(
                      crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var doc = snapshot.data!.docs[index];
                        Items iModel = Items.fromJson(doc.data()! as Map<String, dynamic>);
                        iModel.itemID = doc.id;
                        iModel.menuID = model!.menuID;
                        iModel.restaurantID = model!.restaurantID;
                        return ItemsDesignWidget(model: iModel, context: context);
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
              label: const Text('Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

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
  final TextEditingController _tagController = TextEditingController();

  final List<String> _tags = [];
  Uint8List? _imageBytes;
  String? _imageFileName;
  bool _isLoading = false;

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.first.bytes != null) {
      setState(() {
        _imageBytes = result.files.first.bytes;
        _imageFileName = result.files.first.name;
      });
    }
  }

  Future<String> _fetchRestaurantStatus() async {
    try {
      final String restaurantID = widget.menu.restaurantID!;

      final resDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantID)
          .get();

      if (!resDoc.exists) {
        Fluttertoast.showToast(msg: "Restaurant record not found.");
        return 'Pending';
      }

      return resDoc.data()?['status']?.toString() ?? 'Pending';
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching restaurant status: $e");
      return 'Pending'; 
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBytes == null) {
      _showError('Please select an item image.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String currentRestaurantStatus = await _fetchRestaurantStatus();

      final String restaurantID = widget.menu.restaurantID!;
      final String menuID = widget.menu.menuID!;
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_$_imageFileName';
      

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
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'imageUrl': imageUrl,
        'restaurantID': restaurantID,
        'menuID': menuID,
        'publishedDate': DateTime.now().toString(),
        'status': 'Available',
        'restaurantStatus': currentRestaurantStatus, 
        'discount': 0.0,
        'likes': 0,
        'tags': _tags,
      });

      await docRef.update({'itemID': docRef.id});

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _infoController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _tagController.dispose();
    super.dispose();
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
                  const Text('Add Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: brandColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: brandColors.navy?.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _imageBytes != null ? brandColors.navy! : colorScheme.outline,
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
                            Icon(Icons.add_photo_alternate_outlined, size: 40, color: brandColors.muted),
                            const SizedBox(height: 8),
                            Text('Upload Item Image', style: TextStyle(fontSize: 13, color: brandColors.muted, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text('Click to browse', style: TextStyle(fontSize: 11, color: brandColors.muted)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Item Title',
                  hintText: 'e.g. Pierogi Ruskie',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _infoController,
                decoration: InputDecoration(
                  labelText: 'Short Info',
                  hintText: 'e.g. Crispy and Tasty',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Info is required' : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the item...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Description is required' : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Price (PLN)',
                  hintText: 'e.g. 24.99',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  prefixText: 'PLN ',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Price is required';
                  if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tagController,
                      decoration: InputDecoration(
                        labelText: 'Tags',
                        hintText: 'e.g. Vegan',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onFieldSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 10),
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

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandColors.navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Add Item', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}