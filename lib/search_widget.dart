import 'package:flutter/material.dart';
import 'lesson_model.dart';
import 'lesson_detail.dart';

class LessonSearch extends SearchDelegate {
  final List<Lesson> lessons;
  LessonSearch(this.lessons);

  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final results = lessons.where((lesson) => lesson.title.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final lesson = results[index];
        return ListTile(
          title: Text(lesson.title),
          subtitle: Text(lesson.description),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonDetail(lesson: lesson, index: lessons.indexOf(lesson)))),
        );
      },
    );
  }
}
