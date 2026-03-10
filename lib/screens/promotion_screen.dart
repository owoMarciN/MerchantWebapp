import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
import 'package:user_app/extensions/extensions_import.dart';
import 'package:user_app/global/global.dart';
import 'package:user_app/methods/assistant_methods.dart';
import 'package:user_app/widgets/edit_sheet_components.dart';
import 'package:user_app/widgets/unified_snackbar.dart';

class PromotionsScreen extends StatelessWidget {
  const PromotionsScreen({super.key});

  void _openAddSheet(BuildContext context, String restaurantID) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PromotionSheet(restaurantID: restaurantID),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brandColors = Theme.of(context).extension<BrandColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final String? restaurantID = sharedPreferences?.getString('uid');

    if (restaurantID == null) {
      return Center(child: Text(context.l10n.promo_not_authenticated));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('restaurants')
                .doc(restaurantID)
                .collection('promotions')
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 40, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text(snap.error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13, color: brandColors.muted)),
                      ],
                    ),
                  ),
                );
              }

              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snap.data!.docs.toList()
                ..sort((a, b) {
                  final aRaw = (a.data() as Map)['createdAt'];
                  final bRaw = (b.data() as Map)['createdAt'];
                  DateTime? aDate = aRaw is Timestamp
                      ? aRaw.toDate()
                      : aRaw is DateTime
                          ? aRaw
                          : null;
                  DateTime? bDate = bRaw is Timestamp
                      ? bRaw.toDate()
                      : bRaw is DateTime
                          ? bRaw
                          : null;
                  if (aDate == null && bDate == null) return 0;
                  if (aDate == null) return 1;
                  if (bDate == null) return -1;
                  return bDate.compareTo(aDate);
                });

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.campaign_rounded,
                          size: 64, color: brandColors.muted),
                      const SizedBox(height: 16),
                      Text(context.l10n.promo_empty_title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(context.l10n.promo_empty_subtitle,
                          style: TextStyle(
                              fontSize: 14, color: brandColors.muted)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 100),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return _PromotionCard(
                    promotionID: docs[i].id,
                    data: data,
                    restaurantID: restaurantID,
                    brandColors: brandColors,
                    colorScheme: colorScheme,
                  );
                },
              );
            },
          ),

          // FAB
          Positioned(
            bottom: 28,
            right: 28,
            child: FloatingActionButton.extended(
              onPressed: () => _openAddSheet(context, restaurantID),
              backgroundColor: brandColors.navy,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(context.l10n.promo_fab,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// -- Promotion card -----------------------------------------------------------

class _PromotionCard extends StatelessWidget {
  final String promotionID;
  final Map<String, dynamic> data;
  final String restaurantID;
  final BrandColors brandColors;
  final ColorScheme colorScheme;

  const _PromotionCard({
    required this.promotionID,
    required this.data,
    required this.restaurantID,
    required this.brandColors,
    required this.colorScheme,
  });

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PromotionSheet(
        restaurantID: restaurantID,
        promotionID: promotionID,
        existing: data,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String title = data['title']?.toString() ?? 'Untitled';
    final String description = data['description']?.toString() ?? '';
    final String? bannerUrl = (data['bannerUrl'] as String?)?.isNotEmpty == true
        ? data['bannerUrl'] as String
        : null;
    final bool isActive = data['isActive'] == true;

    final DateTime? startDate = _toDate(data['startDate']);
    final DateTime? endDate = _toDate(data['endDate']);

    final now = DateTime.now();
    final bool dateActive = startDate != null &&
        endDate != null &&
        now.isAfter(startDate) &&
        now.isBefore(endDate);
    final bool effectivelyActive = isActive && dateActive;

    final List<String> linkedItemIDs =
        List<String>.from(data['linkedItemIDs'] ?? []);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: effectivelyActive
              ? brandColors.accentGreen?.withValues(alpha: 0.4) ??
                  colorScheme.outline
              : colorScheme.outline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 180,
                width: double.infinity,
                child: bannerUrl != null
                    ? Image.network(
                        bannerUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: brandColors.navy?.withValues(alpha: 0.05),
                            child: Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                color: brandColors.navy,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) =>
                            _bannerPlaceholder(brandColors),
                      )
                    : _bannerPlaceholder(brandColors),
              ),

              // Active / Inactive badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: effectivelyActive
                        ? brandColors.accentGreen
                        : Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        effectivelyActive
                            ? context.l10n.promo_badge_live
                            : context.l10n.promo_badge_inactive,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              // Linked items count badge
              if (linkedItemIDs.isNotEmpty)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.link_rounded,
                            size: 13, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          linkedItemIDs.length == 1
                              ? context.l10n
                                  .promo_items_linked(linkedItemIDs.length)
                              : context.l10n.promo_items_linked_plural(
                                  linkedItemIDs.length),
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: brandColors.muted,
                                  height: 1.4),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor:
                            brandColors.muted!.withValues(alpha: 0.3),
                      ),
                      onPressed: () => _openEditSheet(context),
                      child: Row(children: [
                        Text(context.l10n.promo_edit_button,
                            style: TextStyle(
                                color: brandColors.accentGreen,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Icon(Icons.edit_rounded,
                            size: 14, color: brandColors.accentGreen),
                      ]),
                    ),
                  ],
                ),
                if (startDate != null && endDate != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.date_range_rounded,
                          size: 14, color: brandColors.muted),
                      const SizedBox(width: 6),
                      Text(
                        '${_fmt(startDate)} → ${_fmt(endDate)}',
                        style:
                            TextStyle(fontSize: 12, color: brandColors.muted),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _toDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  Widget _bannerPlaceholder(BrandColors brand) => Container(
        color: brand.navy?.withValues(alpha: 0.05),
        child: Center(
          child: Icon(Icons.campaign_rounded, size: 48, color: brand.muted),
        ),
      );
}

