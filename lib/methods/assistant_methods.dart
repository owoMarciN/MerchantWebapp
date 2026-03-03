import 'package:firebase_storage/firebase_storage.dart';

List<String> separateItemIDs(List<dynamic> userCart) {
  return userCart.map((item) {
    List<String> parts = item.toString().split(':');
    return parts.length >= 3 ? parts[2] : '';
  }).toList();
}

List<int> separateItemQuantities(List<dynamic> userCart) {
  return userCart.map((item) {
    List<String> parts = item.toString().split(':');
    return parts.length >= 4 ? int.parse(parts[3]) : 1;
  }).toList();
}

/// Deletes a file from Firebase Storage given its URL.
/// Returns a [String?] containing an error message if it fails, or null if successful.
Future<String?> deleteOldFile(String url) async {
  if (url.isEmpty || !url.contains('firebasestorage')) return null;

  try {
    await FirebaseStorage.instance.refFromURL(url).delete();
    return null; // Success
  } on FirebaseException catch (e) {
    // 1. Silent ignore for already deleted files
    if (e.code == 'object-not-found') {
      return null; 
    }

    // 2. Handle specific UI-friendly errors
    if (e.code == 'permission-denied') {
      return "You don't have permission to edit this.";
    }
    if (e.code == 'network-request-failed') {
      return "Check your internet connection.";
    }

    // 3. Fallback for other Firebase errors
    return "Storage error: ${e.message}";
  } catch (e) {
    // 4. Catch-all for non-Firebase exceptions
    return "An unexpected error occurred.";
  }
}
