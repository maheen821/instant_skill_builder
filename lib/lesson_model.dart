import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class Lesson {
  String title;
  String description;
  String videoUrl;
  String imageUrl;
  bool completed;
  bool bookmarked;
  List<QuizItem> quiz; // <-- quiz field

  Lesson({
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.imageUrl,
    this.completed = false,
    this.bookmarked = false,
    required this.quiz,
  });

  /// ✅ Getter: YouTube ID extract karega automatically
  String get youtubeId {
    return YoutubePlayer.convertUrlToId(videoUrl) ?? "";
  }

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      completed: json['completed'] ?? false,
      bookmarked: json['bookmarked'] ?? false,
      quiz: (json['quiz'] as List<dynamic>? ?? [])
          .map((q) => QuizItem.fromJson(q))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'imageUrl': imageUrl,
      'completed': completed,
      'bookmarked': bookmarked,
      'quiz': quiz.map((q) => q.toJson()).toList(),
    };
  }
}

class QuizItem {
  String question;
  List<String> options;
  String correctAnswer;

  QuizItem({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });

  factory QuizItem.fromJson(Map<String, dynamic> json) {
    return QuizItem(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
    };
  }
}
