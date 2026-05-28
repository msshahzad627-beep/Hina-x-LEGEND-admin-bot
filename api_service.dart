import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

// ==========================================
// ⚙️ API CONFIGURATION (یہاں اپنا لنک چیک کر لیں)
// ==========================================
class ApiConfig {
  final String baseUrl = "https://https://legend-x-hina-official-bot-production.up.railway.app";
  final String wsUrl = "wss:///https://legend-x-hina-official-bot-production.up.railway.app/ws";
}

class ApiService {
  static String get baseUrl => Get.find<ApiConfig>().baseUrl;

  // 🔐 لاگ ان چیک
  static Future<Map<String, dynamic>?> login(String key) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'key': key}),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      print("Login Error: $e");
    }
    return null;
  }

  // 🤖 ایکٹو بوٹس کی لسٹ لائیں
  static Future<List<String>> getActiveBots() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/admin/active_bots'));
      if (res.statusCode == 200) {
        List<dynamic> data = jsonDecode(res.body);
        return data.map((e) => e.toString()).toList();
      }
    } catch (e) {
      print("Bots Error: $e");
    }
    return [];
  }

  // 📊 ایڈمن اسٹیٹس
  static Future<int> getStats() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/admin/stats'));
      if (res.statusCode == 200) return jsonDecode(res.body)['total_bots'];
    } catch (e) {}
    return 0;
  }

  // 🔑 تمام کیز (Keys) لائیں
  static Future<List<dynamic>> getKeys() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/admin/keys'));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {}
    return [];
  }

  // 🚀 نئی کی (Key) بنائیں (اب لسٹ جائے گی)
  static Future<bool> createKey(
      String key, List<String> bots, bool autoAllow, bool isAdmin) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/admin/keys/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': key,
          'allowed_bots': bots,
          'auto_allow': autoAllow,
          'is_admin': isAdmin
        }),
      );
      return res.statusCode == 200;
    } catch (e) {}
    return false;
  }

  // ✏️ کی (Key) کو ایڈٹ کریں
  static Future<bool> editKey(
      String key, List<String> bots, bool autoAllow) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/admin/keys/edit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'key': key, 'allowed_bots': bots, 'auto_allow': autoAllow}),
      );
      return res.statusCode == 200;
    } catch (e) {}
    return false;
  }

  // 🗑️ بوٹ کی ہسٹری ڈیلیٹ کریں
  static Future<bool> clearBotHistory(String botJid) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/clear_history'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'bot_jid': botJid}),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 💬 بوٹ کی تمام چیٹس لائیں
  static Future<List<dynamic>> getChats(String botJid) async {
    try {
      final res =
          await http.get(Uri.parse('$baseUrl/api/chats?bot_jid=$botJid'));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {}
    return [];
  }

  // 📜 کسی ایک چیٹ کے میسجز لائیں
  static Future<List<dynamic>> getMessages(
      String botJid, String chatJid) async {
    try {
      final res = await http.get(
          Uri.parse('$baseUrl/api/messages?bot_jid=$botJid&chat_jid=$chatJid'));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {}
    return [];
  }

  // 🗑️ کی (Key) ڈیلیٹ کریں
  static Future<bool> deleteKey(String key) async {
    try {
      final res = await http
          .delete(Uri.parse('$baseUrl/api/admin/keys/delete?key=$key'));
      return res.statusCode == 200;
    } catch (e) {}
    return false;
  }

  // ==================================================
  // 🚀 💬 NEW CHAT APIs (Send Messages, Media & Reply)
  // ==================================================

  // ✉️ میسج اور ریپلائی سینڈ کرنے کی API (یہ آپ کے بیک اینڈ api.go کے حساب سے بنی ہے)
  static Future<bool> sendMessage(String botJid, String chatJid, String text,
      {String replyToMsgId = "", String replyParticipant = ""}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'bot_jid': botJid,
          'chat_jid': chatJid,
          'text': text,
          'reply_to_msg_id': replyToMsgId,
          'reply_participant': replyParticipant
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      print("Send Message Error: $e");
    }
    return false;
  }

  static Future<bool> sendReaction(String botJid, String chatJid, String msgId, String emoji) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/send_reaction'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'bot_jid': botJid,
          'chat_jid': chatJid,
          'msg_id': msgId,
          'emoji': emoji,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      print("Reaction Error: $e");
    }
    return false;
  }

  static Future<bool> deleteMessage(String botJid, String chatJid, String msgId, bool everyone) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/delete_message'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'bot_jid': botJid,
          'chat_jid': chatJid,
          'msg_id': msgId,
          'everyone': everyone,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      print("Delete Message Error: $e");
    }
    return false;
  }

  static Future<bool> blockUser(String botJid, String userJid, bool block) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/block_user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'bot_jid': botJid,
          'user_jid': userJid,
          'block': block,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      print("Block Error: $e");
    }
    return false;
  }

  // 🎙️ 📸 میڈیا (Voice/Video/Image) اپلوڈ اور سینڈ کرنے کی API
  static Future<bool> uploadAndSendMedia(
      String botJid, String chatJid, String filePath, String mediaType,
      {String replyToMsgId = "", String replyParticipant = ""}) async {
    try {
      // نوٹ: بیک اینڈ پر /api/send_media کا روٹ ہونا چاہیے جو ملٹی پارٹ فائل ایکسیپٹ کرے
      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/api/send_media'));
      request.fields['bot_jid'] = botJid;
      request.fields['chat_jid'] = chatJid;
      request.fields['media_type'] = mediaType;

      if (replyToMsgId.isNotEmpty)
        request.fields['reply_to_msg_id'] = replyToMsgId;
      if (replyParticipant.isNotEmpty)
        request.fields['reply_participant'] = replyParticipant;

      // 🕸️ Web Support Fix: اگر پاتھ blob: سے شروع ہوتا ہے تو اسے بائٹس میں کنورٹ کریں
      if (filePath.startsWith('blob:')) {
        var response = await http.get(Uri.parse(filePath));
        request.files.add(http.MultipartFile.fromBytes(
            'file', response.bodyBytes,
            filename: 'media_$mediaType'));
      } else {
        // 📱 Mobile/Desktop Support
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      }

      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print("Media Upload Error: $e");
    }
    return false;
  }
}
