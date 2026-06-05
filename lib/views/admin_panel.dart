import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../theme/app_theme.dart';
import '../controllers/admin_controller.dart';
import '../controllers/auth_controller.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.put(AdminController());
    final auth = Get.find<AuthController>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("ADMIN DASHBOARD",
            style: TextStyle(color: Colors.white, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // 🔄 Switch Button: یوزر پینل پر جانے کے لیے
          IconButton(
            icon: const Icon(Icons.people_alt_outlined,
                color: Colors.lightBlueAccent, size: 28),
            tooltip: "Switch to User Panel",
            onPressed: () => Get.offNamed('/bots'), // یوزر پینل پر سوئچ
          ),
          // 🚪 Logout Button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              auth.isAuthenticated.value = false;
              Get.offAllNamed('/login');
            },
          )
        ],
      ),
      body: Container(
        decoration: AppTheme.auroraGradient,
        child: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value && controller.accessKeys.isEmpty) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }
            return controller.currentIndex.value == 0
                ? _buildHomeTab(controller)
                : _buildSettingsTab(controller, context);
          }),
        ),
      ),
      bottomNavigationBar: Obx(() => Container(
            color: const Color(0xFF1E1E2C).withOpacity(0.9),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppTheme.tealGreen,
              unselectedItemColor: Colors.white54,
              currentIndex: controller.currentIndex.value,
              onTap: controller.changeTab,
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard), label: "Home"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.vpn_key), label: "Keys"),
              ],
            ),
          )),
    );
  }

  Widget _buildHomeTab(AdminController controller) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Live System Stats",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(
                  "Active Bots",
                  controller.totalConnectedBots.value.toString(),
                  Icons.smart_toy),
              _buildStatCard("Access Keys",
                  controller.accessKeys.length.toString(), Icons.key),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return GlassmorphicContainer(
      width: Get.width * 0.42,
      height: 120,
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(colors: [
        Colors.white.withOpacity(0.2),
        Colors.white.withOpacity(0.05)
      ]),
      borderGradient: LinearGradient(colors: [
        Colors.white.withOpacity(0.5),
        Colors.white.withOpacity(0.2)
      ]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text(title, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(AdminController controller, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Generate Access Key",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 15),
                GlassmorphicContainer(
            width: double.infinity,
            height: 420,
            borderRadius: 20,
            blur: 15,
            alignment: Alignment.topCenter,
            border: 2,
            linearGradient: LinearGradient(colors: [
              Colors.white.withOpacity(0.2),
              Colors.white.withOpacity(0.05)
            ]),
            borderGradient: LinearGradient(colors: [
              Colors.white.withOpacity(0.5),
              Colors.white.withOpacity(0.2)
            ]),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller.customKeyController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Custom Key Name (Optional)",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.black12,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 0),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text("Select Allowed Bots:",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(10)),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: controller.activeBots.isEmpty
                            ? const Text("No active bots available.",
                                style: TextStyle(color: Colors.white54))
                            : Obx(() => Wrap(
                                  spacing: 8.0,
                                  children: controller.activeBots.map((bot) {
                                    bool isSelected =
                                        controller.selectedBots.contains(bot);
                                    return ChoiceChip(
                                      label: Text(bot.split('@')[0],
                                          style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.black87)),
                                      selected: isSelected,
                                      selectedColor: AppTheme.tealGreen,
                                      backgroundColor: Colors.white70,
                                      onSelected: (_) =>
                                          controller.toggleBotSelection(bot),
                                    );
                                  }).toList(),
                                )),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text("Auto-Allow New Bots",
                        style: TextStyle(color: Colors.white)),
                    activeColor: AppTheme.tealGreen,
                    value: controller.autoAllowNewBots.value,
                    onChanged: (val) => controller.autoAllowNewBots.value = val,
                  ),
                  SwitchListTile(
                    title: const Text("Admin Mode",
                        style: TextStyle(color: Colors.white)),
                    activeColor: Colors.redAccent,
                    value: controller.isAdminMode.value,
                    onChanged: (val) => controller.isAdminMode.value = val,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.tealGreenDark,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      onPressed: controller.generateKey,
                      child: const Text("GENERATE KEY",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
                const SizedBox(height: 15),
                const Text("Active Keys",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
          ),
          if (controller.accessKeys.isEmpty)
            const SliverFillRemaining(
              child: Center(
                  child: Text("No keys generated yet.",
                      style: TextStyle(color: Colors.white54))),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  var keyData = controller.accessKeys[index];
                  bool isAdmin = keyData["is_admin"];
                  List<dynamic> allowedList = keyData["allowed_bots"] ?? [];

                  return Card(
                    color: Colors.white.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      leading: Icon(
                          isAdmin
                              ? Icons.admin_panel_settings
                              : Icons.vpn_key,
                          color: isAdmin ? Colors.redAccent : Colors.white),
                      title: Text(keyData["key"],
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2)),
                      subtitle: Text(
                          "Bots Allowed: ${allowedList.length} | Auto: ${keyData['auto_allow'] ? 'ON' : 'OFF'}",
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isAdmin)
                            IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.lightBlueAccent),
                                onPressed: () => _openEditDialog(
                                    context, controller, keyData)),
                          IconButton(
                              icon: const Icon(Icons.delete_sweep,
                                  color: Colors.redAccent),
                              onPressed: () =>
                                  controller.deleteKey(keyData["key"])),
                        ],
                      ),
                    ),
                  );
                },
                childCount: controller.accessKeys.length,
              ),
            ),
        ],
      ),
    );
  }

  void _openEditDialog(BuildContext context, AdminController controller,
      Map<String, dynamic> keyData) {
    List<String> currentBots = List<String>.from(keyData["allowed_bots"] ?? []);
    RxList<String> tempSelectedBots = currentBots.obs;
    RxBool tempAutoAllow = (keyData["auto_allow"] as bool).obs;

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2E2E48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Edit ${keyData['key']}",
                style: const TextStyle(color: Colors.white)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Select Bots:",
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 10),
                  Obx(() => Wrap(
                        spacing: 8.0,
                        children: controller.activeBots.map((bot) {
                          bool isSelected = tempSelectedBots.contains(bot);
                          return ChoiceChip(
                            label: Text(bot.split('@')[0]),
                            selected: isSelected,
                            selectedColor: AppTheme.tealGreen,
                            onSelected: (_) {
                              if (isSelected)
                                tempSelectedBots.remove(bot);
                              else
                                tempSelectedBots.add(bot);
                            },
                          );
                        }).toList(),
                      )),
                  const Divider(color: Colors.white24, height: 30),
                  Obx(() => SwitchListTile(
                        title: const Text("Auto-Allow New",
                            style: TextStyle(color: Colors.white)),
                        value: tempAutoAllow.value,
                        activeColor: AppTheme.tealGreen,
                        onChanged: (val) => tempAutoAllow.value = val,
                      )),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Get.back(),
                  child: const Text("Cancel",
                      style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tealGreen),
                onPressed: () => controller.saveEditedKey(keyData['key'],
                    tempSelectedBots.toList(), tempAutoAllow.value),
                child: const Text("Save Changes"),
              )
            ],
          );
        });
  }
}
