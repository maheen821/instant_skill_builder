import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'lesson_model.dart';
import 'dart:html' as html;

class JsonStorageService {
  static final JsonStorageService _instance = JsonStorageService._internal();
  factory JsonStorageService() => _instance;
  JsonStorageService._internal();

  late File jsonFile;
  List<Lesson> lessons = [];

  Future<void> init() async {
    if (kIsWeb) {
      String? data = html.window.localStorage['lessons'];
      if (data != null && data.isNotEmpty) {
        List jsonList = jsonDecode(data);
        lessons = jsonList.map((e) => Lesson.fromJson(e)).toList();
      } else {
        lessons = [];
        await _saveToStorage();
      }
    } else {
      final dir = await getApplicationDocumentsDirectory();
      jsonFile = File('${dir.path}/lessons.json');

      if (await jsonFile.exists()) {
        String data = await jsonFile.readAsString();
        if (data.isNotEmpty) {
          List jsonList = jsonDecode(data);
          lessons = jsonList.map((e) => Lesson.fromJson(e)).toList();
        } else {
          lessons = [];
        }
      } else {
        await jsonFile.create();
        await jsonFile.writeAsString('[]');
        lessons = [];
      }
    }
  }

  Future<void> addLesson(Lesson lesson) async {
    lessons.add(lesson);
    await _saveToStorage();
  }

  Future<void> updateLesson(Lesson lesson, int index) async {
    if (index >= 0 && index < lessons.length) {
      lessons[index] = lesson;
      await _saveToStorage();
    }
  }

  Future<void> deleteLesson(int index) async {
    if (index >= 0 && index < lessons.length) {
      lessons.removeAt(index);
      await _saveToStorage();
    }
  }

  Future<void> _saveToStorage() async {
    List<Map<String, dynamic>> jsonList = lessons.map((e) => e.toJson()).toList();
    String jsonData = jsonEncode(jsonList);

    if (kIsWeb) {
      html.window.localStorage['lessons'] = jsonData;
    } else {
      await jsonFile.writeAsString(jsonData);
    }
  }
}
