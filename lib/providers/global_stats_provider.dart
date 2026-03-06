import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Platform-wide statistics across ALL restaurants.
/// No restaurantID filter — reads every order, restaurant, and menu.
///
/// Mount once at the app root (above DashboardShell) if you need it
/// globally, or lazily at the admin screen level.
///
/// Usage:
///   ChangeNotifierProvider(
///     create: (_) => GlobalStatsProvider(),
///     child: ...,
///   )
///
///   final g = context.watch'<'GlobalStatsProvider'>'();

class GlobalStatsProvider extends ChangeNotifier {
  GlobalStatsProvider() {
    _subscribeOrders();
    _subscribeRestaurants();
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  bool get isLoading => _ordersLoading || _restaurantsLoading;
  bool _ordersLoading = true;
  bool _restaurantsLoading = true;

  // ── Orders ─────────────────────────────────────────────────────────────────

  int totalOrders = 0;
  int pendingOrders = 0;     // status == "normal"
  int processingOrders = 0;
  int completedOrders = 0;   // status == "delivered"
  int cancelledOrders = 0;
  double totalRevenue = 0;
  double avgOrderValue = 0;

  // Today
  int todayOrders = 0;
  double todayRevenue = 0;

  // Last 7 days
  int last7dOrders = 0;
  double last7dRevenue = 0;

  // Last 30 days
  int last30dOrders = 0;
  double last30dRevenue = 0;

  // Revenue per day — "dd.MM" -> revenue, 30 day window
  Map<String, double> revenueByDay = {};

  // Orders per restaurant — restaurantID -> count
  Map<String, int> ordersByRestaurant = {};

  // Revenue per restaurant — restaurantID -> revenue
  Map<String, double> revenueByRestaurant = {};

  // Status frequency
  Map<String, int> statusCounts = {};

  // ── Restaurants ────────────────────────────────────────────────────────────

  int totalRestaurants = 0;   // all restaurants including pending/rejected
  int liveRestaurants = 0;    // only approved + active (shown on landing page)
  int totalMenus = 0;
  int totalItems = 0;

  // Restaurants with at least one order
  int activeRestaurants = 0;

  // ── Internal ───────────────────────────────────────────────────────────────

  StreamSubscription<QuerySnapshot>? _ordersSub;
  StreamSubscription<QuerySnapshot>? _restaurantsSub;

  // ── Orders stream ──────────────────────────────────────────────────────────

  void _subscribeOrders() {
    _ordersSub = FirebaseFirestore.instance
        .collection('orders')
        .orderBy('orderTime', descending: true)
        .snapshots()
        .listen(_onOrderData, onError: (_) {
      _ordersLoading = false;
      notifyListeners();
    });
  }

  void _onOrderData(QuerySnapshot snap) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final day7Start = now.subtract(const Duration(days: 7));
    final day30Start = now.subtract(const Duration(days: 30));

    int tot = 0, pending = 0, proc = 0, completed = 0, canc = 0;
    double rev = 0, todRev = 0, rev7 = 0, rev30 = 0;
    int todOrd = 0, ord7 = 0, ord30 = 0;
    final Map<String, double> byDay = {};
    final Map<String, int> statuses = {};
    final Map<String, int> byRestaurant = {};
    final Map<String, double> revByRestaurant = {};

    // Pre-fill 30 days so chart has no gaps
    for (int i = 29; i >= 0; i--) {
      byDay[_label(now.subtract(Duration(days: i)))] = 0;
    }

    for (final doc in snap.docs) {
      final d = doc.data() as Map<String, dynamic>;
      final double amount =
          double.tryParse(d['totalAmount']?.toString() ?? '0') ?? 0;
      final String status = d['status']?.toString() ?? 'normal';
      final String rid = d['restaurantID']?.toString() ?? '';
      final Timestamp? ts = d['orderTime'] as Timestamp?;
      final DateTime? date = ts?.toDate();

      tot++;
      rev += amount;

      switch (status) {
        case 'normal':
          pending++;
        case 'processing':
          proc++;
        case 'delivered':
          completed++;
        case 'cancelled':
          canc++;
      }
      statuses[status] = (statuses[status] ?? 0) + 1;

      // Per-restaurant counts
      if (rid.isNotEmpty) {
        byRestaurant[rid] = (byRestaurant[rid] ?? 0) + 1;
        revByRestaurant[rid] = (revByRestaurant[rid] ?? 0) + amount;
      }

      if (date != null) {
        if (date.isAfter(todayStart)) {
          todOrd++;
          todRev += amount;
        }
        if (date.isAfter(day7Start)) {
          ord7++;
          rev7 += amount;
        }
        if (date.isAfter(day30Start)) {
          ord30++;
          rev30 += amount;
          final k = _label(date);
          if (byDay.containsKey(k)) byDay[k] = (byDay[k] ?? 0) + amount;
        }
      }
    }

    totalOrders = tot;
    pendingOrders = pending;
    processingOrders = proc;
    completedOrders = completed;
    cancelledOrders = canc;
    totalRevenue = rev;
    avgOrderValue = tot > 0 ? rev / tot : 0;
    todayOrders = todOrd;
    todayRevenue = todRev;
    last7dOrders = ord7;
    last7dRevenue = rev7;
    last30dOrders = ord30;
    last30dRevenue = rev30;
    revenueByDay = byDay;
    statusCounts = statuses;
    ordersByRestaurant = byRestaurant;
    revenueByRestaurant = revByRestaurant;
    activeRestaurants = byRestaurant.keys.length;
    _ordersLoading = false;

    notifyListeners();
  }

