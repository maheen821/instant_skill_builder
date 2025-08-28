import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'login.dart';
import 'register.dart';
import 'user_home.dart';
import 'video_widget.dart'; // ✅ For video test screen if needed
import 'json_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JsonStorageService().init(); // Optional if you use local JSON storage
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Instant Skill Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => UserHome(),
        '/video': (context) => const VideoScreen(), // Optional test
      },
    );
  }
}

// ✅ Optional test video screen
class VideoScreen extends StatelessWidget {
  const VideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Video Player")),
      body: const Center(
        child: VideoWidget(
          // YouTube test
          videoUrl: 'https://www.youtube.com/watch?v=fq4N0hgOWzU',

          // MP4 test
          // videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
        ),
      ),
    );
  }
}
