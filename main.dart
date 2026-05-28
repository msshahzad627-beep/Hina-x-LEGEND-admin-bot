import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'theme/app_theme.dart';
import 'controllers/auth_controller.dart';
import 'api/api_service.dart';
import 'package:get_storage/get_storage.dart';

// آپ کی سکرینز امپورٹ ہو رہی ہیں
import 'views/login_screen.dart';
import 'views/admin_panel.dart';
import 'views/bot_list_screen.dart';
import 'views/vip_dashboard.dart'; // 👈 یہ رہی ہماری نئی ڈیش بورڈ سکرین (Chats + Status)
import 'views/chat_room_screen.dart';

import 'views/story_view_screen.dart';

// 🚀 FIX: یہاں 'async' لگانا لازمی تھا کیونکہ اندر 'await' استعمال ہو رہا ہے
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⚙️ کنفیگریشن اور کنٹرولرز سٹارٹ کریں
  Get.put(ApiConfig());
  Get.put(AuthController());
  await GetStorage.init(); // 👈 اب یہ بالکل پرفیکٹ کام کرے گا

  runApp(const SilentNexusApp());
}

class SilentNexusApp extends StatelessWidget {
  const SilentNexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Silent Nexus VIP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // WhatsApp respects system theme
      initialRoute: '/login', // 👈 ایپ لاگ ان سے شروع ہوگی
      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/admin', page: () => const AdminPanel()),
        GetPage(name: '/bots', page: () => const BotListScreen()),

        // 🚀 یہ ہے وہ نیا راؤٹ جو ہم نے پرانے /chat_list کی جگہ لگایا ہے
        GetPage(name: '/vip_dashboard', page: () => const VIPDashboard()),

        GetPage(name: '/chat_room', page: () => const ChatRoomScreen()),
        GetPage(
            name: '/story_view',
            page: () => StoryViewScreen(
                  statuses: Get.arguments['statuses'],
                  userName: Get.arguments['name'],
                  userDp: Get.arguments['dp_url'],
                )),
      ],
    );
  }
}
