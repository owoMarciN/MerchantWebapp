import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MenuProvider extends ChangeNotifier {
  Map<String, String> itemNames = {};
  bool isLoading = true;

  MenuProvider(String restaurantID) {
    _loadMenuNames(restaurantID);
  }

  Future<void> _loadMenuNames(String resID) async {
    if (resID.isEmpty) return;

    try {
      // Logic: Get all 'items' across all 'menus' for this restaurant
      // We use a Group Query or loop through menus. 
      // Assuming a standard structure where items are under a specific menu:
      final menuSnapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(resID)
          .collection('menus')
          .get();

      Map<String, String> tempNames = {};

      for (var menuDoc in menuSnapshot.docs) {
        final itemsSnapshot = await menuDoc.reference.collection('items').get();
        for (var itemDoc in itemsSnapshot.docs) {
          final data = itemDoc.data();
          // Map ID to Name
          tempNames[itemDoc.id] = data['itemName'] ?? 'Unknown Item';
        }
      }

      itemNames = tempNames;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading names: $e");
      isLoading = false;
      notifyListeners();
    }
  }
}