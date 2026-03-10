import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:user_app/extensions/extensions_import.dart';

// -----------------------------------------------------------------------------
// ADMIN USER MANAGEMENT SCREEN
// Lists all users in the `users` collection.
// Supports search by name/email, filter by role, and per-user actions:
//   • View full profile detail sheet
//   • Ban / Unban  (sets users/{uid}/banned = true/false)
//   • Delete account (deletes users/{uid} document — does NOT delete Auth user)
// -----------------------------------------------------------------------------

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  // null = all roles
  String? _roleFilter;

  List<({String label, String? value})> _roleOptions(BuildContext context) => [
        (label: context.l10n.users_filter_all, value: null),
        (label: context.l10n.users_filter_restaurant, value: 'restaurant'),
        (label: context.l10n.users_filter_admin, value: 'admin'),
        (label: context.l10n.users_filter_customer, value: 'customer'),
      ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() =>
        setState(() => _search = _searchController.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<BrandColors>()!;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // -- Toolbar ----------------------------------------------------------
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(bottom: BorderSide(color: scheme.outline)),
          ),
          child: Row(
            children: [
              // Search
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: context.l10n.users_search_hint,
                      hintStyle: TextStyle(fontSize: 13, color: brand.muted),
                      prefixIcon: Icon(Icons.search_rounded,
                          size: 18, color: brand.muted),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded,
                                  size: 16, color: brand.muted),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _search = '');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: scheme.outline)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: scheme.outline)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFEF4444))),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Role filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _roleOptions(context).map((opt) {
                    final selected = _roleFilter == opt.value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => setState(() => _roleFilter = opt.value),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFEF4444)
                                    .withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFFEF4444)
                                      .withValues(alpha: 0.5)
                                  : scheme.outline,
                            ),
                          ),
                          child: Text(
                            opt.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w400,
                              color: selected
                                  ? const Color(0xFFEF4444)
                                  : brand.muted,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // -- List -------------------------------------------------------------
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // No orderBy — createdAt can be DateTime (legacy) or Timestamp,
            // mixed types cause Firestore to reject the query. Sort client-side.
            // The stream is only opened when the caller is authenticated;
            // the Firestore rule (allow list: if isAdmin()) enforces server-side
            // that only users whose users/{uid}.role == 'admin' may list this collection.
            stream: FirebaseAuth.instance.currentUser == null
                ? const Stream.empty()
                : FirebaseFirestore.instance.collection('users').snapshots(),
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
                        Text(
                          snap.error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Sort and filter entirely client-side.
              // orderBy('createdAt') is unsafe here because the field is
              // written as DateTime on older documents and Timestamp on newer
              // ones — Firestore rejects mixed-type ordering at the query level.
              var docs = snap.data!.docs.toList()
                ..sort((a, b) {
                  final aRaw = (a.data() as Map<String, dynamic>)['createdAt'];
                  final bRaw = (b.data() as Map<String, dynamic>)['createdAt'];

                  DateTime? aDate;
                  DateTime? bDate;

                  if (aRaw is Timestamp) aDate = aRaw.toDate();
                  if (bRaw is Timestamp) bDate = bRaw.toDate();
                  // DateTime stored directly (legacy documents)
                  if (aRaw is DateTime) aDate = aRaw;
                  if (bRaw is DateTime) bDate = bRaw;

                  if (aDate == null && bDate == null) return 0;
                  if (aDate == null) return 1;
                  if (bDate == null) return -1;
                  return bDate.compareTo(aDate); // descending
                });

              if (_roleFilter != null) {
                docs = docs
                    .where((d) =>
                        (d.data() as Map<String, dynamic>)['role']
                            ?.toString() ==
                        _roleFilter)
                    .toList();
              }

              if (_search.isNotEmpty) {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  return name.contains(_search) || email.contains(_search);
                }).toList();
              }

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_search_rounded,
                          size: 40, color: brand.muted),
                      const SizedBox(height: 12),
                      Text(
                        _search.isNotEmpty || _roleFilter != null
                            ? context.l10n.users_empty_filtered
                            : context.l10n.users_empty_all,
                        style: TextStyle(fontSize: 14, color: brand.muted),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  return _UserCard(
                    uid: doc.id,
                    data: doc.data() as Map<String, dynamic>,
                    brand: brand,
                    scheme: scheme,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// -- User card -----------------------------------------------------------------

class _UserCard extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> data;
  final BrandColors brand;
  final ColorScheme scheme;

  static const Color _red = Color(0xFFEF4444);

  const _UserCard({
    required this.uid,
    required this.data,
    required this.brand,
    required this.scheme,
  });

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _UserDetailSheet(uid: uid, data: data, brand: brand, scheme: scheme),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = data['name']?.toString() ?? 'Unknown';
    final String email = data['email']?.toString() ?? '—';
    final String role = data['role']?.toString() ?? 'customer';
    final bool banned = data['banned'] == true;
    final String? photoUrl = (data['photoUrl'] as String?)?.isNotEmpty == true
        ? data['photoUrl'] as String
        : null;
    final Timestamp? ts = data['createdAt'] as Timestamp?;
    final String joined = ts != null ? _formatDate(ts.toDate()) : '—';

    final _RoleStyle rs = _roleStyle(role, context);

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: banned ? _red.withValues(alpha: 0.35) : scheme.outline,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: brand.navy?.withValues(alpha: 0.1),
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: brand.navy),
                        )
                      : null,
                ),
                if (banned)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                          color: _red, shape: BoxShape.circle),
                      child: const Icon(Icons.block_rounded,
                          size: 9, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (banned) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                            border:
                                Border.all(color: _red.withValues(alpha: 0.3)),
                          ),
                          child: Text(context.l10n.users_banned_badge,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _red)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(email,
                      style: TextStyle(fontSize: 12, color: brand.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: rs.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                              color: rs.color.withValues(alpha: 0.3)),
                        ),
                        child: Text(rs.label,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: rs.color)),
                      ),
                      const SizedBox(width: 8),
                      Text(context.l10n.users_joined(joined),
                          style: TextStyle(fontSize: 11, color: brand.muted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Chevron
            Icon(Icons.chevron_right_rounded, size: 20, color: brand.muted),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

// -- User detail sheet ---------------------------------------------------------

class _UserDetailSheet extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> data;
  final BrandColors brand;
  final ColorScheme scheme;

  const _UserDetailSheet({
    required this.uid,
    required this.data,
    required this.brand,
    required this.scheme,
  });

  @override
  State<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<_UserDetailSheet> {
  bool _loading = false;

  static const Color _red = Color(0xFFEF4444);

  Future<void> _toggleBan() async {
    final bool currentlyBanned = widget.data['banned'] == true;
    final String action = currentlyBanned
        ? context.l10n.users_action_unban
        : context.l10n.users_action_ban;
    final String detail = currentlyBanned
        ? context.l10n.users_unban_body
        : context.l10n.users_ban_body;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$action User?',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(detail, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.users_confirm_cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentlyBanned ? const Color(0xFF10B981) : _red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _loading = true);

    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({'banned': !currentlyBanned});

      if (!mounted) return;
      Navigator.pop(context);
      messenger
        ..clearSnackBars()
        ..showSnackBar(_successSnack(currentlyBanned
            ? context.l10n.users_snack_unbanned
            : context.l10n.users_snack_banned));
    } catch (e) {
      if (!mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(_errorSnack(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteUser() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.l10n.users_delete_title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          context.l10n.users_delete_body,
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.users_confirm_cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(context.l10n.users_action_delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _loading = true);

    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .delete();

      if (!mounted) return;
      Navigator.pop(context);
      messenger
        ..clearSnackBars()
        ..showSnackBar(_successSnack(context.l10n.users_snack_deleted));
    } catch (e) {
      if (!mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(_errorSnack(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final String name = data['name']?.toString() ?? 'Unknown';
    final String email = data['email']?.toString() ?? '—';
    final String phone = data['phone']?.toString() ?? '—';
    final String role = data['role']?.toString() ?? 'customer';
    final bool banned = data['banned'] == true;
    final String? photoUrl = (data['photoUrl'] as String?)?.isNotEmpty == true
        ? data['photoUrl'] as String
        : null;
    final Timestamp? ts = data['createdAt'] as Timestamp?;
    final String joined = ts != null ? _formatDate(ts.toDate()) : '—';
    final _RoleStyle rs = _roleStyle(role, context);

    return Container(
      decoration: BoxDecoration(
        color: widget.scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          28, 24, 28, 28 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Text(context.l10n.users_detail_title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: widget.brand.muted),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Avatar + name + email
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: widget.brand.navy?.withValues(alpha: 0.1),
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: widget.brand.navy),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(email,
                          style: TextStyle(
                              fontSize: 13, color: widget.brand.muted)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: rs.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                  color: rs.color.withValues(alpha: 0.3)),
                            ),
                            child: Text(rs.label,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: rs.color)),
                          ),
                          if (banned) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                    color: _red.withValues(alpha: 0.3)),
                              ),
                              child: Text(context.l10n.users_banned_badge,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _red)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Divider(color: widget.scheme.outline),
            const SizedBox(height: 16),

            // Detail grid
            _DetailRow(
                label: context.l10n.users_detail_id,
                value: widget.uid,
                copyable: true,
                brand: widget.brand),
            _DetailRow(
                label: context.l10n.users_detail_phone,
                value: phone,
                brand: widget.brand),
            _DetailRow(
                label: context.l10n.users_detail_joined,
                value: joined,
                brand: widget.brand),
            _DetailRow(
                label: context.l10n.users_detail_role,
                value: role,
                brand: widget.brand),

            const SizedBox(height: 24),

            // Actions
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Row(
                children: [
                  // Ban / Unban
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _toggleBan,
                      icon: Icon(
                        banned ? Icons.lock_open_rounded : Icons.block_rounded,
                        size: 16,
                      ),
                      label: Text(banned
                          ? context.l10n.users_action_unban
                          : context.l10n.users_action_ban),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            banned ? const Color(0xFF10B981) : _red,
                        side: BorderSide(
                            color: banned ? const Color(0xFF10B981) : _red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Delete
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _deleteUser,
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: Text(context.l10n.users_action_delete),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

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
      );

  SnackBar _errorSnack(String msg) => SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500))),
        ]),
        backgroundColor: Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      );
}

// -- Detail row ----------------------------------------------------------------

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;
  final BrandColors brand;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.brand,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child:
                Text(label, style: TextStyle(fontSize: 12, color: brand.muted)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.users_copied),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              child: Icon(Icons.copy_rounded, size: 15, color: brand.muted),
            ),
        ],
      ),
    );
  }
}

// -- Helpers -------------------------------------------------------------------

class _RoleStyle {
  final String label;
  final Color color;
  const _RoleStyle(this.label, this.color);
}

_RoleStyle _roleStyle(String role, BuildContext context) {
  switch (role) {
    case 'admin':
      return _RoleStyle(context.l10n.users_role_admin, const Color(0xFFEF4444));
    case 'restaurant':
      return _RoleStyle(
          context.l10n.users_role_restaurant, const Color(0xFF8B5CF6));
    case 'customer':
      return _RoleStyle(
          context.l10n.users_role_customer, const Color(0xFF3B82F6));
    default:
      return _RoleStyle(role, const Color(0xFF6B7280));
  }
}