// -- Promotion sheet (add + edit) ---------------------------------------------

class _PromotionSheet extends StatefulWidget {
  final String restaurantID;
  final String? promotionID;
  final Map<String, dynamic>? existing;

  const _PromotionSheet({
    required this.restaurantID,
    this.promotionID,
    this.existing,
  });

  bool get isEditing => promotionID != null;

  @override
  State<_PromotionSheet> createState() => _PromotionSheetState();
}

class _PromotionSheetState extends State<_PromotionSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  Uint8List? _imageBytes;
  String? _imageFileName;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = true;
  bool _isLoading = false;

  List<String> _linkedItemIDs = [];
  Map<String, String> _allItems = {};
  bool _itemsLoading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController =
        TextEditingController(text: e?['title']?.toString() ?? '');
    _descriptionController =
        TextEditingController(text: e?['description']?.toString() ?? '');
    _isActive = e?['isActive'] ?? true;
    _linkedItemIDs = List<String>.from(e?['linkedItemIDs'] ?? []);

    if (e?['startDate'] != null) {
      _startDate = e!['startDate'] is Timestamp
          ? (e['startDate'] as Timestamp).toDate()
          : e['startDate'] as DateTime?;
    }
    if (e?['endDate'] != null) {
      _endDate = e!['endDate'] is Timestamp
          ? (e['endDate'] as Timestamp).toDate()
          : e['endDate'] as DateTime?;
    }

    _loadAllItems();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAllItems() async {
    setState(() => _itemsLoading = true);
    try {
      final menusSnap = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantID)
          .collection('menus')
          .get();

      final Map<String, String> items = {};
      for (final menuDoc in menusSnap.docs) {
        final itemsSnap = await menuDoc.reference.collection('items').get();
        for (final itemDoc in itemsSnap.docs) {
          final title = (itemDoc.data()['title'] as String?) ?? 'Untitled';
          items[itemDoc.id] = title;
        }
      }

      if (mounted) setState(() => _allItems = items);
    } catch (_) {
      // Non-fatal
    } finally {
      if (mounted) setState(() => _itemsLoading = false);
    }
  }

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

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ??
            (_startDate ?? DateTime.now()).add(const Duration(days: 7)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate!.add(const Duration(days: 1));
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      unifiedSnackBar(context, context.l10n.promo_no_dates, error: true);
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      unifiedSnackBar(context, context.l10n.promo_date_order_error, error: true);
      return;
    }
    if (!widget.isEditing && _imageBytes == null) {
      unifiedSnackBar(context, context.l10n.promo_no_image, error: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String bannerUrl = widget.existing?['bannerUrl']?.toString() ?? '';
      final String? oldUrl = widget.existing?['bannerUrl']?.toString();
      bool bannerChanged = false;

      if (_imageBytes != null) {
        final String fileName =
            '${DateTime.now().millisecondsSinceEpoch}_$_imageFileName';
        final ref = FirebaseStorage.instance
            .ref()
            .child('restaurants')
            .child(widget.restaurantID)
            .child('promotions')
            .child(fileName);

        await ref.putData(_imageBytes!);
        bannerUrl = await ref.getDownloadURL();
        bannerChanged = true;
      }

      final Map<String, dynamic> payload = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'startDate': Timestamp.fromDate(_startDate!),
        'endDate': Timestamp.fromDate(_endDate!),
        'isActive': _isActive,
        'linkedItemIDs': _linkedItemIDs,
        'bannerUrl': bannerUrl,
        'restaurantID': widget.restaurantID,
      };

      final col = FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantID)
          .collection('promotions');

      if (widget.isEditing) {
        await col.doc(widget.promotionID).update(payload);
      } else {
        payload['createdAt'] = Timestamp.now();
        final docRef = await col.add(payload);
        await docRef.update({'promotionID': docRef.id});
      }

      if (bannerChanged && oldUrl != null && oldUrl.isNotEmpty) {
        final String? err = await deleteOldFile(oldUrl);
        if (err != null && mounted) {
          unifiedSnackBar(context, context.l10n.promo_banner_cleanup_error,
              error: true);
        }
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final successMsg = widget.isEditing
          ? context.l10n.promo_updated
          : context.l10n.promo_created;
      Navigator.pop(context);
      messenger
        ..clearSnackBars()
        ..showSnackBar(_successSnack(successMsg));
    } catch (e) {
      if (!mounted) return;
      unifiedSnackBar(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.l10n.promo_delete_title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(context.l10n.promo_delete_body,
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.promo_delete_cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(context.l10n.promo_delete_confirm),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    setState(() => _isLoading = true);

    final messenger = ScaffoldMessenger.of(context);

    try {
      final String? bannerUrl = widget.existing?['bannerUrl']?.toString();
      if (bannerUrl != null && bannerUrl.isNotEmpty) {
        await deleteOldFile(bannerUrl);
      }

      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantID)
          .collection('promotions')
          .doc(widget.promotionID)
          .delete();

      if (!mounted) return;
      final deletedMsg = context.l10n.promo_deleted;
      Navigator.pop(context);
      messenger
        ..clearSnackBars()
        ..showSnackBar(_successSnack(deletedMsg));
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
    final double kb = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(28, 24, 28, 28 + kb),
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
                  Text(
                    widget.isEditing
                        ? context.l10n.promo_sheet_edit_title
                        : context.l10n.promo_sheet_add_title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  Row(
                    children: [
                      if (widget.isEditing)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.pink.withValues(alpha: 0.3)),
                          onPressed: _isLoading ? null : _delete,
                          child: Row(children: [
                            Text(context.l10n.promo_sheet_delete_button,
                                style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            const Icon(Icons.delete_rounded,
                                color: Colors.redAccent, size: 16),
                          ]),
                        ),
                      if (widget.isEditing) const SizedBox(width: 10),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: brandColors.muted),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Banner image picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
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
                  clipBehavior: Clip.antiAlias,
                  child: _imageBytes != null
                      ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                      : (widget.existing?['bannerUrl'] as String?)
                                  ?.isNotEmpty ==
                              true
                          ? Image.network(
                              widget.existing!['bannerUrl'] as String,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _placeholder(brandColors))
                          : _placeholder(brandColors),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  widget.isEditing
                      ? context.l10n.promo_image_change_hint
                      : context.l10n.promo_image_upload_hint,
                  style: TextStyle(fontSize: 11, color: brandColors.muted),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: customInputDecoration(
                    label: context.l10n.promo_field_title_label,
                    hint: context.l10n.promo_field_title_hint,
                    colorScheme: colorScheme,
                    brandColors: brandColors),
                validator: (v) => v == null || v.trim().isEmpty
                    ? context.l10n.promo_field_title_required
                    : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: customInputDecoration(
                    label: context.l10n.promo_field_desc_label,
                    hint: context.l10n.promo_field_desc_hint,
                    colorScheme: colorScheme,
                    brandColors: brandColors),
                validator: (v) => v == null || v.trim().isEmpty
                    ? context.l10n.promo_field_desc_required
                    : null,
              ),
              const SizedBox(height: 16),

              // Date range
              Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: context.l10n.promo_date_start,
                      date: _startDate,
                      pickLabel: context.l10n.promo_date_pick,
                      onTap: () => _pickDate(isStart: true),
                      brandColors: brandColors,
                      colorScheme: colorScheme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateButton(
                      label: context.l10n.promo_date_end,
                      date: _endDate,
                      pickLabel: context.l10n.promo_date_pick,
                      onTap: () => _pickDate(isStart: false),
                      brandColors: brandColors,
                      colorScheme: colorScheme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Active toggle
              Container(
                decoration: BoxDecoration(
                  color: _isActive
                      ? brandColors.accentGreen?.withValues(alpha: 0.08)
                      : colorScheme.surfaceBright,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isActive
                        ? brandColors.accentGreen?.withValues(alpha: 0.4) ??
                            colorScheme.outline
                        : colorScheme.outline,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _isActive = !_isActive),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.toggle_on_rounded,
                          size: 20,
                          color: _isActive
                              ? brandColors.accentGreen
                              : brandColors.muted,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          context.l10n.promo_active_toggle,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _isActive
                                ? brandColors.accentGreen
                                : brandColors.muted,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: _isActive,
                          onChanged: (v) => setState(() => _isActive = v),
                          activeThumbColor: brandColors.accentGreen,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Link items section
              _SectionLabel(
                  label: context.l10n.promo_link_section_label,
                  hint: context.l10n.promo_link_section_hint,
                  brandColors: brandColors),
              const SizedBox(height: 10),

              if (_itemsLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: brandColors.navy),
                  ),
                )
              else if (_allItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    context.l10n.promo_link_no_items,
                    style: TextStyle(fontSize: 12, color: brandColors.muted),
                  ),
                )
              else
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: _allItems.entries.map((entry) {
                        final bool selected =
                            _linkedItemIDs.contains(entry.key);
                        return CheckboxListTile(
                          dense: true,
                          title: Text(entry.value,
                              style: const TextStyle(fontSize: 13)),
                          value: selected,
                          activeColor: brandColors.navy,
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _linkedItemIDs.add(entry.key);
                              } else {
                                _linkedItemIDs.remove(entry.key);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
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
                      : Text(
                          widget.isEditing
                              ? context.l10n.promo_save_changes
                              : context.l10n.promo_create,
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

  Widget _placeholder(BrandColors brand) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 40, color: brand.muted),
          const SizedBox(height: 8),
          Text(context.l10n.promo_image_upload_label,
              style: TextStyle(
                  fontSize: 13,
                  color: brand.muted,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(context.l10n.promo_image_recommended,
              style: TextStyle(fontSize: 11, color: brand.muted)),
        ],
      );

  SnackBar _successSnack(String msg) => SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(msg,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ]),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        dismissDirection: DismissDirection.horizontal,
      );
}

// -- Date picker button -------------------------------------------------------

class _DateButton extends StatelessWidget {
  final String label;
  final String pickLabel;
  final DateTime? date;
  final VoidCallback onTap;
  final BrandColors brandColors;
  final ColorScheme colorScheme;

  const _DateButton({
    required this.label,
    required this.pickLabel,
    required this.date,
    required this.onTap,
    required this.brandColors,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasDate = date != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: hasDate
              ? brandColors.navy?.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasDate
                ? brandColors.navy?.withValues(alpha: 0.4) ??
                    colorScheme.outline
                : colorScheme.outline,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 16,
                color: hasDate ? brandColors.navy : brandColors.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          TextStyle(fontSize: 10, color: brandColors.muted)),
                  const SizedBox(height: 2),
                  Text(
                    hasDate
                        ? '${date!.day.toString().padLeft(2, '0')}.${date!.month.toString().padLeft(2, '0')}.${date!.year}'
                        : pickLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: hasDate ? brandColors.navy : brandColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- Section label ------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String label;
  final String? hint;
  final BrandColors brandColors;

  const _SectionLabel({
    required this.label,
    required this.brandColors,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        if (hint != null)
          Text(hint!, style: TextStyle(fontSize: 11, color: brandColors.muted)),
      ],
    );
  }
}