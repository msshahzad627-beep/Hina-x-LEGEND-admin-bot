import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; // 👈 لوکل سٹوریج
import 'package:web_socket_channel/web_socket_channel.dart';
import '../api/api_service.dart';

class ChatHubController extends GetxController {
  final box = GetStorage(); // لوکل سٹوریج کا ڈبہ

  var botJid = "".obs;
  var chats = <dynamic>[].obs;
  var statuses = <dynamic>[].obs;
  var isLoading = true.obs;

  // 🟢 ان ریڈ میسجز کا کاؤنٹر
  var unreadCounts = <String, int>{}.obs;

  // 🚀 چیٹ روم کے لیے
  var currentChatMessages = <dynamic>[].obs;
  var activeChatJid = "".obs;
  var isRoomLoading = false.obs;

  WebSocketChannel? channel;

  void initializeSession(String jid) {
    botJid.value = jid;
    _loadLocalData(); // 1. فوراً لوکل ڈیٹا دکھاؤ
    fetchChatsBackground(); // 2. بیک گراؤنڈ میں API ہٹ کرو
    connectWebSocket();
  }

  // 📂 فوراً لوکل کیش دکھانے کا لاجک
  void _loadLocalData() {
    var localChats = box.read('chats_${botJid.value}');
    var localUnread = box.read('unread_${botJid.value}');

    if (localChats != null) {
      chats.value = List<dynamic>.from(localChats);
      isLoading.value = false; // لوڈر ختم!
    }
    if (localUnread != null) {
      unreadCounts.value = Map<String, int>.from(localUnread);
    }
  }

  String _sanitizeJid(String rawJid) {
    if (rawJid.contains('@')) {
       return rawJid.split('@')[0];
    }
    return rawJid;
  }

  // ☁️ بیک گراؤنڈ میں چیٹ لسٹ اپڈیٹ کریں
  void fetchChatsBackground() async {
    if (chats.isEmpty) isLoading.value = true;

    var data = await ApiService.getChats(botJid.value);

    var rawChats = data.where((c) => !c['chat_jid'].toString().contains('status')).toList();

    // Merge duplicate chats based on sanitized JID
    Map<String, dynamic> mergedChats = {};
    for (var c in rawChats) {
      String cleanJid = _sanitizeJid(c['chat_jid']);
      // If not present, or if current message is newer, update it
      if (!mergedChats.containsKey(cleanJid)) {
        c['chat_jid'] = cleanJid; // Force clean JID
        mergedChats[cleanJid] = c;
      } else {
        if (c['updated_at'] > mergedChats[cleanJid]['updated_at']) {
           c['chat_jid'] = cleanJid;
           mergedChats[cleanJid] = c;
        }
      }
    }

    chats.value = mergedChats.values.toList()..sort((a, b) => b['updated_at'].compareTo(a['updated_at']));

    statuses.value =
        data.where((c) => c['chat_jid'].toString().contains('status')).toList();

    // لوکل سٹوریج میں سیو کر لیں تاکہ اگلی بار فوراً شو ہو
    box.write('chats_${botJid.value}', chats);
    isLoading.value = false;
  }

  // 🚀 چیٹ روم کو اوپن کرتے وقت کیشنگ اور ان ریڈ لاجک
  void loadRoomMessages(String chatJid) async {
    activeChatJid.value = chatJid;

    // 1. لوکل میسجز فوراً دکھائیں
    var localMsgs = box.read('msgs_${botJid.value}_$chatJid');
    if (localMsgs != null) {
      currentChatMessages.value = List<dynamic>.from(localMsgs);
    } else {
      isRoomLoading.value = true; // اگر لوکل نہیں تو صرف تب لوڈر دکھائیں
    }

    // 2. بیک گراؤنڈ میں نئے میسجز منگوائیں
    var data = await ApiService.getMessages(botJid.value, chatJid);
    List<dynamic> formattedMsgs = data.reversed.toList();

    // 3. 🟢 ان ریڈ میسجز کی پٹی (Divider) کا لاجک
    int unread = unreadCounts[chatJid] ?? 0;
    if (unread > 0 && formattedMsgs.length >= unread) {
      // جتنے نیو میسجز ہیں، ان کے بعد ایک ڈیوائیڈر لگا دو
      formattedMsgs.insert(unread, {"is_divider": true});
    }

    currentChatMessages.value = formattedMsgs;
    box.write('msgs_${botJid.value}_$chatJid', formattedMsgs); // سیو کریں
    isRoomLoading.value = false;

    // 4. ان ریڈ کاؤنٹ کو 0 کر دیں کیونکہ یوزر نے چیٹ دیکھ لی ہے
    unreadCounts[chatJid] = 0;
    box.write('unread_${botJid.value}', unreadCounts);
    chats.refresh(); // چیٹ لسٹ کو ریفریش کریں تاکہ بیج غائب ہو جائے
  }

