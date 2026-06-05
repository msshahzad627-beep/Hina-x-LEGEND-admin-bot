import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'chat_room_screen.dart'; // To reuse safe image logic if needed

class StoryViewScreen extends StatefulWidget {
  final List<dynamic> statuses;
  final String userName;
  final String userDp;

  const StoryViewScreen(
      {super.key,
      required this.statuses,
      required this.userName,
      required this.userDp});

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  int _currentIndex = 0;
  double _progress = 0.0;
  Timer? _timer;
  final int _duration = 50; // Total steps for 5 seconds (50 * 100ms)
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _progress = 0.0;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isPaused) return;
      setState(() {
        _progress += 1 / _duration;
        if (_progress >= 1.0) {
          _nextStatus();
        }
      });
    });
  }

  void _nextStatus() {
    if (_currentIndex < widget.statuses.length - 1) {
      setState(() {
        _currentIndex++;
        _startTimer();
      });
    } else {
      Get.back();
    }
  }

  void _previousStatus() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _startTimer();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getSafeImageUrl(String originalUrl) {
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
    var status = widget.statuses[_currentIndex];
    String text = status['message_text'] ?? "";
    String type = status['media_type'] ?? "";
    String url = _getSafeImageUrl(status['media_url'] ?? "");

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTapDown: (details) {
            double screenWidth = MediaQuery.of(context).size.width;
            if (details.globalPosition.dx < screenWidth / 3) {
              _previousStatus();
            } else {
              _nextStatus();
            }
          },
          onLongPressStart: (_) => setState(() => _isPaused = true),
          onLongPressEnd: (_) => setState(() => _isPaused = false),
          child: Stack(
            children: [
              // Media / Text content
              Center(
                child: type == 'image' && url.isNotEmpty
                    ? Image.network(url, fit: BoxFit.contain)
                    : type == 'video'
                        ? const Icon(Icons.videocam,
                            color: Colors.white,
                            size: 80) // Video logic can be added later
                        : Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(text,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 28),
                                textAlign: TextAlign.center),
                          ),
              ),

              // Overlay Elements
              Column(
                children: [
                  // Progress Bars
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    child: Row(
                      children: List.generate(widget.statuses.length, (index) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 3,
                            decoration: BoxDecoration(
                              color: index < _currentIndex
                                  ? Colors.white
                                  : index == _currentIndex
                                      ? Colors.white.withOpacity(0.8)
                                      : Colors.white38,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            alignment: Alignment.centerLeft,
                            child: index == _currentIndex
                                ? FractionallySizedBox(
                                    widthFactor: _progress,
                                    child: Container(
                                      color: Colors.white,
                                      height: 3,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        );
                      }),
                    ),
                  ),

                  // User Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey,
                          backgroundImage: widget.userDp.isNotEmpty
                              ? NetworkImage(widget.userDp)
                              : null,
                          child: widget.userDp.isEmpty
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.userName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const Text("Just now",
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Get.back()),
                      ],
                    ),
                  ),
                ],
              ),

              // Reply Box at Bottom
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white38),
                        ),
                        child: const Text("Reply",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
