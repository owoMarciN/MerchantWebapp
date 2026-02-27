import 'package:flutter/material.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
import 'package:user_app/models/menus.dart';
import 'package:user_app/screens/items_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:user_app/widgets/edit_sheet_components.dart';

class MenusDesignWidget extends StatelessWidget {
  final Menus? model;
  const MenusDesignWidget({super.key, this.model});

  void _openEditSheet(BuildContext context) {
    if (model == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditMenuSheet(menu: model!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brandColors = Theme.of(context).extension<BrandColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final bool hasImage = model?.bannerUrl != null && model!.bannerUrl!.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemsScreen(model: model))),
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
            // Banner image
            SizedBox(
              height: 160,
              width: double.infinity,
              child: hasImage
                  ? Image.network(
                      model!.bannerUrl!,
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

            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model?.title ?? 'Untitled Menu',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        model?.description ?? '',
                        style: TextStyle(fontSize: 12, color: brandColors.muted, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.lightBlueAccent),
                          const SizedBox(width: 4),
                          Text(
                            'View Items',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.lightBlueAccent),
                          ),
                        ],
                      ),
                    ],
                  ),
                
                  ElevatedButton(
                    style:  ElevatedButton.styleFrom(
                      backgroundColor: brandColors.muted!.withValues(alpha: 0.3)
                    ),
                    onPressed: () => _openEditSheet(context),
                    child: Row(
                      children: [
                        Text(
                          "Edit Menu", 
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

class _EditMenuSheet extends StatefulWidget {
  final Menus menu;
  const _EditMenuSheet({required this.menu});

  @override
  State<_EditMenuSheet> createState() => _EditMenuSheetState();
}

class _EditMenuSheetState extends State<_EditMenuSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController = TextEditingController();
  late TextEditingController _descriptionController = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageFileName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.menu.title ?? '');
    _descriptionController = TextEditingController(text: widget.menu.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

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
      String bannerUrl = widget.menu.bannerUrl ?? '';
      String? oldUrl = widget.menu.bannerUrl;

      if (_imageBytes != null) {
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_$_imageFileName';
        final ref = FirebaseStorage.instance
            .ref()
            .child('restaurants')
            .child(widget.menu.restaurantID!)
            .child('menus')
            .child(fileName);
            
        await ref.putData(_imageBytes!);
        bannerUrl = await ref.getDownloadURL();

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
          .doc(widget.menu.restaurantID)
          .collection('menus')
          .doc(widget.menu.menuID)
          .update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'bannerUrl': bannerUrl,
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
      if (widget.menu.bannerUrl != null && widget.menu.bannerUrl!.isNotEmpty) {
        final storageRef = FirebaseStorage.instance.refFromURL(widget.menu.bannerUrl!);
        await storageRef.delete();
      }

      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.menu.restaurantID)
          .collection('menus')
          .doc(widget.menu.menuID)
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
                  const Text('Edit Menu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                
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
                              "Delete Menu", 
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold
                              )
                            ),
                            const SizedBox(width: 10),
                            Icon(Icons.delete_rounded, color: Colors.redAccent),
                          ]
                        )
                      ),
                      const SizedBox(width: 16),
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
                      : widget.menu.bannerUrl != null
                          ? Image.network(widget.menu.bannerUrl!, fit: BoxFit.cover,
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
                controller: _descriptionController,
                maxLines: 3,
                decoration: customInputDecoration(
                  label: 'Description',
                  colorScheme: colorScheme, 
                  brandColors: brandColors
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Description is required' : null,
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