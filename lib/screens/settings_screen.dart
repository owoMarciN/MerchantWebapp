import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
import 'package:user_app/global/global.dart';
import 'package:user_app/widgets/map_dialog.dart';
import 'package:user_app/widgets/custom_text_field.dart';
import 'package:user_app/widgets/custom_phone_field.dart';
import 'package:user_app/widgets/progress_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final String? _restaurantID = currentUid;

  @override
  Widget build(BuildContext context) {
    final brandColors = Theme.of(context).extension<BrandColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("restaurants")
          .doc(_restaurantID)
          .snapshots(),
      builder: (context, restaurantSnap) {
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .doc(_restaurantID)
              .snapshots(),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting ||
                restaurantSnap.connectionState == ConnectionState.waiting) {
              return Center(child: circularProgress());
            }

            if (restaurantSnap.hasError || userSnap.hasError) {
              return Center(
                child: Text('Something went wrong',
                    style: TextStyle(color: brandColors.muted)),
              );
            }

            final restaurantData =
                restaurantSnap.data?.data() as Map<String, dynamic>? ?? {};
            final userData =
                userSnap.data?.data() as Map<String, dynamic>? ?? {};

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 48),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isWide = constraints.maxWidth > 700;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            icon: Icons.storefront_rounded,
                            title: 'Business',
                            subtitle: 'Manage your restaurant profile and media',
                            brandColors: brandColors,
                          ),
                          const SizedBox(height: 16),
                          isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _LogoCard(
                                        restaurantID: _restaurantID,
                                        currentUrl: restaurantData["logoUrl"] ?? "",
                                        brandColors: brandColors,
                                        colorScheme: colorScheme,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _BannerCard(
                                        restaurantID: _restaurantID,
                                        currentUrl: restaurantData["bannerUrl"] ?? "",
                                        brandColors: brandColors,
                                        colorScheme: colorScheme,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _LogoCard(
                                      restaurantID: _restaurantID,
                                      currentUrl: restaurantData["logoUrl"] ?? "",
                                      brandColors: brandColors,
                                      colorScheme: colorScheme,
                                    ),
                                    const SizedBox(height: 16),
                                    _BannerCard(
                                      restaurantID: _restaurantID,
                                      currentUrl: restaurantData["bannerUrl"] ?? "",
                                      brandColors: brandColors,
                                      colorScheme: colorScheme,
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 16),
                          _BusinessInfoCard(
                            restaurantID: _restaurantID,
                            data: restaurantData,
                            brandColors: brandColors,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 36),
                          _SectionHeader(
                            icon: Icons.person_rounded,
                            title: 'User Profile',
                            subtitle: 'Update your personal account details',
                            brandColors: brandColors,
                          ),
                          const SizedBox(height: 16),
                          _UserProfileCard(
                            restaurantID: _restaurantID,
                            data: userData,
                            brandColors: brandColors,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 36),
                          _SectionHeader(
                            icon: Icons.warning_amber_rounded,
                            title: 'Danger Zone',
                            subtitle: 'Irreversible actions for your account',
                            brandColors: brandColors,
                            danger: true,
                          ),
                          const SizedBox(height: 16),
                          _DangerCard(
                              brandColors: brandColors,
                              colorScheme: colorScheme),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

/// Deletes a Firebase Storage file by download URL.
/// Silently ignores object-not-found so it is safe to call on empty or
/// already-deleted URLs.
Future<void> _deleteOldFile(String url) async {
  if (url.isEmpty || !url.contains('firebasestorage')) return;
  try {
    await FirebaseStorage.instance.refFromURL(url).delete();
  } on FirebaseException catch (e) {
    if (e.code != 'object-not-found') rethrow;
  }
}

void _snack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: error ? Colors.redAccent : null,
    behavior: SnackBarBehavior.floating,
  ));
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final BrandColors brandColors;
  final bool danger;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.brandColors,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = danger ? Colors.redAccent : brandColors.navy!;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text(subtitle,
                style: TextStyle(fontSize: 12, color: brandColors.muted)),
          ],
        ),
      ],
    );
  }
}

