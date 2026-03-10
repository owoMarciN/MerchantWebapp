import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:user_app/extensions/extensions_import.dart';

class JoinRequestsScreen extends StatefulWidget {
  const JoinRequestsScreen({super.key});

  @override
  State<JoinRequestsScreen> createState() => _JoinRequestsScreenState();
}

class _JoinRequestsScreenState extends State<JoinRequestsScreen>
    with SingleTickerProviderStateMixin {
  // Tab 0 = Restaurant registrations, Tab 1 = Go Live requests
  late final TabController _tabController;
  final String? _filter = 'pending';

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

    return Column(
      children: [
        // -- Tab bar ---------------------------------------------------------
        Container(
          color: scheme.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFFEF4444),
            unselectedLabelColor: brand.muted,
            indicatorColor: const Color(0xFFEF4444),
            indicatorWeight: 2,
            labelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: context.l10n.requests_tab_registrations),
              Tab(text: context.l10n.requests_tab_go_live),
            ],
          ),
        ),

        // -- Tab views --------------------------------------------------------
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _RegistrationsTab(brand: brand, scheme: scheme),
              _GoLiveRequestsTab(brand: brand, scheme: scheme),
            ],
          ),
        ),
      ],
    );
  }
}

// -- Registrations tab ---------------------------------------------------------

class _RegistrationsTab extends StatefulWidget {
  final BrandColors brand;
  final ColorScheme scheme;
  const _RegistrationsTab({required this.brand, required this.scheme});

  @override
  State<_RegistrationsTab> createState() => _RegistrationsTabState();
}

class _RegistrationsTabState extends State<_RegistrationsTab> {
  String? _filter = 'pending';

  @override
  Widget build(BuildContext context) {
    final brand = widget.brand;
    final scheme = widget.scheme;

    final Query query = FirebaseFirestore.instance
        .collection('restaurants')
        .orderBy('createdAt', descending: true);

    return Column(
      children: [
        // -- Filter bar ------------------------------------------------------
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(bottom: BorderSide(color: scheme.outline)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: context.l10n.requests_filter_pending,
                        icon: Icons.hourglass_top_rounded,
                        color: const Color(0xFFD97706),
                        selected: _filter == 'pending',
                        onTap: () => setState(() => _filter = 'pending'),
                        brand: brand,
                        scheme: scheme,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: context.l10n.requests_filter_approved,
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF10B981),
                        selected: _filter == 'approved',
                        onTap: () => setState(() => _filter = 'approved'),
                        brand: brand,
                        scheme: scheme,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: context.l10n.requests_filter_active,
                        icon: Icons.bolt_rounded,
                        color: const Color(0xFF8B5CF6),
                        selected: _filter == 'active',
                        onTap: () => setState(() => _filter = 'active'),
                        brand: brand,
                        scheme: scheme,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: context.l10n.requests_filter_rejected,
                        icon: Icons.cancel_rounded,
                        color: const Color(0xFFEF4444),
                        selected: _filter == 'rejected',
                        onTap: () => setState(() => _filter = 'rejected'),
                        brand: brand,
                        scheme: scheme,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: context.l10n.requests_filter_suspended,
                        icon: Icons.block_rounded,
                        color: Colors.grey,
                        selected: _filter == 'suspended',
                        onTap: () => setState(() => _filter = 'suspended'),
                        brand: brand,
                        scheme: scheme,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: context.l10n.requests_filter_all,
                        icon: Icons.list_rounded,
                        color: brand.navy!,
                        selected: _filter == null,
                        onTap: () => setState(() => _filter = null),
                        brand: brand,
                        scheme: scheme,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // -- List -------------------------------------------------------------
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Client-side filter — avoids composite index requirement
              final allDocs = snap.data?.docs ?? [];
              final docs = _filter == null
                  ? allDocs
                  : allDocs
                      .where((d) =>
                          (d.data() as Map<String, dynamic>)['status']
                              ?.toString() ==
                          _filter)
                      .toList();

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_rounded, size: 40, color: brand.muted),
                      const SizedBox(height: 12),
                      Text(
                        _filter != null
                            ? context.l10n.requests_empty_filtered(_filter!)
                            : context.l10n.requests_empty_all,
                        style: TextStyle(fontSize: 14, color: brand.muted),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final d = doc.data() as Map<String, dynamic>;
                  return _RequestCard(
                    docId: doc.id,
                    data: d,
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

// -- Go Live requests tab -----------------------------------------------------

class _GoLiveRequestsTab extends StatelessWidget {
  final BrandColors brand;
  final ColorScheme scheme;
  const _GoLiveRequestsTab({required this.brand, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('goLiveRequests')
          .orderBy('requestedAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data?.docs ?? [];
        final pending = docs
            .where((d) =>
                (d.data() as Map<String, dynamic>)['status'] == 'pending')
            .toList();
        final reviewed = docs
            .where((d) =>
                (d.data() as Map<String, dynamic>)['status'] != 'pending')
            .toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.rocket_launch_rounded, size: 40, color: brand.muted),
                const SizedBox(height: 12),
                Text(context.l10n.requests_go_live_empty,
                    style: TextStyle(fontSize: 14, color: brand.muted)),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (pending.isNotEmpty) ...[
              _sectionLabel(
                  context.l10n.requests_go_live_section_pending, brand),
              const SizedBox(height: 12),
              ...pending.map((doc) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GoLiveCard(
                      doc: doc,
                      brand: brand,
                      scheme: scheme,
                    ),
                  )),
              const SizedBox(height: 24),
            ],
            if (reviewed.isNotEmpty) ...[
              _sectionLabel(
                  context.l10n.requests_go_live_section_reviewed, brand),
              const SizedBox(height: 12),
              ...reviewed.map((doc) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GoLiveCard(
                      doc: doc,
                      brand: brand,
                      scheme: scheme,
                    ),
                  )),
            ],
          ],
        );
      },
    );
  }

