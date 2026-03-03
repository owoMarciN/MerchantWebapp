import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class OrderStatsProvider extends ChangeNotifier {
  OrderStatsProvider(String restaurantID) {
    _subscribe(restaurantID);
  }

  bool isLoading = true;

  // All-time
  int totalOrders = 0;
  int pendingOrders = 0;     // status == "normal"
  int completedOrders = 0;   // status == "delivered"
  int processingOrders = 0;
  int cancelledOrders = 0;
  double totalRevenue = 0;
  double avgOrderValue = 0;

  // Today
  int todayOrders = 0;
  double todayRevenue = 0;

  // 7d / 30d
  int last7dOrders = 0;   double last7dRevenue = 0;
  int last30dOrders = 0;  double last30dRevenue = 0;

  Map<String, double> revenueByDay = {};  // "dd.MM" -> revenue, 30 day window
  Map<String, int> itemCounts = {};       // itemID -> count
  Map<String, int> statusCounts = {};     // status -> count
  List<QueryDocumentSnapshot> docs = [];  // sorted by orderTime desc

  StreamSubscription<QuerySnapshot>? _sub;

  void _subscribe(String restaurantID) {
    if (restaurantID.isEmpty) return;
    _sub = FirebaseFirestore.instance
        .collection('orders')
        .where('restaurantID', isEqualTo: restaurantID)
        .orderBy('orderTime', descending: true)
        .snapshots()
        .listen(_onData, onError: (_) {
      isLoading = false;
      notifyListeners();
    });
  }

  void _onData(QuerySnapshot snap) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final day7Start = now.subtract(const Duration(days: 7));
    final day30Start = now.subtract(const Duration(days: 30));

    int tot = 0, pending = 0, completed = 0, proc = 0, canc = 0;
    double rev = 0, todRev = 0, rev7 = 0, rev30 = 0;
    int todOrd = 0, ord7 = 0, ord30 = 0;
    final Map<String, double> byDay = {};
    final Map<String, int> items = {};
    final Map<String, int> statuses = {};

    for (int i = 29; i >= 0; i--) {
      byDay[_label(now.subtract(Duration(days: i)))] = 0;
    }

    for (final doc in snap.docs) {
      final d = doc.data() as Map<String, dynamic>;
      final double amount = double.tryParse(d['totalAmount']?.toString() ?? '0') ?? 0;
      final String status = d['status']?.toString() ?? 'normal';
      final Timestamp? ts = d['orderTime'] as Timestamp?;
      final List itemIDs = (d['itemIDs'] as List?) ?? [];
      final DateTime? date = ts?.toDate();

      tot++; rev += amount;

      switch (status) {
        case 'normal':     pending++;
        case 'processing': proc++;
        case 'delivered':  completed++;
        case 'cancelled':  canc++;
      }
      statuses[status] = (statuses[status] ?? 0) + 1;

      if (date != null) {
        if (date.isAfter(todayStart)) { todOrd++; todRev += amount; }
        if (date.isAfter(day7Start))  { ord7++;   rev7   += amount; }
        if (date.isAfter(day30Start)) {
          ord30++; rev30 += amount;
          final k = _label(date);
          if (byDay.containsKey(k)) byDay[k] = (byDay[k] ?? 0) + amount;
        }
      }

      for (final id in itemIDs) {
        final k = id.toString();
        items[k] = (items[k] ?? 0) + 1;
      }
    }

    totalOrders = tot;       pendingOrders = pending;
    completedOrders = completed; processingOrders = proc; cancelledOrders = canc;
    totalRevenue = rev;      avgOrderValue = tot > 0 ? rev / tot : 0;
    todayOrders = todOrd;    todayRevenue = todRev;
    last7dOrders = ord7;     last7dRevenue = rev7;
    last30dOrders = ord30;   last30dRevenue = rev30;
    revenueByDay = byDay;    itemCounts = items;
    statusCounts = statuses; docs = snap.docs;
    isLoading = false;

    notifyListeners();
  }

  Map<String, double> revenueForRange(int days) {
    final entries = revenueByDay.entries.toList();
    if (entries.length <= days) return revenueByDay;
    return Map.fromEntries(entries.sublist(entries.length - days));
  }

  String _label(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }
}