// ─── Logo Card ────────────────────────────────────────────────────────────────
// Flow: tap Choose → image previewed locally → tap Upload →
//   (1) upload new file, (2) update Firestore, (3) delete old file.

class _LogoCard extends StatefulWidget {
  final String? restaurantID;
  final String currentUrl;
  final BrandColors brandColors;
  final ColorScheme colorScheme;

  const _LogoCard({
    required this.restaurantID,
    required this.currentUrl,
    required this.brandColors,
    required this.colorScheme,
  });

  @override
  State<_LogoCard> createState() => _LogoCardState();
}

class _LogoCardState extends State<_LogoCard> {
  Uint8List? _stagedBytes;
  String? _stagedName;
  bool _uploading = false;

  Future<void> _stageImage() async {
    final result =
        await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.first.bytes == null) return;
    setState(() {
      _stagedBytes = result.files.first.bytes;
      _stagedName = result.files.first.name;
    });
  }

  Future<void> _upload() async {
    if (_stagedBytes == null) return;
    setState(() => _uploading = true);
    try {
      // 1. Upload new file to Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('restaurants')
          .child(widget.restaurantID!)
          .child('logo')
          .child('${DateTime.now().millisecondsSinceEpoch}_$_stagedName');
      await ref.putData(_stagedBytes!);
      final newUrl = await ref.getDownloadURL();

      // 2. Persist new URL to Firestore
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantID)
          .update({'logoUrl': newUrl});

      // 3. Delete old file — Firestore already points to new URL so this is safe
      await _deleteOldFile(widget.currentUrl);

      await saveUserPref<String>("logoUrl", newUrl);

      if (mounted) {
        setState(() { _stagedBytes = null; _stagedName = null; });
        _snack(context, 'Logo updated');
      }
    } catch (e) {
      if (mounted) _snack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasLogo = widget.currentUrl.isNotEmpty;
    final bool hasStaged = _stagedBytes != null;

    return _Card(
      colorScheme: widget.colorScheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(title: 'Restaurant Logo', brandColors: widget.brandColors),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: widget.brandColors.navy?.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasStaged
                        ? widget.brandColors.navy?.withValues(alpha: 0.4) ??
                            widget.colorScheme.outline
                        : widget.colorScheme.outline,
                    width: hasStaged ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasStaged
                    ? Image.memory(_stagedBytes!, fit: BoxFit.cover)
                    : hasLogo
                        ? Image.network(widget.currentUrl, fit: BoxFit.cover)
                        : Icon(Icons.restaurant_rounded,
                            size: 32, color: widget.brandColors.muted),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasStaged ? 'New logo ready' : hasLogo ? 'Logo uploaded' : 'No logo yet',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text('Recommended: 512×512px, PNG or JPG',
                        style: TextStyle(fontSize: 11, color: widget.brandColors.muted)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        SizedBox(
                          height: 34,
                          child: OutlinedButton.icon(
                            onPressed: _uploading ? null : _stageImage,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: widget.brandColors.navy,
                              side: BorderSide(
                                  color: widget.brandColors.navy?.withValues(alpha: 0.4) ?? Colors.grey),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            icon: const Icon(Icons.image_rounded, size: 14),
                            label: const Text('Choose', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        if (hasStaged) ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 34,
                            child: ElevatedButton.icon(
                              onPressed: _uploading ? null : _upload,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.brandColors.navy,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              icon: _uploading
                                  ? const SizedBox(
                                      width: 12, height: 12,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.upload_rounded, size: 14),
                              label: Text(_uploading ? 'Uploading…' : 'Upload',
                                  style: const TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Banner Card ──────────────────────────────────────────────────────────────
// Same staged pattern: tap area to choose → preview → Upload button appears.

class _BannerCard extends StatefulWidget {
  final String? restaurantID;
  final String currentUrl;
  final BrandColors brandColors;
  final ColorScheme colorScheme;

  const _BannerCard({
    required this.restaurantID,
    required this.currentUrl,
    required this.brandColors,
    required this.colorScheme,
  });

  @override
  State<_BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<_BannerCard> {
  Uint8List? _stagedBytes;
  String? _stagedName;
  bool _uploading = false;

  Future<void> _stageImage() async {
    final result =
        await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.first.bytes == null) return;
    setState(() {
      _stagedBytes = result.files.first.bytes;
      _stagedName = result.files.first.name;
    });
  }

  Future<void> _upload() async {
    if (_stagedBytes == null) return;
    setState(() => _uploading = true);
    try {
      // 1. Upload new file
      final ref = FirebaseStorage.instance
          .ref()
          .child('restaurants')
          .child(widget.restaurantID!)
          .child('banner')
          .child('${DateTime.now().millisecondsSinceEpoch}_$_stagedName');
      await ref.putData(_stagedBytes!);
      final newUrl = await ref.getDownloadURL();

      // 2. Update Firestore
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantID)
          .update({'bannerUrl': newUrl});

      // 3. Delete old file
      await _deleteOldFile(widget.currentUrl);

      await saveUserPref<String>("bannerUrl", newUrl);

      if (mounted) {
        setState(() { _stagedBytes = null; _stagedName = null; });
        _snack(context, 'Banner updated');
      }
    } catch (e) {
      if (mounted) _snack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasBanner = widget.currentUrl.isNotEmpty;
    final bool hasStaged = _stagedBytes != null;

    return _Card(
      colorScheme: widget.colorScheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(title: 'Restaurant Banner', brandColors: widget.brandColors),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _uploading ? null : _stageImage,
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: widget.brandColors.navy?.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasStaged
                      ? widget.brandColors.navy?.withValues(alpha: 0.4) ?? widget.colorScheme.outline
                      : widget.colorScheme.outline,
                  width: hasStaged ? 2 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasStaged
                  ? Stack(fit: StackFit.expand, children: [
                      Image.memory(_stagedBytes!, fit: BoxFit.cover),
                      Container(
                        color: Colors.black.withValues(alpha: 0.25),
                        child: const Center(
                          child: Icon(Icons.edit_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    ])
                  : hasBanner
                      ? Stack(fit: StackFit.expand, children: [
                          Image.network(widget.currentUrl, fit: BoxFit.cover),
                          Container(
                            color: Colors.black.withValues(alpha: 0.3),
                            child: Center(
                              child: _uploading
                                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  : const Icon(Icons.edit_rounded, color: Colors.white, size: 28),
                            ),
                          ),
                        ])
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 32, color: widget.brandColors.muted),
                            const SizedBox(height: 8),
                            Text('Click to choose banner',
                                style: TextStyle(fontSize: 12, color: widget.brandColors.muted)),
                            const SizedBox(height: 4),
                            Text('Recommended: 1200×800px',
                                style: TextStyle(fontSize: 10, color: widget.brandColors.muted)),
                          ],
                        ),
            ),
          ),
          if (hasStaged) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                onPressed: _uploading ? null : _upload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.brandColors.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: _uploading
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload_rounded, size: 16),
                label: Text(_uploading ? 'Uploading…' : 'Upload Banner',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Business Info Card ───────────────────────────────────────────────────────

class _BusinessInfoCard extends StatefulWidget {
  final String? restaurantID;
  final Map<String, dynamic> data;
  final BrandColors brandColors;
  final ColorScheme colorScheme;

  const _BusinessInfoCard({
    required this.restaurantID,
    required this.data,
    required this.brandColors,
    required this.colorScheme,
  });

  @override
  State<_BusinessInfoCard> createState() => _BusinessInfoCardState();
}

class _BusinessInfoCardState extends State<_BusinessInfoCard> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final PhoneController _mobileController;
  String _address = '';
  double? _lat;
  double? _lng;
  bool _saving = false;
  bool _edited = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.data["name"] ?? '');
    _mobileController = PhoneController(
      initialValue:
          PhoneNumber(isoCode: IsoCode.PL, nsn: widget.data["businessMobile"] ?? ''),
    );
    _address = widget.data["address"] ?? '';
    _lat = (widget.data["lat"] as num?)?.toDouble();
    _lng = (widget.data["lng"] as num?)?.toDouble();
    _nameController.addListener(_onEdit);
    _mobileController.addListener(_onEdit);
  }

  @override
  void didUpdateWidget(_BusinessInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_edited) {
      _nameController.text = widget.data["name"] ?? '';
      _address = widget.data["address"] ?? '';
      _lat = (widget.data["lat"] as num?)?.toDouble();
      _lng = (widget.data["lng"] as num?)?.toDouble();
    }
  }

  void _onEdit() => setState(() => _edited = true);

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MapPickerDialog(
        initialLat: _lat,
        initialLng: _lng,
        brandColors: widget.brandColors,
        colorScheme: widget.colorScheme,
      ),
    );
    if (result != null) {
      setState(() {
        _address = result["address"] as String;
        _lat = result["lat"] as double?;
        _lng = result["lng"] as double?;
        _edited = true;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final name = _nameController.text.trim();
      final mobile = _mobileController.value.international;

      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantID)
          .update({
        'name': name,
        'businessMobile': mobile,
        'address': _address,
        if (_lat != null) 'lat': _lat,
        if (_lng != null) 'lng': _lng,
      });

      await saveUserPref<String>("businessName", name);
      await saveUserPref<String>("businessMobile", mobile);

      if (mounted) {
        setState(() => _edited = false);
        _snack(context, 'Business info saved');
      }
    } catch (e) {
      if (mounted) _snack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      colorScheme: widget.colorScheme,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardTitle(title: 'Business Info', brandColors: widget.brandColors),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Column(
                children: [
                  CustomTextField(
                    hintText: 'Restaurant Name',
                    controller: _nameController,
                    data: Icons.storefront_rounded,
                    validator: FieldValidator.required,
                  ),
                  const SizedBox(height: 12),
                  CustomPhoneField(
                    label: 'Business Phone',
                    controller: _mobileController,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _openMapPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _address.isNotEmpty
                              ? widget.brandColors.navy?.withValues(alpha: 0.4) ?? widget.colorScheme.outline
                              : widget.colorScheme.outline,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 18,
                              color: _address.isNotEmpty
                                  ? widget.brandColors.navy
                                  : widget.brandColors.muted),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _address.isNotEmpty
                                ? Text(_address,
                                    style: const TextStyle(fontSize: 13, color: Colors.black),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis)
                                : Text('Set restaurant address',
                                    style: TextStyle(fontSize: 13, color: widget.brandColors.muted)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.brandColors.navy?.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _address.isNotEmpty ? 'Change' : 'Pick on map',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: widget.brandColors.navy),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_edited) ...[
              const SizedBox(height: 16),
              _SaveButton(saving: _saving, onPressed: _save),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── User Profile Card ────────────────────────────────────────────────────────
// Photo staged locally on pick. On Save:
//   (1) validate form, (2) upload new photo, (3) delete old photo,
//   (4) write name + phone + photoUrl to Firestore in one update.

class _UserProfileCard extends StatefulWidget {
  final String? restaurantID;
  final Map<String, dynamic> data;
  final BrandColors brandColors;
  final ColorScheme colorScheme;

  const _UserProfileCard({
    required this.restaurantID,
    required this.data,
    required this.brandColors,
    required this.colorScheme,
  });

  @override
  State<_UserProfileCard> createState() => _UserProfileCardState();
}

class _UserProfileCardState extends State<_UserProfileCard> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final PhoneController _phoneController;

  Uint8List? _stagedBytes;
  String? _stagedName;
  bool _saving = false;
  bool _edited = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.data["name"] ?? '');
    _phoneController = PhoneController(
      initialValue:
          PhoneNumber(isoCode: IsoCode.PL, nsn: widget.data["phone"] ?? ''),
    );
    _nameController.addListener(_onEdit);
    _phoneController.addListener(_onEdit);
  }

  @override
  void didUpdateWidget(_UserProfileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_edited) _nameController.text = widget.data["name"] ?? '';
  }

  void _onEdit() => setState(() => _edited = true);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _stagePhoto() async {
    final result =
        await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.first.bytes != null) {
      setState(() {
        _stagedBytes = result.files.first.bytes;
        _stagedName = result.files.first.name;
        _edited = true;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final name = _nameController.text.trim();
    final phone = _phoneController.value.international;
    final String oldPhotoUrl = widget.data['photoUrl'] ?? '';
    String photoUrl = oldPhotoUrl;

    try {
      if (_stagedBytes != null) {
        // 1. Upload new photo
        final ref = FirebaseStorage.instance
            .ref()
            .child('users')
            .child(widget.restaurantID!)
            .child('${DateTime.now().millisecondsSinceEpoch}_$_stagedName');
        await ref.putData(_stagedBytes!);
        photoUrl = await ref.getDownloadURL();

        // 2. Delete old photo — new URL is confirmed so safe to delete
        await _deleteOldFile(oldPhotoUrl);
      }

      // 3. Single Firestore write with all updated fields
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.restaurantID)
          .update({'name': name, 'phone': phone, 'photoUrl': photoUrl});

      await saveUserPref<String>("accountName", name);
      await saveUserPref<String>("phone", phone);
      await saveUserPref<String>("photoUrl", photoUrl);

      if (mounted) {
        setState(() {
          _edited = false;
          _stagedBytes = null;
          _stagedName = null;
        });
        _snack(context, 'Profile saved');
      }
    } catch (e) {
      if (mounted) _snack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? photoUrl = widget.data["photoUrl"];
    final bool hasExisting = photoUrl != null && photoUrl.isNotEmpty;
    final bool hasStaged = _stagedBytes != null;

    return _Card(
      colorScheme: widget.colorScheme,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardTitle(title: 'Profile', brandColors: widget.brandColors),
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: _saving ? null : _stagePhoto,
                  child: Stack(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.brandColors.navy?.withValues(alpha: 0.08),
                          border: Border.all(
                            color: hasStaged
                                ? widget.brandColors.navy?.withValues(alpha: 0.5) ?? widget.colorScheme.outline
                                : widget.colorScheme.outline,
                            width: hasStaged ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: hasStaged
                            ? Image.memory(_stagedBytes!, fit: BoxFit.cover)
                            : hasExisting
                                ? Image.network(photoUrl, fit: BoxFit.cover)
                                : Icon(Icons.person_rounded,
                                    size: 32, color: widget.brandColors.muted),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: hasStaged
                                ? widget.brandColors.accentGreen
                                : widget.brandColors.navy,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: widget.colorScheme.surface, width: 2),
                          ),
                          child: Icon(
                            hasStaged ? Icons.check_rounded : Icons.camera_alt_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.data["name"] ?? 'Owner',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(widget.data["email"] ?? '',
                          style: TextStyle(fontSize: 12, color: widget.brandColors.muted)),
                      const SizedBox(height: 4),
                      if (hasStaged)
                        Text(
                          'New photo ready — press Save to apply',
                          style: TextStyle(
                              fontSize: 11,
                              color: widget.brandColors.accentGreen,
                              fontWeight: FontWeight.w600),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: widget.brandColors.navy?.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.data["role"] ?? 'restaurant_admin',
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: widget.brandColors.navy),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Column(
                children: [
                  CustomTextField(
                    hintText: "Owner's Name",
                    controller: _nameController,
                    data: Icons.person_rounded,
                    validator: FieldValidator.required,
                  ),
                  const SizedBox(height: 12),
                  CustomPhoneField(
                    label: 'Phone Number',
                    controller: _phoneController,
                  ),
                ],
              ),
            ),
            if (_edited) ...[
              const SizedBox(height: 16),
              _SaveButton(saving: _saving, onPressed: _save),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Danger Zone ──────────────────────────────────────────────────────────────

class _DangerCard extends StatelessWidget {
  final BrandColors brandColors;
  final ColorScheme colorScheme;
  const _DangerCard({required this.brandColors, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return _Card(
      colorScheme: colorScheme,
      borderColor: Colors.redAccent.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow(
            context,
            icon: Icons.lock_reset_rounded,
            title: 'Change Password',
            subtitle: 'Send a password reset email to your account',
            buttonLabel: 'Reset',
            onTap: () => _snack(context, 'Password reset email sent'),
          ),
          Divider(height: 24, color: colorScheme.outline),
          _buildRow(
            context,
            icon: Icons.delete_forever_rounded,
            title: 'Delete Account',
            subtitle: 'Permanently delete your restaurant and all data',
            buttonLabel: 'Delete',
            onTap: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Delete Account'),
                content: const Text(
                    'This will permanently delete your account and all restaurant data. This cannot be undone.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Delete',
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.redAccent),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(fontSize: 12, color: brandColors.muted)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          child: Text(buttonLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ─── Map Picker Dialog ────────────────────────────────────────────────────────

class _MapPickerDialog extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final BrandColors brandColors;
  final ColorScheme colorScheme;

  const _MapPickerDialog({
    required this.initialLat,
    required this.initialLng,
    required this.brandColors,
    required this.colorScheme,
  });

  @override
  State<_MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<_MapPickerDialog> {
  String _address = '';
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _lat = widget.initialLat;
    _lng = widget.initialLng;
  }

  Future<void> _openMap() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const MapDialog(),
    );
    if (result != null && mounted) {
      setState(() {
        _address = result['address'] as String? ?? '';
        _lat = result['latitude'] as double?;
        _lng = result['longitude'] as double?;
      });
    }
  }

  void _confirm() {
    if (_address.isEmpty) {
      _snack(context, 'Please pick a location on the map first.');
      return;
    }
    Navigator.pop(context, {'address': _address, 'lat': _lat, 'lng': _lng});
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPicked = _address.isNotEmpty;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: widget.colorScheme.surface,
                border:
                    Border(bottom: BorderSide(color: widget.colorScheme.outline)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded,
                      size: 20, color: widget.brandColors.navy),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Restaurant Location',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: widget.brandColors.muted),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: hasPicked
                          ? widget.brandColors.accentGreen?.withValues(alpha: 0.06)
                          : widget.brandColors.navy?.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: hasPicked
                            ? widget.brandColors.accentGreen?.withValues(alpha: 0.3) ??
                                widget.colorScheme.outline
                            : widget.colorScheme.outline,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          hasPicked ? Icons.check_circle_rounded : Icons.location_off_rounded,
                          size: 18,
                          color: hasPicked
                              ? widget.brandColors.accentGreen
                              : widget.brandColors.muted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            hasPicked ? _address : 'No location selected yet',
                            style: TextStyle(
                                fontSize: 13,
                                color: hasPicked ? null : widget.brandColors.muted,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _openMap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: widget.brandColors.navy,
                        side: BorderSide(
                            color: widget.brandColors.navy?.withValues(alpha: 0.4) ?? Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.map_rounded, size: 18),
                      label: Text(hasPicked ? 'Change on Map' : 'Open Map',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: hasPicked ? _confirm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.brandColors.navy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        disabledBackgroundColor:
                            widget.brandColors.navy?.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Confirm Address',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
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

// ─── Shared Components ────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final ColorScheme colorScheme;
  final Color? borderColor;
  const _Card({required this.child, required this.colorScheme, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? colorScheme.outline),
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String title;
  final BrandColors brandColors;
  const _CardTitle({required this.title, required this.brandColors});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700));
  }
}

class _SaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback onPressed;
  const _SaveButton({required this.saving, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final brandColors = Theme.of(context).extension<BrandColors>()!;
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        height: 38,
        child: ElevatedButton(
          onPressed: saving ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: brandColors.navy,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          child: saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save Changes',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}