  Widget _sectionLabel(String text, BrandColors brand) => Text(
        text,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: brand.muted,
            letterSpacing: 1.2),
      );
}

// -- Go Live card --------------------------------------------------------------

class _GoLiveCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final BrandColors brand;
  final ColorScheme scheme;

  const _GoLiveCard({
    required this.doc,
    required this.brand,
    required this.scheme,
  });

  @override
  State<_GoLiveCard> createState() => _GoLiveCardState();
}

class _GoLiveCardState extends State<_GoLiveCard> {
  bool _loading = false;

  Future<void> _activate() async {
    setState(() => _loading = true);
    try {
      final db = FirebaseFirestore.instance;
      final String restaurantID = widget.doc.id;

      // 1. Set restaurant status to active
      await db
          .collection('restaurants')
          .doc(restaurantID)
          .update({'status': 'active'});

      // 2. Propagate restaurantStatus to all items
      final menusSnap = await db
          .collection('restaurants')
          .doc(restaurantID)
          .collection('menus')
          .get();

      WriteBatch batch = db.batch();
      int opCount = 0;

      for (final menuDoc in menusSnap.docs) {
        final itemsSnap = await db
            .collection('restaurants')
            .doc(restaurantID)
            .collection('menus')
            .doc(menuDoc.id)
            .collection('items')
            .get();

        for (final itemDoc in itemsSnap.docs) {
          batch.update(itemDoc.reference, {'restaurantStatus': 'active'});
          opCount++;
          if (opCount == 490) {
            await batch.commit();
            batch = db.batch();
            opCount = 0;
          }
        }
      }
      if (opCount > 0) await batch.commit();

      // 3. Mark Go Live request as approved
      await db.collection('goLiveRequests').doc(restaurantID).update(
          {'status': 'approved', 'reviewedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l10n.requests_error_failed(e.toString()))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decline() async {
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('goLiveRequests')
          .doc(widget.doc.id)
          .update({
        'status': 'declined',
        'reviewedAt': FieldValue.serverTimestamp(),
      });
      // Restaurant stays at "approved" — owner sees "Declined · Reapply"
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l10n.requests_error_failed(e.toString()))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.doc.data() as Map<String, dynamic>;
    final String name = d['name']?.toString() ?? 'Unknown';
    final String restaurantID = widget.doc.id;
    final String status = d['status']?.toString() ?? 'pending';
    final Timestamp? ts = d['requestedAt'] as Timestamp?;
    final String date = ts != null ? _formatDate(ts.toDate()) : '—';
    final String timeAgo = ts != null ? _timeAgo(ts.toDate()) : '—';

    final bool isPending = status == 'pending';

    return Container(
      decoration: BoxDecoration(
        color: widget.scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.4)
              : widget.scheme.outline,
        ),
      ),
      child: Column(
        children: [
          // -- Header -------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.rocket_launch_rounded,
                      color: Color(0xFF8B5CF6), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      Text(
                          context.l10n
                              .requests_go_live_requested(timeAgo, date),
                          style: TextStyle(
                              fontSize: 11, color: widget.brand.muted)),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _badgeColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: _badgeColor(status).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _badgeLabel(status),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _badgeColor(status)),
                  ),
                ),
              ],
            ),
          ),

          // -- Setup checklist -----------------------------------------------
          if (isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _SetupChecklist(
                restaurantID: restaurantID,
                brand: widget.brand,
                scheme: widget.scheme,
              ),
            ),

          const SizedBox(height: 14),
          Divider(height: 1, color: widget.scheme.outline),

          // -- Actions -------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: _loading
                ? const SizedBox(
                    height: 36,
                    child: Center(
                        child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))),
                  )
                : isPending
                    ? Row(
                        children: [
                          _ActionButton(
                            label: context.l10n.requests_action_activate,
                            icon: Icons.bolt_rounded,
                            color: const Color(0xFF8B5CF6),
                            onTap: _activate,
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            label: context.l10n.requests_action_decline,
                            icon: Icons.close_rounded,
                            color: const Color(0xFFEF4444),
                            outline: true,
                            onTap: _decline,
                          ),
                        ],
                      )
                    : Text(
                        status == 'approved'
                            ? context.l10n.requests_go_live_activated_on(
                                _formatDate((d['reviewedAt'] as Timestamp?)
                                        ?.toDate() ??
                                    DateTime.now()))
                            : context.l10n.requests_go_live_declined_on(
                                _formatDate(
                                    (d['reviewedAt'] as Timestamp?)?.toDate() ??
                                        DateTime.now())),
                        style:
                            TextStyle(fontSize: 12, color: widget.brand.muted),
                      ),
          ),
        ],
      ),
    );
  }

  Color _badgeColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF8B5CF6);
      case 'declined':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFD97706);
    }
  }

  String _badgeLabel(String status) {
    switch (status) {
      case 'approved':
        return context.l10n.requests_badge_activated;
      case 'declined':
        return context.l10n.requests_badge_declined;
      default:
        return context.l10n.requests_badge_pending_review;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// -- Setup checklist -----------------------------------------------------------
// Fetches the restaurant doc and checks what the owner has completed.

class _SetupChecklist extends StatelessWidget {
  final String restaurantID;
  final BrandColors brand;
  final ColorScheme scheme;

  const _SetupChecklist({
    required this.restaurantID,
    required this.brand,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        FirebaseFirestore.instance
            .collection('restaurants')
            .doc(restaurantID)
            .get(),
        FirebaseFirestore.instance.collection('users').doc(restaurantID).get(),
        FirebaseFirestore.instance
            .collection('restaurants')
            .doc(restaurantID)
            .collection('menus')
            .get(),
      ]),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(
              height: 20, child: Center(child: LinearProgressIndicator()));
        }

        final restaurantData =
            (snap.data![0] as DocumentSnapshot).data() as Map<String, dynamic>;
        final userData = (snap.data![1] as DocumentSnapshot).data()
                as Map<String, dynamic>? ??
            {};
        final menusSnap = snap.data![2] as QuerySnapshot;

        final checks = [
          _Check(context.l10n.requests_check_logo,
              (restaurantData['logoUrl'] ?? '').toString().isNotEmpty),
          _Check(context.l10n.requests_check_banner,
              (restaurantData['bannerUrl'] ?? '').toString().isNotEmpty),
          _Check(context.l10n.requests_check_address,
              (restaurantData['address'] ?? '').toString().isNotEmpty),
          _Check(context.l10n.requests_check_iban,
              (restaurantData['iban'] ?? '').toString().trim().isNotEmpty),
          _Check(context.l10n.requests_check_photo,
              (userData['photoUrl'] ?? '').toString().isNotEmpty),
          _Check(context.l10n.requests_check_menu, menusSnap.docs.isNotEmpty),
        ];

        final int completed = checks.where((c) => c.done).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                    context.l10n
                        .requests_setup_progress(completed, checks.length),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: brand.muted)),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: completed / checks.length,
                      backgroundColor: scheme.outline,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          completed == checks.length
                              ? const Color(0xFF10B981)
                              : const Color(0xFFD97706)),
                      minHeight: 5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: checks.map((c) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      c.done
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 13,
                      color: c.done ? const Color(0xFF10B981) : brand.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(c.label,
                        style: TextStyle(
                            fontSize: 11,
                            color: c.done
                                ? const Color(0xFF10B981)
                                : brand.muted)),
                  ],
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _Check {
  final String label;
  final bool done;
  const _Check(this.label, this.done);
}

