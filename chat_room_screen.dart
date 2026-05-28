import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:record/record.dart';
// ignore: depend_on_referenced_packages
import '../theme/app_theme.dart';
import '../api/api_service.dart';
import '../controllers/chat_hub_controller.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatHubController hub = Get.find<ChatHubController>();

  final ScrollController _scrollController = ScrollController();
  bool showScrollToBottom = false;
  bool showScrollToTop = false;

  String botJid = "";
  String chatJid = "";
  String chatName = "";

  final TextEditingController _msgController = TextEditingController();
  bool isTyping = false;

  Map<String, dynamic>? replyingToMsg;

  final _audioRecorder = AudioRecorder();
  bool isRecording = false;
  double swipeOffset = 0.0;

  @override
  void initState() {
    super.initState();
    botJid = Get.arguments['bot_jid'] ?? "";
    chatJid = Get.arguments['chat_jid'] ?? "";
    chatName = Get.arguments['name'] ?? "User";

    // 🚀 یہاں JID کو کلین کیا گیا ہے تاکہ اگر نام کی جگہ پوری JID آ رہی ہو تو صرف نمبر شو ہو
    if (chatName.contains('@')) {
      chatName = chatName.split('@')[0];
    }

    hub.loadRoomMessages(chatJid);

    _msgController.addListener(() {
      setState(() {
        isTyping = _msgController.text.trim().isNotEmpty;
      });
    });

    _scrollController.addListener(() {
      setState(() {
        showScrollToBottom = _scrollController.offset > 200;
        showScrollToTop = _scrollController.hasClients &&
            _scrollController.offset <
                _scrollController.position.maxScrollExtent - 200;
      });
    });
  }

  @override
  void dispose() {
    hub.activeChatJid.value = "";
    _msgController.dispose();
    _audioRecorder.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showContactInfo() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E2C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.tealGreen,
                child: Icon(Icons.person, size: 50, color: Colors.white)),
            const SizedBox(height: 15),
            Text(chatName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text("📞 Phone: ${chatJid.split('@')[0]}",
                style: const TextStyle(
                    color: Colors.lightBlueAccent, fontSize: 16)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoAction(Icons.call, "Audio"),
                _buildInfoAction(Icons.videocam, "Video"),
                _buildInfoAction(Icons.search, "Search"),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.redAccent),
              title: const Text("Block User", style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                 Get.back();
                 _blockUser(chatJid, true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: Colors.white70),
              title: const Text("Unblock User", style: TextStyle(color: Colors.white70)),
              onTap: () {
                 Get.back();
                 _blockUser(chatJid, false);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _blockUser(String userJid, bool block) async {
      bool success = await ApiService.blockUser(botJid, userJid, block);
      if (success) {
        Get.snackbar(
          block ? "Blocked" : "Unblocked",
          "User has been ${block ? 'blocked' : 'unblocked'}.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: Colors.white
        );
      } else {
        Get.snackbar("Error", "Failed to perform action");
      }
  }

  Widget _buildInfoAction(IconData icon, String label) {
    return Column(
      children: [
        IconButton(
            onPressed: () {},
            icon: Icon(icon, color: AppTheme.tealGreen, size: 28)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  void _sendMessage() async {
    String text = _msgController.text.trim();
    if (text.isEmpty) return;

    String tempMsgId = "temp_${DateTime.now().millisecondsSinceEpoch}";
    String targetChatJid =
        chatJid.contains('@') ? chatJid : "$chatJid@s.whatsapp.net";

    String replyId = replyingToMsg?['msg_id'] ?? "";
    String replyPart = replyingToMsg?['sender_jid'] ?? "";
    if (replyPart.isNotEmpty && !replyPart.contains('@')) {
      replyPart = "$replyPart@s.whatsapp.net";
    }

    Map<String, dynamic> tempMsg = {
      "msg_id": tempMsgId,
      "sender_jid": botJid,
      "text": text,
      "media_type": "",
      "is_from_me": true,
      "media_url": "",
      "status": "sending",
      "timestamp": DateTime.now().millisecondsSinceEpoch ~/ 1000, 
      "quoted_msg_id": replyId,
      "quoted_text": replyingToMsg?['text'] ?? "",
      "quoted_media_type": replyingToMsg?['media_type'] ?? "",
    };

    hub.currentChatMessages.insert(0, tempMsg);

    setState(() {
      _msgController.clear();
      replyingToMsg = null;
    });

    try {
      bool success = await ApiService.sendMessage(botJid, targetChatJid, text,
          replyToMsgId: replyId, replyParticipant: replyPart);

      int idx =
          hub.currentChatMessages.indexWhere((m) => m['msg_id'] == tempMsgId);
      if (idx != -1) {
        var msg = hub.currentChatMessages[idx];
        msg['status'] = success ? "sent" : "failed";
        hub.currentChatMessages[idx] = msg;
      }
    } catch (e) {
      int idx =
          hub.currentChatMessages.indexWhere((m) => m['msg_id'] == tempMsgId);
      if (idx != -1) {
        var msg = hub.currentChatMessages[idx];
        msg['status'] = "failed";
        hub.currentChatMessages[idx] = msg;
      }
    }
  }

  void _sendMediaMessage(String filePath, String mediaType) async {
    String tempMsgId = "temp_${DateTime.now().millisecondsSinceEpoch}";
    String targetChatJid =
        chatJid.contains('@') ? chatJid : "$chatJid@s.whatsapp.net";

    String replyId = replyingToMsg?['msg_id'] ?? "";
    String replyPart = replyingToMsg?['sender_jid'] ?? "";
    if (replyPart.isNotEmpty && !replyPart.contains('@')) {
      replyPart = "$replyPart@s.whatsapp.net";
    }

    var tempMsg = {
      "msg_id": tempMsgId,
      "sender_jid": botJid,
      "text": "",
      "media_type": mediaType,
      "is_from_me": true,
      "media_url": filePath,
      "status": "sending",
      "timestamp": DateTime.now().millisecondsSinceEpoch ~/ 1000, 
      "quoted_msg_id": replyId,
      "quoted_text": replyingToMsg?['text'] ?? "",
      "quoted_media_type": replyingToMsg?['media_type'] ?? "",
    };

    hub.currentChatMessages.insert(0, tempMsg);
    setState(() => replyingToMsg = null);

    try {
      bool success = await ApiService.uploadAndSendMedia(
          botJid, targetChatJid, filePath, mediaType,
          replyToMsgId: replyId, replyParticipant: replyPart);

      int idx =
          hub.currentChatMessages.indexWhere((m) => m['msg_id'] == tempMsgId);
      if (idx != -1) {
        var msg = hub.currentChatMessages[idx];
        msg['status'] = success ? "sent" : "failed";
        hub.currentChatMessages[idx] = msg;
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to send media");
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.any, allowMultiple: false, withData: true);
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      // Web: use bytes; Mobile: use path
      final path = file.path ?? file.name;
      _sendMediaMessage(path, "document");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        title: Row(
          children: [
            const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white)),
            const SizedBox(width: 10),
            Expanded(
                child: Text(chatName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 18))),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.videocam), onPressed: () {}),
          IconButton(icon: const Icon(Icons.call), onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showContactInfo),
        ],
      ),
      body: Container(
        color: const Color(0xFF0D0D1A),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Obx(() {
                    if (hub.isRoomLoading.value) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.tealGreen));
                    }

                    return ListView.builder(
                      controller: _scrollController, 
                      reverse: true,
                      padding: const EdgeInsets.only(
                          left: 10, right: 10, bottom: 10, top: 20),
                      itemCount: hub.currentChatMessages.length,
                      itemBuilder: (context, index) {
                        var msg = hub.currentChatMessages[index];

                        if (msg['is_divider'] == true) {
                          return Center(
                              child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 15),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 6),
                            decoration: BoxDecoration(
                                color: const Color(0xFF2E2E48),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.lightBlueAccent
                                        .withOpacity(0.5))),
                            child: const Text("↓ New Messages ↓",
                                style: TextStyle(
                                    color: Colors.lightBlueAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ));
                        }

                        // 🚀 یہاں JID کو کلین کر کے میچ کیا گیا ہے تاکہ مرجنگ پرفیکٹ ہو
                        String senderClean = (msg['sender_jid'] ?? "").toString().split('@')[0];
                        String chatClean = chatJid.split('@')[0];
                        bool isMe = senderClean != chatClean;

                        return GestureDetector(
                          onLongPress: () {
                            _showMessageOptions(context, msg, isMe);
                          },
                          child: SwipeTo(
                            onRightSwipe: (details) {
                              setState(() => replyingToMsg = msg);
                            },
                            child: MessageBubble(msg: msg, isMe: isMe),
                          ),
                        );
                      },
                    );
                  }),

                  Positioned(
                    right: 10,
                    bottom: 15,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showScrollToTop)
                          FloatingActionButton.small(
                            heroTag: 'topBtn',
                            backgroundColor:
                                const Color(0xFF1E1E2C).withOpacity(0.8),
                            onPressed: () {
                              _scrollController.animateTo(
                                _scrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOut,
                              );
                            },
                            child: const Icon(Icons.arrow_upward,
                                color: Colors.white),
                          ),
                        if (showScrollToTop && showScrollToBottom)
                          const SizedBox(height: 10),
                        if (showScrollToBottom)
                          FloatingActionButton.small(
                            heroTag: 'bottomBtn',
                            backgroundColor:
                                const Color(0xFF1E1E2C).withOpacity(0.8),
                            onPressed: () {
                              _scrollController.animateTo(
                                0.0,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOut,
                              );
                            },
                            child: const Icon(Icons.arrow_downward,
                                color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(
      BuildContext context, Map<String, dynamic> msg, bool isMe) {
    Get.bottomSheet(
      Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Wrap(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ["👍", "❤️", "😂", "😮", "😢", "🙏"]
                    .map((emoji) => GestureDetector(
                          onTap: () {
                            Get.back();
                            _sendReaction(msg['msg_id'], emoji);
                          },
                          child:
                              Text(emoji, style: const TextStyle(fontSize: 32)),
                        ))
                    .toList(),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.reply),
              title: Text('Reply',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color)),
              onTap: () {
                Get.back();
                setState(() => replyingToMsg = msg);
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text('Delete for Everyone',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color)),
                onTap: () {
                  Get.back();
                  _deleteMessage(msg['msg_id'], everyone: true);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: Text('Delete for Me',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color)),
              onTap: () {
                Get.back();
                _deleteMessage(msg['msg_id'], everyone: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendReaction(String msgId, String emoji) async {
    bool success = await ApiService.sendReaction(botJid, chatJid, msgId, emoji);

    if (success) {
      int idx = hub.currentChatMessages.indexWhere((m) => m['msg_id'] == msgId);
      if (idx != -1) {
        var msg = hub.currentChatMessages[idx];
        msg['reaction'] = emoji;
        hub.currentChatMessages[idx] = msg;
        setState(() {});
      }
    }
  }

  void _deleteMessage(String msgId, {required bool everyone}) async {
    bool success = await ApiService.deleteMessage(botJid, chatJid, msgId, everyone);

    if (success) {
      hub.currentChatMessages.removeWhere((m) => m['msg_id'] == msgId);
    }
  }

  Widget _buildInputArea() {
    return Column(
      children: [
        if (replyingToMsg != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E48),
              borderRadius: BorderRadius.circular(10),
              border: const Border(
                  left: BorderSide(color: AppTheme.tealGreen, width: 4)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // 🚀 ریپلائی میں بھی کلین نمبر یوز کیا ہے
                        (replyingToMsg!['sender_jid'] ?? "").toString().split('@')[0] == chatJid.split('@')[0]
                            ? chatName
                            : "You",
                        style: const TextStyle(
                            color: AppTheme.tealGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        replyingToMsg!['text']?.isNotEmpty == true
                            ? replyingToMsg!['text']
                            : "Media",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: () => setState(() => replyingToMsg = null),
                )
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          color: const Color(0xFF1E1E2C),
          child: Row(
            children: [
              if (!isRecording)
                IconButton(
                    icon:
                        const Icon(Icons.add, color: Colors.white54, size: 28),
                    onPressed: _pickFile),
              Expanded(
                child: isRecording
                    ? Row(
                        children: [
                          const Icon(Icons.mic, color: Colors.redAccent),
                          const SizedBox(width: 10),
                          const Text("Recording... ◀ Slide left to cancel",
                              style: TextStyle(color: Colors.white54)),
                        ],
                      )
                    : TextField(
                        controller: _msgController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: const Color(0xFF2E2E48),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              isTyping
                  ? GestureDetector(
                      onTap: _sendMessage,
                      child: const CircleAvatar(
                          backgroundColor: AppTheme.tealGreen,
                          radius: 22,
                          child:
                              Icon(Icons.send, color: Colors.white, size: 20)),
                    )
                  : GestureDetector(
                      onLongPressStart: (details) async {
                        if (await _audioRecorder.hasPermission()) {
                          setState(() {
                            isRecording = true;
                            swipeOffset = 0.0;
                          });
                          await _audioRecorder.start(const RecordConfig(),
                              path: ''); // Web: record stores in memory, returns blob URL
                        }
                      },
                      onLongPressMoveUpdate: (details) {
                        if (isRecording &&
                            details.localOffsetFromOrigin.dx < -80) {
                          _audioRecorder.stop();
                          setState(() {
                            isRecording = false;
                            swipeOffset = 0.0;
                          });
                          Get.snackbar("Cancelled", "Voice note cancelled",
                              snackPosition: SnackPosition.TOP);
                        }
                      },
                      onLongPressEnd: (details) async {
                        if (isRecording) {
                          String? path = await _audioRecorder.stop();
                          setState(() {
                            isRecording = false;
                            swipeOffset = 0.0;
                          });
                          if (path != null) _sendMediaMessage(path, "audio");
                        }
                      },
                      child: CircleAvatar(
                        backgroundColor:
                            isRecording ? Colors.redAccent : AppTheme.tealGreen,
                        radius: 22,
                        child: Icon(isRecording ? Icons.mic : Icons.mic_none,
                            color: Colors.white, size: 22),
                      ),
                    )
            ],
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------
// Message Bubble
// ----------------------------------------------------------------------
class MessageBubble extends StatefulWidget {
  final Map<String, dynamic> msg;
  final bool isMe;

  const MessageBubble({super.key, required this.msg, required this.isMe});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  bool isAudioLoading = false;
  Duration audioDuration = Duration.zero;
  Duration audioPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state.playing;
          if (state.processingState == ProcessingState.ready ||
              state.processingState == ProcessingState.completed) {
            isAudioLoading = false;
          }
          if (state.processingState == ProcessingState.completed) {
            _audioPlayer.seek(Duration.zero);
            _audioPlayer.pause();
          }
        });
      }
    });

    _audioPlayer.durationStream.listen((newDuration) {
      if (mounted && newDuration != null)
        setState(() => audioDuration = newDuration);
    });

    _audioPlayer.positionStream.listen((newPosition) {
      if (mounted) setState(() => audioPosition = newPosition);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _handleAudioPlay(String url) async {
    if (url.isEmpty) return;
    try {
      if (isPlaying) {
        await _audioPlayer.pause();
      } else {
        setState(() => isAudioLoading = true);
        if (_audioPlayer.duration == null) await _audioPlayer.setUrl(url);
        await _audioPlayer.play();
      }
    } catch (e) {
      setState(() => isAudioLoading = false);
      Get.snackbar("Error", "Cannot play audio inline.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null || timestamp.toString().isEmpty) return "";
    
    DateTime date;
    
    if (timestamp is int || timestamp is double) {
      int ts = timestamp is double ? timestamp.toInt() : timestamp as int;
      if (ts == 0) return "";
      if (ts < 10000000000) {
        ts *= 1000;
      }
      date = DateTime.fromMillisecondsSinceEpoch(ts);
    } else if (timestamp is String) {
      int? ts = int.tryParse(timestamp);
      if (ts != null) {
        if (ts == 0) return "";
        if (ts < 10000000000) {
          ts *= 1000;
        }
        date = DateTime.fromMillisecondsSinceEpoch(ts);
      } else {
        try {
          date = DateTime.parse(timestamp).toLocal();
        } catch (e) {
          return "";
        }
      }
    } else {
      return "";
    }

    int hour = date.hour;
    int minute = date.minute;
    String ampm = hour >= 12 ? 'PM' : 'AM';
    
    hour = hour % 12;
    if (hour == 0) hour = 12;
    
    String minuteStr = minute.toString().padLeft(2, '0');
    
    return "${hour.toString().padLeft(2, '0')}:$minuteStr $ampm";
  }

  String getSafeImageUrl(String originalUrl) {
    if (originalUrl.isEmpty) return "";
    String url = originalUrl.startsWith("http://")
        ? originalUrl.replaceFirst("http://", "https://")
        : originalUrl;

    if (url.startsWith('blob:') || url.startsWith('/')) {
      return url;
    }

    return "https://wsrv.nl/?url=${Uri.encodeComponent(url)}";
  }

  @override
  Widget build(BuildContext context) {
    String text = widget.msg['text'] ?? "";
    String type = widget.msg['media_type'] ?? "";
    String rawUrl = widget.msg['media_url'] ?? "";
    String status = widget.msg['status'] ?? "sent";
    String timeStr = _formatTimestamp(widget.msg['timestamp']);

    String url = rawUrl;
    if (url.startsWith("http://")) {
      url = url.replaceFirst("http://", "https://");
    }

    String safeImageUrl = getSafeImageUrl(rawUrl);
    String quotedText = widget.msg['quoted_text'] ?? "";
    String quotedType = widget.msg['quoted_media_type'] ?? "";

    if (type == "sticker") {
      return Align(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          width: 120,
          height: 120,
          child: safeImageUrl.isNotEmpty
              ? Image.network(safeImageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) =>
                      const Icon(Icons.broken_image, color: Colors.grey))
              : const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.isMe
                  ? (isDark
                      ? AppTheme.outgoingChatDark
                      : AppTheme.outgoingChatLight)
                  : (isDark
                      ? AppTheme.incomingChatDark
                      : AppTheme.incomingChatLight),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: widget.isMe
                    ? const Radius.circular(12)
                    : const Radius.circular(0),
                bottomRight: widget.isMe
                    ? const Radius.circular(0)
                    : const Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 1,
                    offset: const Offset(0, 1))
              ],
            ),
            constraints: BoxConstraints(maxWidth: Get.width * 0.75),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              alignment: WrapAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (quotedText.isNotEmpty || quotedType.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(8),
                          border: const Border(
                              left: BorderSide(color: Colors.amber, width: 4)),
                        ),
                        child: Row(
                          children: [
                            if (quotedType == "image")
                              const Icon(Icons.image,
                                  size: 16, color: Colors.white70),
                            if (quotedType == "video")
                              const Icon(Icons.videocam,
                                  size: 16, color: Colors.white70),
                            if (quotedType == "audio")
                              const Icon(Icons.mic,
                                  size: 16, color: Colors.white70),
                            if (quotedType.isNotEmpty) const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                quotedText.isNotEmpty ? quotedText : "Media",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (type == "image" || type == "video")
                      GestureDetector(
                        onTap: () {
                          if (type == "video") {
                            Get.to(() => VideoPlayerScreen(videoUrl: url));
                          } else if (type == "image") {
                            Get.to(() =>
                                FullScreenImageView(imageUrl: safeImageUrl));
                          }
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                height: 200,
                                width: double.infinity,
                                color: Colors.black26,
                                child:
                                    (type == "image" && safeImageUrl.isNotEmpty)
                                        ? Image.network(safeImageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) =>
                                                const Icon(Icons.broken_image,
                                                    color: Colors.white38,
                                                    size: 50))
                                        : Icon(
                                            type == "image"
                                                ? Icons.image
                                                : Icons.videocam,
                                            color: Colors.white38,
                                            size: 50),
                              ),
                              if (type == "video")
                                Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(
                                        color: Colors.black45,
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.play_arrow,
                                        color: Colors.white, size: 30)),
                            ],
                          ),
                        ),
                      ),
                    if (type == "audio")
                      Container(
                        margin: const EdgeInsets.only(top: 5, bottom: 5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 8),
                        decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _handleAudioPlay(url),
                              child: isAudioLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : Icon(
                                      isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 30),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SliderTheme(
                                data: SliderThemeData(
                                    thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(
                                        overlayRadius: 10)),
                                child: Slider(
                                  min: 0,
                                  max: audioDuration.inSeconds.toDouble() > 0
                                      ? audioDuration.inSeconds.toDouble()
                                      : 1.0,
                                  value: audioPosition.inSeconds
                                      .toDouble()
                                      .clamp(
                                          0.0,
                                          audioDuration.inSeconds.toDouble() > 0
                                              ? audioDuration.inSeconds
                                                  .toDouble()
                                              : 1.0),
                                  activeColor: Colors.white,
                                  inactiveColor: Colors.white38,
                                  onChanged: (value) async {
                                    final position =
                                        Duration(seconds: value.toInt());
                                    await _audioPlayer.seek(position);
                                  },
                                ),
                              ),
                            ),
                            Text(_formatDuration(audioPosition),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    if (text.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                            top: (type.isNotEmpty || quotedText.isNotEmpty)
                                ? 8.0
                                : 0,
                            left: 4,
                            right: 10,
                            bottom: 4),
                        child: MarkdownBody(
                          data: text,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                                color: isDark
                                    ? AppTheme.textPrimaryDark
                                    : AppTheme.textPrimaryLight,
                                fontSize: 15),
                            code: const TextStyle(
                                backgroundColor: Colors.black45,
                                color: Colors.greenAccent,
                                fontFamily: 'monospace',
                                fontSize: 14),
                          ),
                        ),
                      ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                         timeStr,
                        style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.black54),
                      ),
                      if (widget.isMe) ...[
                        const SizedBox(width: 4),
                        if (status == "sending")
                          const Icon(Icons.access_time,
                              size: 14, color: Colors.grey)
                        else if (status == "sent")
                          const Icon(Icons.check, size: 15, color: Colors.grey)
                        else if (status == "delivered")
                          const Icon(Icons.done_all,
                              size: 15, color: Colors.grey)
                        else if (status == "read")
                          const Icon(Icons.done_all,
                              size: 15, color: AppTheme.blueTick)
                        else if (status == "failed")
                          const Icon(Icons.error_outline,
                              size: 15, color: Colors.red),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (widget.msg['reaction'] != null &&
              widget.msg['reaction'].toString().isNotEmpty)
            Positioned(
              bottom: -8,
              right: widget.isMe ? 15 : null,
              left: widget.isMe ? null : 15,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.incomingChatDark
                      : AppTheme.incomingChatLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark
                          ? AppTheme.backgroundDark
                          : AppTheme.backgroundLight,
                      width: 2),
                ),
                child: Text(widget.msg['reaction'],
                    style: const TextStyle(fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }
}

class FullScreenImageView extends StatelessWidget {
  final String imageUrl;
  const FullScreenImageView({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          (loadingProgress.expectedTotalBytes ?? 1)
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: Colors.white54, size: 80),
                SizedBox(height: 10),
                Text("Failed to load image",
                    style: TextStyle(color: Colors.white54))
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    VideoPlayer(_controller),
                    VideoProgressIndicator(_controller, allowScrubbing: true),
                    Center(
                      child: IconButton(
                        icon: Icon(
                            _controller.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 50),
                        onPressed: () {
                          setState(() {
                            _controller.value.isPlaying
                                ? _controller.pause()
                                : _controller.play();
                          });
                        },
                      ),
                    )
                  ],
                ),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
