import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';
import '../controllers/chat_hub_controller.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatHubController hub = Get.put(ChatHubController());

    // 🚀 یہ صرف تب چلے گا جب ایپ پہلی بار اس سکرین پر آئے گی
    // اس کے اندر ویب ساکٹ کنیکٹ ہو کر 24 گھنٹے لائیو ہو جائے گا
    if (hub.botJid.value.isEmpty) {
      hub.initializeSession(Get.arguments['bot_jid']);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Obx(() => Text("Chats (${hub.botJid.value.split('@')[0]})",
            style: const TextStyle(color: Colors.white))),
        backgroundColor: const Color(0xFF1E1E2C).withOpacity(0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        // 🚀 تھری ڈاٹ مینیو (PopupMenuButton)
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'refresh') {
                // 🔥 FIX: اب بالکل صحیح فنکشن کال ہو رہا ہے جو آپ کے کنٹرولر میں موجود ہے!
                // یہ صرف API کو ہٹ کرے گا اور ویب ساکٹ کو بالکل نہیں چھیڑے گا
                hub.fetchChatsBackground(); 
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.black87, size: 22),
                      SizedBox(width: 10),
                      Text("Refresh", style: TextStyle(color: Colors.black87)),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.auroraGradient,
        child: SafeArea(
          child: Obx(() {
            if (hub.isLoading.value) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }
            if (hub.chats.isEmpty) {
              return const Center(
                  child: Text("No chats found.",
                      style: TextStyle(color: Colors.white70)));
            }

            return ListView.builder(
              itemCount: hub.chats.length,
              itemBuilder: (context, index) {
                var chat = hub.chats[index];

                String dp = chat['dp_url'] ?? "";
                String titleName = chat['push_name']?.toString() ?? "";
                if (titleName.trim().isEmpty) {
                  titleName = chat['chat_jid'].toString();
                }
                String lastMsg = chat['last_message'] ?? "📸 Media Message";

                // 🟢 ان ریڈ کاؤنٹ نکالیں
                int unread = hub.unreadCounts[chat['chat_jid']] ?? 0;

                return ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white24,
                    backgroundImage: dp.isNotEmpty ? NetworkImage(dp) : null,
                    child: dp.isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  title: Text(titleName,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(lastMsg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70)),

                  // 🟢 اگر ان ریڈ میسجز ہیں تو گرین بیج دکھاؤ
                  trailing: unread > 0
                      ? CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.greenAccent,
                          child: Text(unread.toString(),
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)))
                      : null,

                  onTap: () {
                    Get.toNamed('/chat_room', arguments: {
                      'bot_jid': hub.botJid.value,
                      'chat_jid': chat['chat_jid'],
                      'name': titleName
                    });
                  },
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
