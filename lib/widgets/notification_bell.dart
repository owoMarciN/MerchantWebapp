import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:user_app/extensions/brand_color_ext.dart';

// -----------------------------------------------------------------------------
// NOTIFICATION BELL + SHEET
//
// Used in the restaurant dashboard topbar.
//
// Usage in dashboard_shells.dart:
//   NotificationBell(
//     uid: restaurantID,
//     brandColors: brandColors,
//     colorScheme: colorScheme,
//   )
// -----------------------------------------------------------------------------

class NotificationBell extends StatefulWidget {
  final String? uid;
  final BrandColors brandColors;
  final ColorScheme colorScheme;

  const NotificationBell({
    super.key,
    required this.uid,
    required this.brandColors,
    required this.colorScheme,
  });

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  int _previousUnread = 0;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.12, end: -0.12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.12, end: 0.12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.12, end: -0.12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.12, end: 0.0), weight: 1),
    ]).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onUnreadChanged(int newCount) {
    if (newCount > _previousUnread) {
      _shakeController.forward(from: 0);
    }
    _previousUnread = newCount;
  }

  void _openSheet() {
    if (widget.uid == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationSheet(
        uid: widget.uid!,
        brandColors: widget.brandColors,
        colorScheme: widget.colorScheme,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snap) {
        final int unread = snap.data?.docs.length ?? 0;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onUnreadChanged(unread);
        });

        return AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (_, child) =>
              Transform.rotate(angle: _shakeAnimation.value, child: child),
          child: GestureDetector(
            onTap: _openSheet,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                border: Border.all(color: widget.colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Icon(
                      unread > 0
                          ? Icons.notifications_rounded
                          : Icons.notifications_none_rounded,
                      size: 24,
                      color: unread > 0
                          ? widget.brandColors.navy
                          : widget.brandColors.muted,
                    ),
                  ),
                  if (unread > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// -- Notification bottom sheet -------------------------------------------------

class _NotificationSheet extends StatelessWidget {
  final String uid;
  final BrandColors brandColors;
  final ColorScheme colorScheme;

  const _NotificationSheet({
    required this.uid,
    required this.brandColors,
    required this.colorScheme,
  });

  Future<void> _markAllRead() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Text('Notifications',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                // Live unread badge
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('notifications')
                      .where('isRead', isEqualTo: false)
                      .snapshots(),
                  builder: (_, snap) {
                    final int count = snap.data?.docs.length ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.3)),
                      ),
                      child: Text('$count unread',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.redAccent)),
                    );
                  },
                ),
                TextButton(
                  onPressed: _markAllRead,
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text('Mark all read',
                      style: TextStyle(
                          fontSize: 13, color: brandColors.accentGreen)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: colorScheme.outline),

          // List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('notifications')
                  .orderBy('timestamp', descending: true)
                  .limit(30)
                  .snapshots(),
              builder: (context, snap) {
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
                            size: 48, color: brandColors.muted),
                        const SizedBox(height: 12),
                        const Text('No notifications yet',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text('Admin messages will appear here',
                            style: TextStyle(
                                fontSize: 12, color: brandColors.muted)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _NotificationTile(
                    doc: docs[i],
                    brandColors: brandColors,
                    colorScheme: colorScheme,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -- Notification tile ---------------------------------------------------------

class _NotificationTile extends StatelessWidget {
  final DocumentSnapshot doc;
  final BrandColors brandColors;
  final ColorScheme colorScheme;

  const _NotificationTile({
    required this.doc,
    required this.brandColors,
    required this.colorScheme,
  });

  Future<void> _markRead() async {
    if ((doc.data() as Map)['isRead'] == true) return;
    await doc.reference.update({'isRead': true});
  }

  Future<void> _delete() async {
    await doc.reference.delete();
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final String title = data['title']?.toString() ?? 'Notification';
    final String body = data['body']?.toString() ?? '';
    final bool isRead = data['isRead'] == true;
    final dynamic rawTs = data['timestamp'] ?? data['createdAt'];
    final DateTime? date = rawTs is Timestamp ? rawTs.toDate() : null;

    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.redAccent, size: 20),
      ),
      onDismissed: (_) => _delete(),
      child: GestureDetector(
        onTap: _markRead,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead
                ? colorScheme.surface
                : brandColors.navy?.withValues(alpha: 0.05) ??
                    colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRead
                  ? colorScheme.outline
                  : brandColors.navy?.withValues(alpha: 0.2) ??
                      colorScheme.outline,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isRead
                      ? colorScheme.surfaceBright
                      : brandColors.navy?.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRead
                      ? Icons.notifications_none_rounded
                      : Icons.notifications_active_rounded,
                  size: 24,
                  color: isRead ? brandColors.muted : brandColors.navy,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isRead
                                ? FontWeight.w500
                                : FontWeight.w700)),
                        ),
                        if (!isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 14,
                            height: 14,
                            margin: const EdgeInsets.only(top: 3),
                            decoration: BoxDecoration(
                              color: brandColors.navy,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(body,
                          style: TextStyle(
                              fontSize: 12,
                              color: brandColors.muted,
                              height: 1.4)),
                    ],
                    if (date != null) ...[
                      const SizedBox(height: 6),
                      Text(_fmt(date),
                          style: TextStyle(
                              fontSize: 10, color: brandColors.muted)),
                    ],
                  ],
                ),
              ),

              // Delete button
              GestureDetector(
                onTap: _delete,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(Icons.close_rounded,
                      size: 20, color: brandColors.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }
}
