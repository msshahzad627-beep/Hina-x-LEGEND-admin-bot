import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';
import '../controllers/auth_controller.dart';
import '../controllers/bot_controller.dart';
import '../api/api_service.dart';

class BotListScreen extends StatelessWidget {
  const BotListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final botController = Get.put(BotController());

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("USER PANEL (BOTS)",
            style: TextStyle(color: Colors.white, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (auth.isAdmin.value)
            IconButton(
                icon: const Icon(Icons.admin_panel_settings,
                    color: Colors.orangeAccent, size: 28),
                onPressed: () => Get.offNamed('/admin')),
          IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () {
                auth.isAuthenticated.value = false;
                Get.offAllNamed('/login');
              })
        ],
      ),
      body: Container(
        decoration: AppTheme.auroraGradient,
        child: SafeArea(
          child: Obx(() {
            if (botController.isLoading.value)
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            if (botController.bots.isEmpty)
              return const Center(
                  child: Text("No bots available right now.",
                      style: TextStyle(color: Colors.white70, fontSize: 18)));

            return ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: botController.bots.length,
              itemBuilder: (context, index) {
                String bot = botController.bots[index];
                String shortName = bot.split('@')[0];

                return Card(
                  color: Colors.white.withOpacity(0.1),
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    leading: const CircleAvatar(
                        backgroundColor: AppTheme.tealGreen,
                        child: Icon(Icons.smart_toy, color: Colors.white)),
                    title: Text("Bot: $shortName",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    subtitle: const Text("Tap to view chats",
                        style: TextStyle(color: Colors.white54)),

                    // 🗑️ VIP Delete Button with Dialog
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_sweep,
                          color: Colors.redAccent, size: 28),
                      onPressed: () =>
                          _showDeleteDialog(context, shortName, bot),
                    ),

                    // 💬 Tap to Open Chat List
                    // 👈 اب یہ /chat_list کی بجائے /vip_dashboard پر جائے گا
                    onTap: () => Get.toNamed('/vip_dashboard',
                        arguments: {'bot_jid': bot}),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  // ⚠️ Delete Confirmation Dialog
  void _showDeleteDialog(
      BuildContext context, String shortName, String botJid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
          SizedBox(width: 10),
          Text("Delete History?", style: TextStyle(color: Colors.white))
        ]),
        content: Text(
            "Are you sure you want to delete all chat history for $shortName? This action cannot be undone.",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Get.back(),
              child: const Text("CANCEL",
                  style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Get.back(); // Close Dialog
              Get.snackbar("Clearing...", "Deleting history for $shortName",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.orange);
              bool success = await ApiService.clearBotHistory(botJid);
              if (success) {
                Get.snackbar("Success", "History deleted successfully!",
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: Colors.white);
              }
            },
            child: const Text("DELETE",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}