// -- Request card --------------------------------------------------------------

class _RequestCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final BrandColors brand;
  final ColorScheme scheme;

  const _RequestCard({
    required this.docId,
    required this.data,
    required this.brand,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final String name = data['name']?.toString() ?? 'Unknown';
    final String nip = data['nip']?.toString() ?? '—';
    final String regon = data['regon']?.toString() ?? '—';
    final String mobile = data['businessMobile']?.toString() ?? '—';
    final String status = data['status']?.toString() ?? 'pending';
    final Timestamp? ts = data['createdAt'] as Timestamp?;
    final String date = ts != null ? _formatDate(ts.toDate()) : '—';

    final _StatusStyle style = _statusStyle(context, status);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // -- Header ---------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: style.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(style.icon, color: style.color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      Text(context.l10n.requests_submitted(date),
                          style: TextStyle(fontSize: 11, color: brand.muted)),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: style.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: style.color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    style.label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: style.color),
                  ),
                ),
              ],
            ),
          ),

          // -- Details grid ---------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              children: [
                _DetailItem(label: 'NIP', value: nip, brand: brand),
                const SizedBox(width: 24),
                _DetailItem(label: 'REGON', value: regon, brand: brand),
                const SizedBox(width: 24),
                _DetailItem(label: 'Mobile', value: mobile, brand: brand),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: scheme.outline),

          // -- Actions --------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: _ActionRow(
              docId: docId,
              status: status,
              brand: brand,
              scheme: scheme,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  _StatusStyle _statusStyle(BuildContext context, String status) {
    switch (status) {
      case 'approved':
        return _StatusStyle(
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF10B981),
            label: context.l10n.requests_status_approved);
      case 'active':
        return _StatusStyle(
            icon: Icons.bolt_rounded,
            color: const Color(0xFF8B5CF6),
            label: context.l10n.requests_status_active);
      case 'rejected':
        return _StatusStyle(
            icon: Icons.cancel_rounded,
            color: const Color(0xFFEF4444),
            label: context.l10n.requests_status_rejected);
      case 'suspended':
        return _StatusStyle(
            icon: Icons.block_rounded,
            color: Colors.grey,
            label: context.l10n.requests_status_suspended);
      default:
        return _StatusStyle(
            icon: Icons.hourglass_top_rounded,
            color: const Color(0xFFD97706),
            label: context.l10n.requests_status_pending);
    }
  }
}

