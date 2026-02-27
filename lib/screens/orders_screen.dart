import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
import 'package:user_app/global/global.dart';
import 'package:user_app/widgets/progress_bar.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final String? _restaurantID = currentUid;

  @override
  Widget build(BuildContext context) {
    final brandColors = Theme.of(context).extension<BrandColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("orders")
          .where("restaurantID", isEqualTo: _restaurantID)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: circularProgress());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Something went wrong', style: TextStyle(color: brandColors.muted)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: Icon(Icons.receipt_long_rounded, size: 48, color: brandColors.muted),
                ),
                const SizedBox(height: 20),
                const Text(
                  'No orders right now',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'When customers place orders they will appear here.',
                  style: TextStyle(fontSize: 14, color: brandColors.muted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: const [
                      Expanded(flex: 3, child: _TableHeader('ORDER ID')),
                      Expanded(flex: 3, child: _TableHeader('CUSTOMER')),
                      Expanded(flex: 2, child: _TableHeader('ITEMS')),
                      Expanded(flex: 3, child: _TableHeader('STATUS')),
                      Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: _TableHeader('TOTAL'))),
                    ],
                  ),
                ),
                Divider(height: 1, color: colorScheme.outline),
                ...snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _OrderRow(
                    orderId: doc.id,
                    data: data,
                    brandColors: brandColors,
                    colorScheme: colorScheme,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrderRow extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;
  final BrandColors brandColors;
  final ColorScheme colorScheme;

  const _OrderRow({
    required this.orderId,
    required this.data,
    required this.brandColors,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final String status = data["status"] ?? "Pending";
    final String customerName = data["customerName"] ?? "Unknown";
    final List itemIDs = data["itemIDs"] ?? [];
    final double total = (data["totalAmount"] ?? 0).toDouble();
    final String shortId = orderId.length > 8 ? orderId.substring(0, 8) : orderId;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  '#$shortId...',
                  style: TextStyle(fontSize: 13, color: brandColors.muted, fontFamily: 'monospace'),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  customerName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${itemIDs.length} item${itemIDs.length == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 13, color: brandColors.muted),
                ),
              ),
              Expanded(
                flex: 3,
                child: _StatusChip(status: status, brandColors: brandColors),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${total.toStringAsFixed(2)} PLN',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: colorScheme.outline),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final BrandColors brandColors;
  const _StatusChip({required this.status, required this.brandColors});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'Pending' => (const Color(0xFFFEF3C7).withValues(alpha: 0.3), const Color(0xFFD97706)),
      'In Progress' => (brandColors.navy!.withValues(alpha: 0.15), brandColors.navy!),
      'Ready' => (brandColors.accentGreen!.withValues(alpha: 0.15), brandColors.accentGreen!),
      'Delivered' => (brandColors.muted!.withValues(alpha: 0.1), brandColors.muted!),
      _ => (brandColors.muted!.withValues(alpha: 0.1), brandColors.muted!),
    };

    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF8A8AA8), letterSpacing: 0.8),
    );
  }
}