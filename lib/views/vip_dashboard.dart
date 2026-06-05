import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../theme/app_theme.dart';
import '../controllers/chat_hub_controller.dart';

class VIPDashboard extends StatefulWidget {
  const VIPDashboard({super.key});

  @override
  State<VIPDashboard> createState() => _VIPDashboardState();
}

class _VIPDashboardState extends State<VIPDashboard> {
  final ChatHubController hub = Get.put(ChatHubController());
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    hub.initializeSession(Get.arguments['bot_jid']);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("WhatsApp", style: theme.appBarTheme.titleTextStyle),
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          actions: [
            Obx(() {
              // چھوٹا لوڈر جو بتائے کہ بیک گراؤنڈ میں میسجز/چیٹس ریفریش ہو رہے ہیں
              if (hub.isLoading.value) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            IconButton(
                icon: const Icon(Icons.camera_alt_outlined), onPressed: () {}),
            IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            
            // 🚀 تھری ڈاٹ مینیو (PopupMenuButton) میں ریفریش بٹن لگا دیا ہے!
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'refresh') {
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
          bottom: TabBar(
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            indicatorColor: isDark ? AppTheme.tealGreen : Colors.white,
            labelColor: isDark ? AppTheme.tealGreen : Colors.white,
            unselectedLabelColor:
                isDark ? AppTheme.textSecondaryDark : Colors.white70,
            tabs: const [
              Tab(text: "CHATS"),
              Tab(text: "UPDATES"),
            ],
          ),
        ),
        body: Container(
          color: theme.scaffoldBackgroundColor,
          child: Obx(() {
            return TabBarView(
              children: [
                _buildChatList(theme), 
                _buildStatusList(theme), 
              ],
            );
          }),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          backgroundColor: AppTheme.lightGreen,
          child: Icon(
            _currentIndex == 0 ? Icons.message : Icons.camera_alt,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _deleteChat(String chatJid) async {
    bool confirm = await Get.defaultDialog(
          title: "Delete chat?",
          middleText: "Messages will be removed from this device.",
          textConfirm: "Delete chat",
          textCancel: "Cancel",
          confirmTextColor: Colors.white,
          buttonColor: AppTheme.tealGreen,
        ) ??
        false;

    if (confirm) {
      hub.chats.removeWhere((c) => c['chat_jid'] == chatJid);
      Get.snackbar("Deleted", "Chat deleted successfully",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "";
    int ts = timestamp is int ? timestamp : int.tryParse(timestamp.toString()) ?? 0;
    if (ts == 0) return "";
    var date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildChatList(ThemeData theme) {
    if (hub.chats.isEmpty)
      return Center(
          child: Text("No chats yet.",
              style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7))));

    return ListView.builder(
      itemCount: hub.chats.length,
      itemBuilder: (context, index) {
        var chat = hub.chats[index];
        String dp = chat['dp_url'] ?? "";
        int unread = hub.unreadCounts[chat['chat_jid']] ?? 0;
        String timeStr = _formatTimestamp(chat['updated_at']);

        return InkWell(
          onLongPress: () {
            Get.bottomSheet(
              Container(
                color: theme.scaffoldBackgroundColor,
                child: Wrap(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete chat',
                          style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color)),
                      onTap: () {
                        Get.back();
                        _deleteChat(chat['chat_jid']);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          onTap: () {
            Get.toNamed('/chat_room', arguments: {
              'bot_jid': hub.botJid.value,
              'chat_jid': chat['chat_jid'],
              'name': chat['push_name']
            });
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.grey.shade400,
                  backgroundImage: dp.isNotEmpty ? NetworkImage(dp) : null,
                  child: dp.isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 30)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              chat['push_name'],
                              style: TextStyle(
                                  color: theme.textTheme.bodyLarge?.color,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            timeStr,
                            style: TextStyle(
                                color: unread > 0
                                    ? AppTheme.lightGreen
                                    : (theme.brightness == Brightness.dark
                                        ? AppTheme.textSecondaryDark
                                        : AppTheme.textSecondaryLight),
                                fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.done_all,
                              size: 16, color: AppTheme.blueTick),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              chat['last_message'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: theme.brightness == Brightness.dark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight,
                                  fontSize: 14),
                            ),
                          ),
                          if (unread > 0)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppTheme.lightGreen,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unread.toString(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusList(ThemeData theme) {
    Map<String, List<dynamic>> groupedStatuses = {};
    for (var status in hub.statuses) {
      String jid = status['sender_jid'] ?? status['chat_jid'] ?? "";
      if (!groupedStatuses.containsKey(jid)) {
        groupedStatuses[jid] = [];
      }
      groupedStatuses[jid]!.add(status);
    }

    var userJids = groupedStatuses.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text("Recent updates",
              style: TextStyle(
                  color: theme.brightness == Brightness.dark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ),
        Expanded(
          child: userJids.isEmpty
              ? Center(
                  child: Text("No recent updates.",
                      style: TextStyle(
                          color: theme.brightness == Brightness.dark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight)))
              : ListView.builder(
                  itemCount: userJids.length,
                  itemBuilder: (context, index) {
                    var jid = userJids[index];
                    var userStatuses = groupedStatuses[jid]!;
                    var latestStatus = userStatuses.last; 

                    String dp = latestStatus['dp_url'] ?? "";
                    String name = latestStatus['push_name']?.toString() ?? "";
                    if (name.trim().isEmpty)
                      name = jid.toString().split('@')[0];

                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppTheme.lightGreen,
                              width: 2.5), 
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey.shade400,
                          backgroundImage:
                              dp.isNotEmpty ? NetworkImage(dp) : null,
                          child: dp.isEmpty
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                      ),
                      title: Text(name,
                          style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                              fontWeight: FontWeight.bold)),
                      subtitle: Text("${userStatuses.length} updates",
                          style: TextStyle(
                              color: theme.brightness == Brightness.dark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight)),
                      onTap: () {
                        Get.toNamed('/story_view', arguments: {
                          'statuses': userStatuses,
                          'name': name,
                          'dp_url': dp
                        });
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