  // ⚡ لائیو ویب ساکٹ کنکشن
  void connectWebSocket() {
    channel = WebSocketChannel.connect(Uri.parse(ApiConfig().wsUrl));

    channel!.stream.listen((message) {
      var data = jsonDecode(message);

      if (data['type'] == 'new_message' && data['bot_jid'] == botJid.value) {
        _updateChatList(data);
        _updateChatRoom(data);
      } else if (data['type'] == 'message_status') {
        _updateMessageStatus(data);
      } else if (data['type'] == 'reaction') {
        _updateMessageReaction(data);
      }
    }, onDone: () {
      Future.delayed(const Duration(seconds: 5), connectWebSocket);
    });
  }

  void _updateMessageStatus(Map<String, dynamic> data) {
    if (data['chat_jid'] == activeChatJid.value) {
      List<dynamic> msgIds = data['message_ids'] ?? [];
      String newStatus = data['status']; // 'delivered' or 'read'

      for (String msgId in msgIds) {
        int idx = currentChatMessages.indexWhere((m) => m['msg_id'] == msgId);
        if (idx != -1) {
          var msg = currentChatMessages[idx];
          // Update status only if it's progressing forward
          if (newStatus == 'read' ||
              (newStatus == 'delivered' && msg['status'] != 'read')) {
            msg['status'] = newStatus;
            currentChatMessages[idx] = msg;
          }
        }
      }
      box.write(
          'msgs_${botJid.value}_${activeChatJid.value}', currentChatMessages);
    }
  }

  void _updateMessageReaction(Map<String, dynamic> data) {
    if (activeChatJid.value.isNotEmpty) {
      String msgId = data['message_id'];
      String emoji = data['emoji'] ?? "";

      int idx = currentChatMessages.indexWhere((m) => m['msg_id'] == msgId);
      if (idx != -1) {
        var msg = currentChatMessages[idx];
        msg['reaction'] = emoji; // Add/update reaction
        currentChatMessages[idx] = msg;
        box.write(
            'msgs_${botJid.value}_${activeChatJid.value}', currentChatMessages);
      }
    }
  }

  void _updateChatList(Map<String, dynamic> newMsg) {
    String rawChatJid = newMsg['chat_jid'];
    if (newMsg['is_status'] == true) return;

    String cleanChatJid = _sanitizeJid(rawChatJid);

    // 🟢 اگر یوزر اس چیٹ میں نہیں ہے، تو ان ریڈ کاؤنٹر بڑھا دو!
    if (activeChatJid.value != cleanChatJid &&
        newMsg['sender_jid'] != botJid.value) {
      unreadCounts[cleanChatJid] = (unreadCounts[cleanChatJid] ?? 0) + 1;
      box.write('unread_${botJid.value}', unreadCounts); // سیو کریں
    }

    int index = chats.indexWhere((c) => c['chat_jid'] == cleanChatJid);
    if (index != -1) {
      var chat = chats.removeAt(index);
      chat['last_message'] =
          newMsg['message_text'].isEmpty ? "📸 Media" : newMsg['message_text'];
      chats.insert(0, chat);
    } else {
      chats.insert(0, {
        "chat_jid": cleanChatJid,
        "push_name": newMsg['push_name'] ?? cleanChatJid,
        "last_message": newMsg['message_text'].isEmpty
            ? "📸 Media"
            : newMsg['message_text'],
        "updated_at": newMsg['timestamp'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        "dp_url": ""
      });
    }
    box.write('chats_${botJid.value}', chats); // اپڈیٹڈ لسٹ سیو کریں
  }

  void _updateChatRoom(Map<String, dynamic> newMsg) {
    if (newMsg['chat_jid'] == activeChatJid.value) {
      int tempIdx = currentChatMessages.indexWhere((m) =>
          m['msg_id'] == newMsg['msg_id'] ||
          (m['is_from_me'] == true &&
              m['text'] == newMsg['message_text'] &&
              m['status'] == 'sending'));

      if (tempIdx != -1) {
        newMsg['status'] = 'sent';
        currentChatMessages[tempIdx] = newMsg;
      } else {
        currentChatMessages.insert(0, newMsg);
      }
      box.write(
          'msgs_${botJid.value}_${activeChatJid.value}', currentChatMessages);
    }
  }

  @override
  void onClose() {
    channel?.sink.close();
    super.onClose();
  }
}
