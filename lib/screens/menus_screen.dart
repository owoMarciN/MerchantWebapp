import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
import 'package:user_app/global/global.dart';
import 'package:user_app/models/menus.dart';
import 'package:user_app/widgets/menus_design.dart';
import 'package:user_app/widgets/progress_bar.dart';

class MenusScreen extends StatefulWidget {
  const MenusScreen({super.key});

  @override
  State<MenusScreen> createState() => _MenusScreenState();
}

class _MenusScreenState extends State<MenusScreen> {
  void _openAddMenuSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddMenuSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? restaurantID = sharedPreferences!.getString("uid");
    final brandColors = Theme.of(context).extension<BrandColors>()!;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("restaurants")
                  .doc(restaurantID)
                  .collection("menus")
                  .orderBy("publishedDate", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return SliverToBoxAdapter(
                    child: Center(child: circularProgress()),
                  );
                }

                if (snapshot.data!.docs.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_menu_rounded, size: 64, color: brandColors.muted),
                          const SizedBox(height: 16),
                          const Text('No menus yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text('Tap + to add your first menu', style: TextStyle(fontSize: 14, color: brandColors.muted)),
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
                      Menus mModel = Menus.fromJson(doc.data()! as Map<String, dynamic>);
                      mModel.menuID = doc.id;
                      mModel.restaurantID = restaurantID;
                      return MenusDesignWidget(model: mModel, context: context);
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
            onPressed: _openAddMenuSheet,
            backgroundColor: brandColors.navy,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('Add Menu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _AddMenuSheet extends StatefulWidget {
  const _AddMenuSheet();

  @override
  State<_AddMenuSheet> createState() => _AddMenuSheetState();
}

class _AddMenuSheetState extends State<_AddMenuSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageFileName;
  bool _isLoading = false;

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBytes == null) {
      _showError('Please select a banner image.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String restaurantID = currentUid!;
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_$_imageFileName';

      final ref = FirebaseStorage.instance
          .ref()
          .child('restaurants')
          .child(restaurantID)
          .child('menus')
          .child(fileName);

      await ref.putData(_imageBytes!);
      final String imageUrl = await ref.getDownloadURL();

      final docRef = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantID)
          .collection('menus')
          .add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'bannerUrl': imageUrl,
        'restaurantID': restaurantID,
        'publishedDate': DateTime.now(),
      });

      await docRef.update({'menuID': docRef.id});

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
      SnackBar(content: Text("There was and error: $message")),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Add Menu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: brandColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Banner image picker
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
                          Text('Upload Banner Image', style: TextStyle(fontSize: 13, color: brandColors.muted, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('Click to browse', style: TextStyle(fontSize: 11, color: brandColors.muted)),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Menu Title',
                hintText: 'e.g. Lunch Specials',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Briefly describe this menu...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Description is required' : null,
            ),

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
                    : const Text('Create Menu', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}