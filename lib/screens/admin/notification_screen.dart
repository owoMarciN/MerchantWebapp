import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
import 'package:user_app/widgets/unified_snackbar.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<BrandColors>()!;
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outline),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    border: Border(bottom: BorderSide(color: scheme.outline)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFFEF4444),
                    unselectedLabelColor: brand.muted,
                    indicatorColor: const Color(0xFFEF4444),
                    indicatorWeight: 2,
                    labelStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(text: 'Send Notification'),
                      Tab(text: 'History'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _SendTab(brand: brand, scheme: scheme),
                      _HistoryTab(brand: brand, scheme: scheme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _Audience { all, restaurants, specific }

// ── Send tab ──────────────────────────────────────────────────────────────────

class _SendTab extends StatefulWidget {
  final BrandColors brand;
  final ColorScheme scheme;
  const _SendTab({required this.brand, required this.scheme});

  @override
  State<_SendTab> createState() => _SendTabState();
}

class _SendTabState extends State<_SendTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _searchController = TextEditingController();

  _Audience _audience = _Audience.all;
  bool _isLoading = false;

  List<Map<String, dynamic>> _searchResults = [];
  // Multiple selected users
  final List<Map<String, dynamic>> _selectedUsers = [];
  bool _searching = false;

  static const Color _red = Color(0xFFEF4444);

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final snap =
          await FirebaseFirestore.instance.collection('users').get();
      final q = query.toLowerCase();
      // Exclude already selected
      final selectedUIDs =
          _selectedUsers.map((u) => u['uid'] as String).toSet();
      final results = snap.docs
          .map((d) => {'uid': d.id, ...d.data()})
          .where((d) =>
              !selectedUIDs.contains(d['uid']) &&
              ((d['name']?.toString().toLowerCase() ?? '').contains(q) ||
                  (d['email']?.toString().toLowerCase() ?? '').contains(q)))
          .take(8)
          .toList();
      if (mounted) setState(() => _searchResults = results);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _addUser(Map<String, dynamic> user) {
    setState(() {
      _selectedUsers.add(user);
      // Remove the chosen user from results but keep the list open
      // so the admin can keep selecting more without re-typing.
      _searchResults.removeWhere((u) => u['uid'] == user['uid']);
    });
  }

  void _removeUser(String uid) {
    setState(() =>
        _selectedUsers.removeWhere((u) => u['uid'] == uid));
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_audience == _Audience.specific && _selectedUsers.isEmpty) {
      unifiedSnackBar(context, 'Please select at least one user.',
          error: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = FirebaseFirestore.instance;
      final String title = _titleController.text.trim();
      final String body = _bodyController.text.trim();
      final now = Timestamp.now();

      // ── 1. Resolve target UIDs ────────────────────────────────────────────
      List<String> targetUIDs = [];

      if (_audience == _Audience.specific) {
        targetUIDs =
            _selectedUsers.map((u) => u['uid'] as String).toList();
      } else if (_audience == _Audience.restaurants) {
        final snap = await db
            .collection('users')
            .where('role', isEqualTo: 'restaurant_admin')
            .get();
        targetUIDs = snap.docs.map((d) => d.id).toList();
      } else {
        final snap = await db.collection('users').get();
        targetUIDs = snap.docs.map((d) => d.id).toList();
      }

      if (targetUIDs.isEmpty) {
        if (mounted) {
          unifiedSnackBar(context, 'No users found for this audience.',
              error: true);
        }
        return;
      }

      // ── 2. Batch-write (chunked at 500) ───────────────────────────────────
      const int chunkSize = 500;
      for (int i = 0; i < targetUIDs.length; i += chunkSize) {
        final chunk = targetUIDs.sublist(
          i,
          (i + chunkSize) > targetUIDs.length
              ? targetUIDs.length
              : i + chunkSize,
        );
        final batch = db.batch();
        for (final uid in chunk) {
          final ref = db
              .collection('users')
              .doc(uid)
              .collection('notifications')
              .doc();
          batch.set(ref, {
            'title': title,
            'body': body,
            'isRead': false,
            'timestamp': now,
            'source': 'admin',
          });
        }
        await batch.commit();
      }

      // ── 3. History record ─────────────────────────────────────────────────
      final String targetName = _audience == _Audience.specific
          ? _selectedUsers.map((u) => u['name'] ?? 'Unknown').join(', ')
          : _audienceLabel(_audience);

      await db.collection('adminNotificationHistory').add({
        'title': title,
        'body': body,
        'audience': _audience.name,
        'targetName': targetName,
        'sentCount': targetUIDs.length,
        'sentAt': now,
      });

      if (!mounted) return;
      unifiedSnackBar(context,
          'Sent to ${targetUIDs.length} user${targetUIDs.length == 1 ? '' : 's'}');

      _titleController.clear();
      _bodyController.clear();
      _searchController.clear();
      setState(() {
        _audience = _Audience.all;
        _selectedUsers.clear();
        _searchResults = [];
      });
    } catch (e) {
      if (mounted) unifiedSnackBar(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _audienceLabel(_Audience a) => switch (a) {
        _Audience.all => 'All Users',
        _Audience.restaurants => 'Restaurant Owners',
        _Audience.specific => 'Specific Users',
      };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Audience selector ─────────────────────────────────────────
            const Text('Target Audience',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              children: _Audience.values.map((a) {
                final selected = _audience == a;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: a != _Audience.specific ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _audience = a;
                        _selectedUsers.clear();
                        _searchResults = [];
                        _searchController.clear();
                      }),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selected
                              ? _red.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? _red.withValues(alpha: 0.5)
                                : widget.scheme.outline,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              switch (a) {
                                _Audience.all =>
                                  Icons.groups_rounded,
                                _Audience.restaurants =>
                                  Icons.storefront_rounded,
                                _Audience.specific =>
                                  Icons.person_search_rounded,
                              },
                              size: 20,
                              color: selected ? _red : widget.brand.muted,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              switch (a) {
                                _Audience.all => 'All',
                                _Audience.restaurants => 'Restaurants',
                                _Audience.specific => 'Specific',
                              },
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: selected ? _red : widget.brand.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            // ── Specific user search ──────────────────────────────────────
            if (_audience == _Audience.specific) ...[
              const SizedBox(height: 16),

              // Selected users chips
              if (_selectedUsers.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedUsers.map((user) {
                    final name =
                        user['name']?.toString() ?? 'Unknown';
                    final photo = user['photoUrl']?.toString();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: _red.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: photo?.isNotEmpty == true
                                ? NetworkImage(photo!)
                                : null,
                            backgroundColor: widget.brand.navy
                                ?.withValues(alpha: 0.15),
                            child: photo?.isNotEmpty != true
                                ? Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: widget.brand.navy),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(name,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () =>
                                _removeUser(user['uid'] as String),
                            child: Icon(Icons.close_rounded,
                                size: 15,
                                color: widget.brand.muted),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
              ],

              // Search field
              TextField(
                controller: _searchController,
                onChanged: _searchUsers,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: _selectedUsers.isEmpty
                      ? 'Search by name or email…'
                      : 'Add more users…',
                  hintStyle: TextStyle(
                      fontSize: 13, color: widget.brand.muted),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 18, color: widget.brand.muted),
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded,
                                  size: 16, color: widget.brand.muted),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchResults = []);
                              },
                            )
                          : null,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: widget.scheme.outline)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: widget.scheme.outline)),
                  filled: true,
                  fillColor: widget.scheme.surfaceContainerLow,
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white, width: 1.5)),
                ),
              ),

              // Dropdown results
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: widget.scheme.outline),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Column(
                      children: _searchResults.map((user) {
                        final name =
                            user['name']?.toString() ?? 'Unknown';
                        final email =
                            user['email']?.toString() ?? '';
                        final photo =
                            user['photoUrl']?.toString();
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundImage:
                                photo?.isNotEmpty == true
                                    ? NetworkImage(photo!)
                                    : null,
                            backgroundColor: widget.brand.navy
                                ?.withValues(alpha: 0.1),
                            child: photo?.isNotEmpty != true
                                ? Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: widget.brand.navy),
                                  )
                                : null,
                          ),
                          title: Text(name,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(email,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: widget.brand.muted)),
                          trailing: Icon(Icons.add_circle_outline_rounded,
                              size: 18, color: widget.brand.navy),
                          onTap: () => _addUser(user),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 20),

            // ── Title ─────────────────────────────────────────────────────
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Notification Title',
                hintText: 'e.g. New feature available',
                filled: true,
                fillColor: widget.scheme.surfaceContainerLow,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: widget.scheme.outline)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white, width: 1.5)),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // ── Body ──────────────────────────────────────────────────────
            TextFormField(
              controller: _bodyController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Message',
                hintText: 'Write the notification message…',
                filled: true,
                fillColor: widget.scheme.surfaceContainerLow,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: widget.scheme.outline)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white, width: 1.5)),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),

            // ── Send button ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _isLoading ? 'Sending…' : 'Send Notification',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── History tab ───────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final BrandColors brand;
  final ColorScheme scheme;
  const _HistoryTab({required this.brand, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('adminNotificationHistory')
          .orderBy('sentAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
              child: Text(snap.error.toString(),
                  style: TextStyle(color: brand.muted)));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_none_rounded,
                    size: 48, color: brand.muted),
                const SizedBox(height: 12),
                Text('No notifications sent yet',
                    style: TextStyle(fontSize: 14, color: brand.muted)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _HistoryCard(data: data, brand: brand, scheme: scheme);
          },
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final BrandColors brand;
  final ColorScheme scheme;

  const _HistoryCard(
      {required this.data, required this.brand, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final title = data['title']?.toString() ?? '—';
    final body = data['body']?.toString() ?? '';
    final targetName = data['targetName']?.toString() ?? '—';
    final int sentCount = data['sentCount'] ?? 0;
    final Timestamp? ts = data['sentAt'] as Timestamp?;
    final String time = ts != null ? _fmt(ts.toDate()) : '—';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: Colors.green.withValues(alpha: 0.4)),
                ),
                child: const Text('Sent',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.green)),
              ),
            ],
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(body,
                style: TextStyle(fontSize: 12, color: brand.muted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.people_outline_rounded,
                  size: 13, color: brand.muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(targetName,
                    style: TextStyle(fontSize: 11, color: brand.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 14),
              Icon(Icons.check_circle_outline_rounded,
                  size: 13, color: Colors.green),
              const SizedBox(width: 4),
              Text('$sentCount sent',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.green)),
              const SizedBox(width: 14),
              Text(time,
                  style: TextStyle(fontSize: 11, color: brand.muted)),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    final date =
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    final time =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}