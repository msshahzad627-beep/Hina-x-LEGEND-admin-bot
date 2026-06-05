import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../api/api_service.dart';

class AuthController extends GetxController {
  var isAdmin = false.obs;
  var isAuthenticated = false.obs;
  var userKey = "".obs;
  var allowedBots = <String>[].obs; // 👈 اب یہ لسٹ ہے
  var isLoading = false.obs;

  Future<void> login(String password) async {
    if (password.isEmpty) return;

    isLoading.value = true;
    var response = await ApiService.login(password);
    isLoading.value = false;

    if (response != null && response['status'] == 'success') {
      isAuthenticated.value = true;
      isAdmin.value = response['is_admin'];

      // ڈیٹا بیس سے آنے والی لسٹ کو سیو کریں
      if (response['allowed_bots'] != null) {
        allowedBots.value = List<String>.from(response['allowed_bots']);
      }
      userKey.value = password;

      if (isAdmin.value) {
        Get.offAllNamed('/admin');
      } else {
        Get.offAllNamed('/bots');
      }
    } else {
      Get.snackbar("Access Denied", "Invalid or Expired VIP Key",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withOpacity(0.9),
          colorText: Colors.white);
    }
  }
}
