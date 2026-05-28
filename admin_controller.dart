import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math';
import '../api/api_service.dart';

class AdminController extends GetxController {
  var currentIndex = 0.obs;
  var totalConnectedBots = 0.obs;
  var accessKeys = <dynamic>[].obs;
  var isLoading = false.obs;

  // 🤖 بوٹس لسٹ کے لیے
  var activeBots = <String>[].obs;
  var selectedBots = <String>[].obs;

  // ⚙️ فارم کنٹرولز
  var autoAllowNewBots = false.obs;
  var isAdminMode = false.obs;
  TextEditingController customKeyController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchAdminData();
  }

  void changeTab(int index) {
    currentIndex.value = index;
    if (index == 0 || index == 1) fetchAdminData();
  }

  Future<void> fetchAdminData() async {
    isLoading.value = true;
    totalConnectedBots.value = await ApiService.getStats();
    accessKeys.value = await ApiService.getKeys();
    activeBots.value = await ApiService.getActiveBots(); // 👈 لائیو بوٹس کی لسٹ
    isLoading.value = false;
  }

  // 🎯 بوٹ کو سلیکٹ یا ڈی-سلیکٹ کریں
  void toggleBotSelection(String botJid) {
    if (selectedBots.contains(botJid)) {
      selectedBots.remove(botJid);
    } else {
      selectedBots.add(botJid);
    }
  }

  // 🚀 نئی کی (Key) بنائیں
  Future<void> generateKey() async {
    String newKey = customKeyController.text.trim();
    if (newKey.isEmpty) {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      Random rnd = Random();
      newKey =
          "VIP-${String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))))}";
    }

    bool success = await ApiService.createKey(newKey, selectedBots.toList(),
        autoAllowNewBots.value, isAdminMode.value);

    if (success) {
      selectedBots.clear(); // لسٹ خالی کر دیں
      customKeyController.clear();
      await fetchAdminData();
      Get.snackbar("Success! 🔑", "Key Generated: $newKey",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF6A11CB),
          colorText: Colors.white);
    } else {
      Get.snackbar("Error", "Could not generate key (might already exist)",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white);
    }
  }

  // ✏️ کی (Key) ایڈٹ کریں
  Future<void> saveEditedKey(
      String key, List<String> editedBots, bool editedAutoAllow) async {
    bool success = await ApiService.editKey(key, editedBots, editedAutoAllow);
    if (success) {
      await fetchAdminData();
      Get.back(); // ڈائیلاگ بند کریں
      Get.snackbar("Updated", "Access Key updated successfully.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    }
  }

  // 🗑️ کی (Key) ڈیلیٹ کریں
  Future<void> deleteKey(String keyStr) async {
    bool success = await ApiService.deleteKey(keyStr);
    if (success) await fetchAdminData();
  }
}
