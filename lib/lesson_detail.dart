import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'lesson_model.dart';
import 'badge_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as yt_flutter;
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as yt_iframe;

class LessonDetail extends StatefulWidget {
  final Lesson lesson;
  final int index;
  final VoidCallback? onComplete;

  LessonDetail({required this.lesson, required this.index, this.onComplete});

  @override
  _LessonDetailState createState() => _LessonDetailState();
}

class _LessonDetailState extends State<LessonDetail> {
  yt_flutter.YoutubePlayerController? _ytMobileController;
  yt_iframe.YoutubePlayerController? _ytWebController;

  bool _quizEnabled = false;
  bool _quizCompleted = false;
  int _currentMiniTask = 0;
  int _currentQuestion = 0;
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    _loadLessonProgress();
    _initYoutubeController();
  }

  Future<void> _loadLessonProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final key = widget.lesson.title;

    setState(() {
      _quizCompleted = prefs.getBool('${key}_completed') ?? false;
      _quizEnabled = prefs.getBool('${key}_quiz_enabled') ?? false;
      _currentMiniTask = prefs.getInt('${key}_mini_task') ?? 0;
      _currentQuestion = prefs.getInt('${key}_current_question') ?? 0;
    });
  }

  Future<void> _saveLessonProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final key = widget.lesson.title;

    await prefs.setBool('${key}_completed', _quizCompleted);
    await prefs.setBool('${key}_quiz_enabled', _quizEnabled);
    await prefs.setInt('${key}_mini_task', _currentMiniTask);
    await prefs.setInt('${key}_current_question', _currentQuestion);
  }

  void _initYoutubeController() {
    if (kIsWeb) {
      _ytWebController = yt_iframe.YoutubePlayerController(
        params: const yt_iframe.YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
        ),
      );
      _ytWebController!.listen((event) {
        if (event.playerState == yt_iframe.PlayerState.ended && !_quizEnabled) {
          setState(() {
            _quizEnabled = true;
            _saveLessonProgress();
          });
        }
      });
      _ytWebController!.loadVideoById(videoId: widget.lesson.videoUrl);
    } else {
      _ytMobileController = yt_flutter.YoutubePlayerController(
        initialVideoId: widget.lesson.videoUrl,
        flags: const yt_flutter.YoutubePlayerFlags(autoPlay: false, mute: false),
      )..addListener(() {
        if (_ytMobileController!.value.playerState == yt_flutter.PlayerState.ended &&
            !_quizEnabled) {
          setState(() {
            _quizEnabled = true;
            _saveLessonProgress();
          });
        }
      });
    }
  }

  void _startQuiz() {
    _showQuestion();
  }

  void _showQuestion() {
    if (_currentQuestion >= widget.lesson.quiz.length) {
      _currentMiniTask = 0;
      _startMiniTask();
      return;
    }

    final question = widget.lesson.quiz[_currentQuestion];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Q${_currentQuestion + 1}. ${question.question}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: question.options.map((option) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  _selectedOption == option ? Colors.pinkAccent : Colors.white,
                  foregroundColor:
                  _selectedOption == option ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  _selectedOption = option;
                  Navigator.pop(context);
                  _checkAnswer();
                },
                child: Text(option),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _checkAnswer() {
    final question = widget.lesson.quiz[_currentQuestion];
    final isCorrect = _selectedOption == question.correctAnswer;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(isCorrect ? "✅ Correct!" : "❌ Wrong Answer"),
      backgroundColor: isCorrect ? Colors.green : Colors.red,
      duration: Duration(seconds: 1),
    ));

    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _currentQuestion++;
        _selectedOption = null;
        _saveLessonProgress();
      });
      _showQuestion();
    });
  }

  void _startMiniTask() {
    if (_currentMiniTask >= 3) {
      setState(() {
        _quizCompleted = true;
        _saveLessonProgress();
      });

      if (widget.onComplete != null) widget.onComplete!();

      showDialog(
        context: context,
        builder: (_) => BadgePopup(
          title: "🎉 Congratulations!",
          message:
          "You completed the quiz & all mini tasks!\nBadge Unlocked: Flutter Beginner 🏅",
        ),
      );
      return;
    }

    final controller = TextEditingController();
    String hint = "";
    switch (_currentMiniTask) {
      case 0:
        hint = "Draw a quick diagram or describe visually what you learned.";
        break;
      case 1:
        hint = "Solve this challenge: apply one concept from the lesson in real life.";
        break;
      case 2:
        hint = "Write a short story or scenario using lesson concepts creatively.";
        break;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Mini Task ${_currentMiniTask + 1}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(hint, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                    Text("Please enter your response before submitting."),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 1),
                  ));
                  return;
                }

                // Save mini task progress
                setState(() {
                  _currentMiniTask++;
                });
                await _saveLessonProgress();

                Navigator.of(context).pop(); // close current dialog

                // Small delay to ensure dialog closes before opening next
                Future.delayed(Duration(milliseconds: 200), () {
                  _startMiniTask(); // open next mini task automatically
                });
              },
              child: Text("Submit"),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ytMobileController?.dispose();
    _ytWebController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoPlayer = kIsWeb
        ? AspectRatio(
        aspectRatio: 16 / 9,
        child: yt_iframe.YoutubePlayer(controller: _ytWebController!))
        : yt_flutter.YoutubePlayer(
      controller: _ytMobileController!,
      showVideoProgressIndicator: true,
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
          title: Text(widget.lesson.title),
          backgroundColor: Colors.pink,
          centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            videoPlayer,
            SizedBox(height: 20),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
                ],
              ),
              child: Text(widget.lesson.description,
                  style:
                  TextStyle(fontSize: 16, color: Colors.black87, height: 1.5)),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.quiz),
              label: Text(_quizCompleted
                  ? "Completed ✅"
                  : _quizEnabled
                  ? "Take Quiz & Mini Tasks"
                  : "Watch Full Video to Unlock Quiz"),
              onPressed: (!_quizEnabled || _quizCompleted) ? null : _startQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