  // ── Restaurants stream ─────────────────────────────────────────────────────

  void _subscribeRestaurants() {
    _restaurantsSub = FirebaseFirestore.instance
        .collection('restaurants')
        .snapshots()
        .listen(_onRestaurantData, onError: (_) {
      _restaurantsLoading = false;
      notifyListeners();
    });
  }

  void _onRestaurantData(QuerySnapshot snap) async {
    // All restaurants regardless of status — for admin total count
    totalRestaurants = snap.docs.length;
    liveRestaurants = snap.docs.where((doc) {
      final status =
          (doc.data() as Map<String, dynamic>)['status']?.toString() ?? '';
      return status == 'approved' || status == 'active';
    }).length;

    // Only count menus and items for restaurants that are live (approved or active).
    // Pending / rejected / suspended restaurants should not contribute to
    // the public-facing stats shown on the landing page.
    final liveDocs = snap.docs.where((doc) {
      final status =
          (doc.data() as Map<String, dynamic>)['status']?.toString() ?? '';
      return status == 'approved' || status == 'active';
    }).toList();

    int menus = 0;
    int items = 0;

    final futures = liveDocs.map((doc) async {
      final menusSnap = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(doc.id)
          .collection('menus')
          .get();

      menus += menusSnap.docs.length;

      for (final menuDoc in menusSnap.docs) {
        final itemsSnap = await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(doc.id)
            .collection('menus')
            .doc(menuDoc.id)
            .collection('items')
            .get();
        items += itemsSnap.docs.length;
      }
    });

    await Future.wait(futures);

    totalMenus = menus;
    totalItems = items;
    _restaurantsLoading = false;

    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Top N restaurants by order count.
  List<MapEntry<String, int>> topRestaurantsByOrders({int limit = 5}) {
    final sorted = ordersByRestaurant.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  /// Top N restaurants by revenue.
  List<MapEntry<String, double>> topRestaurantsByRevenue({int limit = 5}) {
    final sorted = revenueByRestaurant.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  /// Revenue sliced to the last [days] entries for a chart.
  Map<String, double> revenueForRange(int days) {
    final entries = revenueByDay.entries.toList();
    if (entries.length <= days) return revenueByDay;
    return Map.fromEntries(entries.sublist(entries.length - days));
  }

  String _label(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _ordersSub?.cancel();
    _restaurantsSub?.cancel();
    super.dispose();
  }
}