// -- Action row ----------------------------------------------------------------

class _ActionRow extends StatefulWidget {
  final String docId;
  final String status;
  final BrandColors brand;
  final ColorScheme scheme;

  const _ActionRow({
    required this.docId,
    required this.status,
    required this.brand,
    required this.scheme,
  });

  @override
  State<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<_ActionRow> {
  bool _loading = false;

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _loading = true);
    try {
      final db = FirebaseFirestore.instance;
      final restaurantRef = db.collection('restaurants').doc(widget.docId);

      // 1. Update the restaurant document status
      await restaurantRef.update({'status': newStatus});

      // 2. Propagate restaurantStatus to every item across all menus
      //    so Algolia can filter pending/rejected/suspended items from search.
      final menusSnap = await restaurantRef.collection('menus').get();

      // Use batched writes — max 500 ops per batch
      WriteBatch batch = db.batch();
      int opCount = 0;

      for (final menuDoc in menusSnap.docs) {
        final itemsSnap = await restaurantRef
            .collection('menus')
            .doc(menuDoc.id)
            .collection('items')
            .get();

        for (final itemDoc in itemsSnap.docs) {
          batch.update(itemDoc.reference, {'restaurantStatus': newStatus});
          opCount++;

          // Commit and start a new batch before hitting the 500 op limit
          if (opCount == 490) {
            await batch.commit();
            batch = db.batch();
            opCount = 0;
          }
        }
      }

      // Commit any remaining writes
      if (opCount > 0) await batch.commit();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.l10n.requests_error_failed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmAndUpdate(
      String newStatus, String title, String message, Color color) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(message,
            style: TextStyle(fontSize: 13, color: widget.brand.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.requests_confirm_cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(title),
          ),
        ],
      ),
    );

    if (confirmed == true) await _updateStatus(newStatus);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 36,
        child: Center(
            child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    // Buttons per status:
    // pending    → Approve, Reject
    // approved   → Suspend, Reject
    // active     → Suspend
    // rejected   → Approve
    // suspended  → Reinstate, Reject
    final buttons = <Widget>[
      if (widget.status == 'pending' || widget.status == 'rejected')
        _ActionButton(
          label: context.l10n.requests_action_approve,
          icon: Icons.check_rounded,
          color: const Color(0xFF10B981),
          onTap: () => _confirmAndUpdate(
            'approved',
            context.l10n.requests_confirm_approve_title,
            context.l10n.requests_confirm_approve_body,
            const Color(0xFF10B981),
          ),
        ),
      if (widget.status == 'pending' ||
          widget.status == 'approved' ||
          widget.status == 'suspended')
        _ActionButton(
          label: context.l10n.requests_action_reject,
          icon: Icons.close_rounded,
          color: const Color(0xFFEF4444),
          outline: true,
          onTap: () => _confirmAndUpdate(
            'rejected',
            context.l10n.requests_confirm_reject_title,
            context.l10n.requests_confirm_reject_body,
            const Color(0xFFEF4444),
          ),
        ),
      if (widget.status == 'active' || widget.status == 'approved')
        _ActionButton(
          label: context.l10n.requests_action_suspend,
          icon: Icons.block_rounded,
          color: Colors.grey,
          outline: true,
          onTap: () => _confirmAndUpdate(
            'suspended',
            context.l10n.requests_confirm_suspend_title,
            context.l10n.requests_confirm_suspend_body,
            Colors.grey,
          ),
        ),
      if (widget.status == 'suspended')
        _ActionButton(
          label: context.l10n.requests_action_reinstate,
          icon: Icons.undo_rounded,
          color: const Color(0xFF10B981),
          onTap: () => _confirmAndUpdate(
            'active',
            context.l10n.requests_confirm_reinstate_title,
            context.l10n.requests_confirm_reinstate_body,
            const Color(0xFF10B981),
          ),
        ),
    ];

    return Row(
      children: [
        // Buttons with equal 8px gaps between them
        ...buttons.expand((btn) => [btn, const SizedBox(width: 8)]).toList()
          ..removeLast(),

        const Spacer(),

        // Copy restaurant ID
        IconButton(
          tooltip: context.l10n.requests_action_copy_id,
          icon: Icon(Icons.copy_rounded, size: 16, color: widget.brand.muted),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.requests_copied(widget.docId)),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }
}

// -- Filter chip ---------------------------------------------------------------

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final BrandColors brand;
  final ColorScheme scheme;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
    required this.brand,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.4) : scheme.outline,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: selected ? color : brand.muted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? color : brand.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- Action button -------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool outline;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outline = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outline) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14, color: color),
        label: Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: Colors.white),
      label: Text(label,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// -- Detail item ---------------------------------------------------------------

class _DetailItem extends StatelessWidget {
  final String label, value;
  final BrandColors brand;

  const _DetailItem(
      {required this.label, required this.value, required this.brand});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: brand.muted)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// -- Data models ---------------------------------------------------------------

class _StatusStyle {
  final IconData icon;
  final Color color;
  final String label;
  const _StatusStyle(
      {required this.icon, required this.color, required this.label});
}
