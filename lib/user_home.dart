import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'user_model.dart';
import 'lesson_model.dart';
import 'lesson_detail.dart';
import 'login.dart'; // ✅ For logout navigation

class UserHome extends StatefulWidget {
  final User? user;
  final String? token;

  UserHome({this.user, this.token});
  @override
  _UserHomeState createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  List<Lesson> allLessons = [];
  List<Lesson> filteredLessons = [];
  List<String> categories = ["All", "UI", "State", "Navigation", "Animations"];
  String selectedCategory = "All";

  bool isLoading = true;
  bool hasError = false;
  int _selectedIndex = 0;
  bool _isDarkTheme = false;
  bool _notificationsEnabled = true;
  final TextEditingController searchController = TextEditingController();

  String _userName = "Flutter Learner";

  static const String remoteJson =
      'https://raw.githubusercontent.com/maheen821/flutter-json-data/main/lessons.json';

  @override
  void initState() {
    super.initState();
    _loadLessons();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Flutter Learner';
    });
  }

  Future<void> _saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    setState(() => _userName = name);
  }

  Future<void> _loadLessons() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      final res = await http.get(Uri.parse(remoteJson));
      if (res.statusCode == 200) {
        final jsonList = jsonDecode(res.body) as List<dynamic>;
        final lessons = jsonList.map((e) => Lesson.fromJson(e)).toList();
        setState(() {
          allLessons = lessons;
          filteredLessons = List.from(allLessons);
          isLoading = false;
        });
        await _loadCompletionStatus();
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> _loadCompletionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> completedList = prefs.getStringList('completedLessons') ?? [];
    setState(() {
      for (var lesson in allLessons) {
        lesson.completed = completedList.contains(lesson.title);
      }
    });
  }

  void _onNavTap(int index) => setState(() => _selectedIndex = index);

  void _toggleTheme(bool val) => setState(() => _isDarkTheme = val);

  void _filterLessons(String query) {
    final q = query.trim().toLowerCase();
    final filtered = allLessons.where((l) {
      final t = l.title.toLowerCase();
      final d = l.description.toLowerCase();
      return (t.contains(q) || d.contains(q)) &&
          (selectedCategory == "All" ||
              l.title.toLowerCase().contains(selectedCategory.toLowerCase()));
    }).toList();
    setState(() => filteredLessons = filtered);
  }

  void _filterByCategory(String category) {
    setState(() {
      selectedCategory = category;
      _filterLessons(searchController.text);
    });
  }

  void _toggleBookmark(Lesson lesson) {
    setState(() => lesson.bookmarked = !lesson.bookmarked);
  }

  void _clearBookmarks() {
    setState(() {
      for (var l in allLessons) {
        l.bookmarked = false;
      }
    });
  }

  Future<void> _markLessonComplete(Lesson lesson) async {
    setState(() => lesson.completed = true);
    final prefs = await SharedPreferences.getInstance();
    List<String> completedList = prefs.getStringList('completedLessons') ?? [];
    if (!completedList.contains(lesson.title)) {
      completedList.add(lesson.title);
      await prefs.setStringList('completedLessons', completedList);
    }
    _showBadgePopup();
  }

  void _showBadgePopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("🎉 Congratulations!"),
        content: const Text("Lesson completed! Badge Unlocked: Flutter Beginner 🏅"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"))
        ],
      ),
    );
  }

  // ✅ LOGOUT
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Instant Skill Builder",
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorSchemeSeed: Colors.pinkAccent,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: Colors.pinkAccent,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Instant Skill Builder"),
          elevation: 4,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pinkAccent, Colors.deepPurpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onNavTap,
          selectedItemColor: Colors.pinkAccent,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: "Bookmarks"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
          ],
        ),
      ),
    );
  }

  // ---------------- BODY ----------------
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return RefreshIndicator(
          onRefresh: _loadLessons,
          child: ListView(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildSearchBar(),
              _buildCategoryChips(),
              const SizedBox(height: 12),
              if (hasError)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _errorBanner(),
                ),
              _buildLessonList(),
            ],
          ),
        );
      case 1:
        final bookmarked = allLessons.where((l) => l.bookmarked).toList();
        return bookmarked.isEmpty
            ? _buildEmptyState("No bookmarks yet")
            : ListView.builder(
          itemCount: bookmarked.length,
          itemBuilder: (context, i) {
            final l = bookmarked[i];
            return ListTile(
              leading: const Icon(Icons.bookmark, color: Colors.pinkAccent),
              title: Text(l.title),
              subtitle: Text(l.description),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LessonDetail(
                        lesson: l,
                        index: i,
                        onComplete: () => _markLessonComplete(l)),
                  ),
                );
              },
            );
          },
        );
      case 2:
        return _buildProfile();
      case 3:
        return _buildSettings();
      default:
        return _buildEmptyState();
    }
  }

  Widget _buildProfile() {
    final completed = allLessons.where((l) => l.completed).length;
    final bookmarks = allLessons.where((l) => l.bookmarked).length;
    final total = allLessons.length;

    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final prefs = snapshot.data!;
        final userJson = prefs.getString('user');

        if (userJson == null || userJson.isEmpty) {
          return const Center(child: Text("No user data found."));
        }

        final user = User.fromJson(jsonDecode(userJson));

        final userName = user.username ?? "No Name";
        final userEmail = user.email ?? "No Email";
        final profileImageBase64 = user.profileImage ?? "";

        // ✅ Logout function
        Future<void> _logout() async {
          await prefs.remove('token');
          await prefs.remove('isLoggedIn');
          // ✅ Optional: keep user info for next login
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logged out successfully')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => LoginPage()),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 55,
                backgroundColor: Colors.pinkAccent.shade100,
                backgroundImage: profileImageBase64.isNotEmpty
                    ? MemoryImage(base64Decode(profileImageBase64))
                    : null,
                child: profileImageBase64.isEmpty
                    ? const Icon(Icons.person, size: 55, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                userName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                userEmail,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Stats
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text("Progress",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : completed / total,
                          minHeight: 12,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                              Colors.pinkAccent.shade200),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("Completed: $completed / $total"),
                      Text("Bookmarked: $bookmarks"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Buttons
              ElevatedButton.icon(
                onPressed: () async {
                  final nameController = TextEditingController(text: userName);
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: const Text("Edit Name"),
                      content: TextField(controller: nameController),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel")),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pinkAccent),
                          onPressed: () async {
                            user.username = nameController.text;
                            await prefs.setString('user', jsonEncode(user.toJson()));
                            Navigator.pop(context);
                            setState(() {});
                          },
                          child: const Text("Save"),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text("Edit Name"),
              ),
              const SizedBox(height: 12),

              // ✅ Logout button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
              ),
            ],
          ),
        );
      },
    );
  }


  // ---------------- SETTINGS ----------------
  Widget _buildSettings() {
    return ListView(
      children: [
        SwitchListTile(
          title: const Text("Dark Theme"),
          value: _isDarkTheme,
          onChanged: _toggleTheme,
          secondary: const Icon(Icons.dark_mode),
        ),
        SwitchListTile(
          title: const Text("Enable Notifications"),
          value: _notificationsEnabled,
          onChanged: (val) => setState(() => _notificationsEnabled = val),
          secondary: const Icon(Icons.notifications_active),
        ),
        ListTile(
          leading: const Icon(Icons.delete, color: Colors.red),
          title: const Text("Clear Bookmarks"),
          onTap: _clearBookmarks,
        ),
        ListTile(
          leading: const Icon(Icons.restart_alt, color: Colors.red),
          title: const Text("Clear Progress"),
          onTap: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('completedLessons');
            setState(() {
              for (var l in allLessons) {
                l.completed = false;
              }
            });
          },
        ),
      ],
    );
  }
  // ---- HEADER ----
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: NetworkImage(
              'https://images.unsplash.com/photo-1555066931-4365d14bab8c?auto=format&fit=crop&w=1200&q=80'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black45,
        ),
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: const Text(
          "Level up your skills 🚀",
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ---- SEARCH ----
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: searchController,
        onChanged: _filterLessons,
        decoration: InputDecoration(
          hintText: 'Search lessons…',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.pink.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ---- CATEGORY FILTER ----
  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: categories.map((cat) {
          final isSelected = cat == selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (_) => _filterByCategory(cat),
              selectedColor: Colors.pinkAccent,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---- LESSON LIST ----
  Widget _buildLessonList() {
    if (filteredLessons.isEmpty) {
      return _buildEmptyState("No lessons found");
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredLessons.length,
      itemBuilder: (context, index) {
        final lesson = filteredLessons[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LessonDetail(
                      lesson: lesson,
                      index: index,
                      onComplete: () => _markLessonComplete(lesson)),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                      child: CachedNetworkImage(
                        imageUrl: lesson.imageUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image, size: 50),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: IconButton(
                        icon: Icon(
                          lesson.bookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: Colors.white,
                        ),
                        onPressed: () => _toggleBookmark(lesson),
                      ),
                    ),
                    if (lesson.completed)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Completed",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    lesson.title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                    lesson.description,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---- EMPTY / ERROR ----
  Widget _buildEmptyState([String message = "No lessons available"]) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message,
            style: const TextStyle(color: Colors.grey, fontSize: 16)),
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.orange),
          const SizedBox(width: 8),
          const Expanded(child: Text("Failed to load data from server.")),
          TextButton(onPressed: _loadLessons, child: const Text("Retry")),
        ],
      ),
    );
  }
  }
