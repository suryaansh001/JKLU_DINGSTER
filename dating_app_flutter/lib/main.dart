import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert' show utf8, base64Url;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:web_socket_channel/io.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(DatingApp());
}

class AppColorScheme {
  final LinearGradient backgroundGradient;
  final Color buttonBackground;
  final Color buttonForeground;
  final Color textColor;

  AppColorScheme({
    required this.backgroundGradient,
    required this.buttonBackground,
    required this.buttonForeground,
    required this.textColor,
  });
}

List<AppColorScheme> colorSchemes = [
  AppColorScheme(
    backgroundGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.pink, Colors.yellow, Colors.green, Colors.blue, Colors.purple],
    ),
    buttonBackground: Colors.redAccent[700]!,
    buttonForeground: Colors.amber,
    textColor: Colors.white,
  ),
  AppColorScheme(
    backgroundGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.orange, Colors.red, Colors.purple, Colors.teal],
    ),
    buttonBackground: Colors.teal,
    buttonForeground: Colors.orange,
    textColor: Colors.white,
  ),
  AppColorScheme(
    backgroundGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.cyan, Colors.lime, Colors.pinkAccent, Colors.indigo],
    ),
    buttonBackground: Colors.indigo,
    buttonForeground: Colors.lime,
    textColor: Colors.white,
  ),
];

class DatingApp extends StatelessWidget {
  const DatingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primarySwatch: Colors.pink,
        textTheme: TextTheme(
          bodyLarge: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
          headlineSmall: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
          headlineLarge: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.yellow),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late AppColorScheme currentScheme;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    currentScheme = colorSchemes[Random().nextInt(colorSchemes.length)];
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: currentScheme.backgroundGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  'assets/logo.png', // Replace with your logo path
                  width: 200,
                  height: 200,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Let others ring your bell(s)',
                style: TextStyle(
                  fontSize: 20,
                  color: currentScheme.textColor.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen(colorScheme: currentScheme))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentScheme.buttonBackground,
                      foregroundColor: currentScheme.buttonForeground,
                    ),
                    child: const Text('Login'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen(colorScheme: currentScheme))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentScheme.buttonBackground,
                      foregroundColor: currentScheme.buttonForeground,
                    ),
                    child: const Text('Register'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  final AppColorScheme colorScheme;

  const RegisterScreen({super.key, required this.colorScheme});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _favoriteFoodController = TextEditingController();
  final TextEditingController _twoTruthsController = TextEditingController();
  final TextEditingController _dreamVacationController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _passwordController.text,
          'favorite_food': _favoriteFoodController.text,
          'two_truths_and_a_lie': _twoTruthsController.text,
          'dream_vacation': _dreamVacationController.text,
        }),
      );
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please log in.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen(colorScheme: widget.colorScheme)),
        );
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Registration failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: widget.colorScheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: widget.colorScheme.backgroundGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Join Dinger',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: widget.colorScheme.textColor),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: widget.colorScheme.textColor.withOpacity(0.7)),
                    filled: true,
                    fillColor: widget.colorScheme.buttonForeground.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: widget.colorScheme.buttonBackground),
                    ),
                  ),
                  style: TextStyle(color: widget.colorScheme.textColor),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: widget.colorScheme.textColor.withOpacity(0.7)),
                    filled: true,
                    fillColor: widget.colorScheme.buttonForeground.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: widget.colorScheme.buttonBackground),
                    ),
                  ),
                  style: TextStyle(color: widget.colorScheme.textColor),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _favoriteFoodController,
                  decoration: InputDecoration(
                    labelText: 'Favorite Food',
                    labelStyle: TextStyle(color: widget.colorScheme.textColor.withOpacity(0.7)),
                    filled: true,
                    fillColor: widget.colorScheme.buttonForeground.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: widget.colorScheme.buttonBackground),
                    ),
                  ),
                  style: TextStyle(color: widget.colorScheme.textColor),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _twoTruthsController,
                  decoration: InputDecoration(
                    labelText: 'Two Truths and a Lie',
                    labelStyle: TextStyle(color: widget.colorScheme.textColor.withOpacity(0.7)),
                    filled: true,
                    fillColor: widget.colorScheme.buttonForeground.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: widget.colorScheme.buttonBackground),
                    ),
                  ),
                  style: TextStyle(color: widget.colorScheme.textColor),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _dreamVacationController,
                  decoration: InputDecoration(
                    labelText: 'Dream Vacation',
                    labelStyle: TextStyle(color: widget.colorScheme.textColor.withOpacity(0.7)),
                    filled: true,
                    fillColor: widget.colorScheme.buttonForeground.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: widget.colorScheme.buttonBackground),
                    ),
                  ),
                  style: TextStyle(color: widget.colorScheme.textColor),
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? CircularProgressIndicator(color: widget.colorScheme.buttonForeground)
                    : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.colorScheme.buttonBackground,
                          foregroundColor: widget.colorScheme.buttonForeground,
                        ),
                        child: const Text('Register'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final AppColorScheme colorScheme;

  const LoginScreen({super.key, required this.colorScheme});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _token;
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      print('Login attempt with username: ${_usernameController.text}');
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/token/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
      );
      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Token received: ${data['access']}');
        setState(() => _token = data['access']);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(token: _token!, colorScheme: widget.colorScheme)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${response.statusCode} - ${response.body}')),
        );
      }
    } catch (e) {
      print('Login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: widget.colorScheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: widget.colorScheme.backgroundGradient),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome to Dinger',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: widget.colorScheme.textColor),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: widget.colorScheme.textColor.withOpacity(0.7)),
                    filled: true,
                    fillColor: widget.colorScheme.buttonForeground.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: widget.colorScheme.buttonBackground),
                    ),
                  ),
                  style: TextStyle(color: widget.colorScheme.textColor),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: widget.colorScheme.textColor.withOpacity(0.7)),
                    filled: true,
                    fillColor: widget.colorScheme.buttonForeground.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: widget.colorScheme.buttonBackground),
                    ),
                  ),
                  style: TextStyle(color: widget.colorScheme.textColor),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? CircularProgressIndicator(color: widget.colorScheme.buttonForeground)
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.colorScheme.buttonBackground,
                          foregroundColor: widget.colorScheme.buttonForeground,
                        ),
                        child: const Text('Login'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String token;
  final AppColorScheme colorScheme;

  const HomeScreen({super.key, required this.token, required this.colorScheme});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<dynamic> _profiles = [];
  List<dynamic> _likedProfiles = [];
  List<dynamic> _matches = [];
  final CardSwiperController _swipeController = CardSwiperController();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _favoriteFoodController = TextEditingController();
  final TextEditingController _twoTruthsController = TextEditingController();
  final TextEditingController _dreamVacationController = TextEditingController();
  String _sortOption = 'Default';
  String _filterKeyword = '';
  late AppColorScheme currentScheme;

  // Undo feature
  CardSwiperDirection? _lastSwipeDirection;
  dynamic _lastSwipedProfile;
  bool _canUndo = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    currentScheme = widget.colorScheme;
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    print('HomeScreen initialized with token: ${widget.token}');
    _cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    _cameraController!.initialize().then((_) => setState(() {})).catchError((e) {
      print('Camera init error: $e');
    });
    _fetchProfiles();
    _fetchLikedProfiles();
    _fetchMatches();
    _loadProfile();
  }

  Future<void> _fetchProfiles() async {
    try {
      print('Fetching profiles with token: ${widget.token}');
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/profiles/'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      print('Fetch profiles status: ${response.statusCode}');
      print('Fetch profiles body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        List<dynamic> profiles = data['profiles'] as List<dynamic>? ?? [];
        
        if (_sortOption == 'Alphabetical') {
          profiles.sort((a, b) => (a['username'] as String).compareTo(b['username'] as String));
        }
        
        if (_filterKeyword.isNotEmpty) {
          profiles = profiles.where((profile) => (profile['bio'] as String?)?.toLowerCase().contains(_filterKeyword.toLowerCase()) ?? false).toList();
        }

        setState(() {
          _profiles = profiles;
          print('Profiles set: $_profiles');
        });
      } else {
        print('Fetch profiles failed with status: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch profiles: ${response.statusCode} - ${response.body}')),
        );
      }
    } catch (e) {
      print('Fetch profiles error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fetch error: $e')),
      );
    }
  }

  Future<void> _fetchLikedProfiles() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/liked/'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _likedProfiles = jsonDecode(response.body);
          print('Liked profiles set: $_likedProfiles');
        });
      }
    } catch (e) {
      print('Fetch liked profiles error: $e');
    }
  }

  Future<void> _fetchMatches() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/matches/'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _matches = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print('Fetch matches error: $e');
    }
  }

  Future<void> _loadProfile() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/profile/'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _bioController.text = data['bio'] ?? '';
          _favoriteFoodController.text = data['favorite_food'] ?? '';
          _twoTruthsController.text = data['two_truths_and_a_lie'] ?? '';
          _dreamVacationController.text = data['dream_vacation'] ?? '';
        });
      }
    } catch (e) {
      print('Load profile error: $e');
    }
  }

  Future<void> _updateProfile() async {
    try {
      print('Updating profile with bio: ${_bioController.text}, favorite_food: ${_favoriteFoodController.text}');
      final response = await http.patch(
        Uri.parse('http://localhost:8000/api/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'bio': _bioController.text,
          'favorite_food': _favoriteFoodController.text,
          'two_truths_and_a_lie': _twoTruthsController.text,
          'dream_vacation': _dreamVacationController.text,
        }),
      );
      print('Update profile status: ${response.statusCode}');
      print('Update profile body: ${response.body}');
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      } else {
        print('Update profile failed with status: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${response.statusCode} - ${response.body}')),
        );
      }
    } catch (e) {
      print('Update profile error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update error: $e')),
      );
    }
  }

  Future<void> _likeProfile(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/like/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'liked_user_id': userId}),
      );
      print('Like response: ${response.body}');
      if (response.statusCode == 201) {
        final message = jsonDecode(response.body)['message'];
        if (message == 'Match created!') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('It’s a match!')),
          );
          _fetchMatches();
        }
        _fetchLikedProfiles();
      }
    } catch (e) {
      print('Like error: $e');
    }
  }

  Future<void> _undoLike(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:8000/api/like/$userId/'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (response.statusCode == 204) {
        print('Undo like successful');
        _fetchLikedProfiles();
      } else {
        print('Undo like failed: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to undo like: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Undo like error: $e');
    }
  }

  Future<void> _recordAndUploadVideo() async {
    try {
      if (!_cameraController!.value.isInitialized) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera not initialized')),
        );
        return;
      }
      await _cameraController!.startVideoRecording();
      await Future.delayed(const Duration(seconds: 5));
      final video = await _cameraController!.stopVideoRecording();
      final videoBytes = await video.readAsBytes();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:8000/api/upload-video/'),
      );
      request.headers['Authorization'] = 'Bearer ${widget.token}';
      request.files.add(http.MultipartFile.fromBytes('video', videoBytes, filename: 'video.mp4'));
      final response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video uploaded successfully')),
        );
        _fetchProfiles();
      }
    } catch (e) {
      print('Video upload error: $e');
    }
  }

  Future<void> _uploadImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images == null || images.isEmpty) return;
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:8000/api/upload-images/'),
      );
      request.headers['Authorization'] = 'Bearer ${widget.token}';
      for (var image in images) {
        final bytes = await image.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('images', bytes, filename: image.name));
      }
      final response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Images uploaded successfully')),
        );
        _fetchProfiles();
      }
    } catch (e) {
      print('Image upload error: $e');
    }
  }

  Future<void> _uploadPost() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:8000/api/upload-post/'),
      );
      request.headers['Authorization'] = 'Bearer ${widget.token}';
      final bytes = await image.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: image.name));
      request.fields['caption'] = _captionController.text;
      final response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post uploaded successfully')),
        );
        _captionController.clear();
        _fetchProfiles();
      }
    } catch (e) {
      print('Post upload error: $e');
    }
  }

  void _showHeartEmojis(BuildContext context) {
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Center(
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(seconds: 2),
          curve: Curves.easeOut,
          onEnd: () => overlayEntry.remove(),
          child: const Text(
            '❤️❤️❤️',
            style: TextStyle(fontSize: 50),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () => overlayEntry.remove());
  }

  void _showSwipeEmoji(CardSwiperDirection direction) {
    String emoji = direction == CardSwiperDirection.left ? '👎' : direction == CardSwiperDirection.top ? '⬆️' : '⬇️';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(child: Text(emoji, style: const TextStyle(fontSize: 40))),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
      ),
    );
  }

  void _updateColorScheme() {
    setState(() {
      currentScheme = colorSchemes[Random().nextInt(colorSchemes.length)];
    });
  }

  void _undoLastSwipe() {
    if (!_canUndo || _lastSwipeDirection == null || _lastSwipedProfile == null) return;

    setState(() {
      _canUndo = false;
    });

    if (_lastSwipeDirection == CardSwiperDirection.right) {
      _undoLike(_lastSwipedProfile['id']);
      _swipeController.undo();
    } else if (_lastSwipeDirection == CardSwiperDirection.left) {
      _swipeController.undo();
    } else if (_lastSwipeDirection == CardSwiperDirection.top || _lastSwipeDirection == CardSwiperDirection.bottom) {
      _swipeController.undo();
      Navigator.pop(context);
    }

    _lastSwipeDirection = null;
    _lastSwipedProfile = null;
  }

  void _showUploadPostDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: currentScheme.buttonForeground.withOpacity(0.9),
        title: Text('Create a Post', style: TextStyle(color: currentScheme.textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _captionController,
              decoration: InputDecoration(
                labelText: 'Caption',
                labelStyle: TextStyle(color: currentScheme.textColor.withOpacity(0.7)),
                filled: true,
                fillColor: currentScheme.buttonBackground.withOpacity(0.7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: currentScheme.buttonForeground),
                ),
              ),
              style: TextStyle(color: currentScheme.textColor),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadPost();
            },
            child: Text('Upload', style: TextStyle(color: currentScheme.buttonForeground)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: currentScheme.textColor.withOpacity(0.7))),
          ),
        ],
      ),
    );
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage()),
    );
  }

  void _sortProfiles(String? option) {
    setState(() {
      _sortOption = option ?? 'Default';
      _fetchProfiles();
    });
  }

  void _filterProfiles(String keyword) {
    setState(() {
      _filterKeyword = keyword;
      _fetchProfiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Center(child: CircularProgressIndicator(color: currentScheme.buttonForeground));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Dinger', style: TextStyle(color: currentScheme.buttonForeground)),
        backgroundColor: currentScheme.buttonBackground,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort, color: currentScheme.textColor),
            onSelected: _sortProfiles,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'Default', child: Text('Default', style: TextStyle(color: currentScheme.textColor))),
              PopupMenuItem(value: 'Alphabetical', child: Text('Alphabetical', style: TextStyle(color: currentScheme.textColor))),
            ],
          ),
          IconButton(
            icon: Icon(Icons.filter_list, color: currentScheme.textColor),
            onPressed: () => showDialog(
              context: context,
              builder: (context) {
                final TextEditingController filterController = TextEditingController();
                return AlertDialog(
                  backgroundColor: currentScheme.buttonForeground.withOpacity(0.9),
                  title: Text('Filter by Bio', style: TextStyle(color: currentScheme.textColor)),
                  content: TextField(
                    controller: filterController,
                    decoration: InputDecoration(
                      labelText: 'Keyword',
                      labelStyle: TextStyle(color: currentScheme.textColor.withOpacity(0.7)),
                      filled: true,
                      fillColor: currentScheme.buttonBackground.withOpacity(0.7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: currentScheme.buttonForeground),
                      ),
                    ),
                    style: TextStyle(color: currentScheme.textColor),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        _filterProfiles(filterController.text);
                        Navigator.pop(context);
                      },
                      child: Text('Apply', style: TextStyle(color: currentScheme.buttonBackground)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: currentScheme.textColor.withOpacity(0.7))),
                    ),
                  ],
                );
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout, color: currentScheme.textColor),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(gradient: currentScheme.backgroundGradient),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Text(
                  'Edit Profile',
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: currentScheme.buttonForeground),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _bioController,
                      decoration: InputDecoration(
                        labelText: 'Bio',
                        labelStyle: TextStyle(color: currentScheme.textColor.withOpacity(0.7)),
                        filled: true,
                        fillColor: currentScheme.buttonForeground.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: currentScheme.buttonBackground),
                        ),
                      ),
                      style: TextStyle(color: currentScheme.textColor),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _favoriteFoodController,
                      decoration: InputDecoration(
                        labelText: 'Favorite Food',
                        labelStyle: TextStyle(color: currentScheme.textColor.withOpacity(0.7)),
                        filled: true,
                        fillColor: currentScheme.buttonForeground.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: currentScheme.buttonBackground),
                        ),
                      ),
                      style: TextStyle(color: currentScheme.textColor),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _twoTruthsController,
                      decoration: InputDecoration(
                        labelText: 'Two Truths and a Lie',
                        labelStyle: TextStyle(color: currentScheme.textColor.withOpacity(0.7)),
                        filled: true,
                        fillColor: currentScheme.buttonForeground.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: currentScheme.buttonBackground),
                        ),
                      ),
                      style: TextStyle(color: currentScheme.textColor),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _dreamVacationController,
                      decoration: InputDecoration(
                        labelText: 'Dream Vacation',
                        labelStyle: TextStyle(color: currentScheme.textColor.withOpacity(0.7)),
                        filled: true,
                        fillColor: currentScheme.buttonForeground.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: currentScheme.buttonBackground),
                        ),
                      ),
                      style: TextStyle(color: currentScheme.textColor),
                    ),
                    const SizedBox(height: 20),
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: ElevatedButton(
                        onPressed: () {
                          _animationController.forward().then((_) => _animationController.reverse());
                          _updateProfile();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: currentScheme.buttonBackground,
                          foregroundColor: currentScheme.buttonForeground,
                        ),
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: currentScheme.backgroundGradient),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 300,
                  child: _profiles.isEmpty
                      ? Text('No profiles yet', style: TextStyle(fontSize: 18, color: currentScheme.textColor))
                      : CardSwiper(
                          controller: _swipeController,
                          cardsCount: _profiles.length,
                          onSwipe: (previousIndex, currentIndex, direction) {
                            setState(() {
                              _lastSwipeDirection = direction;
                              _lastSwipedProfile = _profiles[previousIndex];
                              _canUndo = true;
                            });
                            if (direction == CardSwiperDirection.right) {
                              _likeProfile(_profiles[previousIndex]['id']);
                              _showHeartEmojis(context);
                              _updateColorScheme();
                            } else if (direction == CardSwiperDirection.top || direction == CardSwiperDirection.bottom) {
                              final profile = _profiles[previousIndex];
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfilePage(profile: profile, initialTab: 1, colorScheme: currentScheme),
                                ),
                              );
                            } else {
                              _showSwipeEmoji(direction);
                            }
                            _animationController.forward().then((_) => _animationController.reverse());
                            return true;
                          },
                          allowedSwipeDirection: AllowedSwipeDirection.all(),
                          cardBuilder: (context, index, horizontalOffsetPercentage, verticalOffsetPercentage) {
                            final profile = _profiles[index];
                            return ScaleTransition(
                              scale: _scaleAnimation,
                              child: ProfileCard(
                                username: profile['username'] ?? 'Unknown',
                                bio: profile['bio'] ?? '',
                                videoUrl: profile['video_url'],
                                favoriteFood: profile['favorite_food'],
                                dreamVacation: profile['dream_vacation'],
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ProfilePage(profile: profile, colorScheme: currentScheme)),
                                ),
                                colorScheme: currentScheme,
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () => _swipeController.swipe(CardSwiperDirection.left),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: currentScheme.buttonBackground,
                          foregroundColor: currentScheme.buttonForeground,
                        ),
                        child: const Icon(Icons.arrow_left),
                      ),
                      if (_canUndo)
                        ElevatedButton(
                          onPressed: _undoLastSwipe,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentScheme.buttonForeground,
                            foregroundColor: currentScheme.buttonBackground,
                          ),
                          child: const Icon(Icons.undo),
                        ),
                      ElevatedButton(
                        onPressed: () => _swipeController.swipe(CardSwiperDirection.right),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: currentScheme.buttonBackground,
                          foregroundColor: currentScheme.buttonForeground,
                        ),
                        child: const Icon(Icons.arrow_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: ElevatedButton(
                          onPressed: () {
                            _animationController.forward().then((_) => _animationController.reverse());
                            _recordAndUploadVideo();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentScheme.buttonBackground,
                            foregroundColor: currentScheme.buttonForeground,
                          ),
                          child: const Text('Record & Upload Video'),
                        ),
                      ),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: ElevatedButton(
                          onPressed: () {
                            _animationController.forward().then((_) => _animationController.reverse());
                            _uploadImages();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentScheme.buttonBackground,
                            foregroundColor: currentScheme.buttonForeground,
                          ),
                          child: const Text('Upload Images'),
                        ),
                      ),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: ElevatedButton(
                          onPressed: () {
                            _animationController.forward().then((_) => _animationController.reverse());
                            _showUploadPostDialog();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentScheme.buttonBackground,
                            foregroundColor: currentScheme.buttonForeground,
                          ),
                          child: const Text('Create Post'),
                        ),
                      ),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: ElevatedButton(
                          onPressed: () {
                            _animationController.forward().then((_) => _animationController.reverse());
                            Navigator.push(context, MaterialPageRoute(builder: (_) => LikedProfilesScreen(token: widget.token, colorScheme: currentScheme)));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentScheme.buttonBackground,
                            foregroundColor: currentScheme.buttonForeground,
                          ),
                          child: const Text('View Liked Profiles'),
                        ),
                      ),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: ElevatedButton(
                          onPressed: () {
                            _animationController.forward().then((_) => _animationController.reverse());
                            Navigator.push(context, MaterialPageRoute(builder: (_) => MatchesScreen(token: widget.token, colorScheme: currentScheme)));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentScheme.buttonBackground,
                            foregroundColor: currentScheme.buttonForeground,
                          ),
                          child: const Text('View Matches'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _profiles.length > 5 ? 5 : _profiles.length,
                      itemBuilder: (context, index) {
                        final profile = _profiles[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(profile: profile, colorScheme: currentScheme))),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: currentScheme.buttonBackground,
                                  child: Text(
                                    profile['username']?[0] ?? 'U',
                                    style: TextStyle(fontSize: 32, color: currentScheme.textColor),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  profile['username'] ?? 'Unknown',
                                  style: TextStyle(color: currentScheme.buttonForeground, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _animationController.dispose();
    _captionController.dispose();
    super.dispose();
  }
}

class LikedProfilesScreen extends StatefulWidget {
  final String token;
  final AppColorScheme colorScheme;

  const LikedProfilesScreen({super.key, required this.token, required this.colorScheme});

  @override
  _LikedProfilesScreenState createState() => _LikedProfilesScreenState();
}

class _LikedProfilesScreenState extends State<LikedProfilesScreen> {
  List<dynamic> _likedProfiles = [];

  @override
  void initState() {
    super.initState();
    _fetchLikedProfiles();
  }

  Future<void> _fetchLikedProfiles() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/liked/'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      print('Fetch liked profiles status: ${response.statusCode}');
      print('Fetch liked profiles body: ${response.body}');
      if (response.statusCode == 200) {
        setState(() {
          _likedProfiles = jsonDecode(response.body);
          print('Liked profiles set: $_likedProfiles');
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch liked profiles: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Fetch liked profiles error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching liked profiles: $e')),
      );
    }
  }

  Future<Map<String, dynamic>> _fetchProfile(String username) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/profiles/'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final profiles = data['profiles'] as List<dynamic>;
        return profiles.firstWhere((profile) => profile['username'] == username);
      }
      throw Exception('Profile not found');
    } catch (e) {
      print('Fetch profile error for $username: $e');
      rethrow;
    }
  }

  void _navigateToProfile(String username) async {
    try {
      final profile = await _fetchProfile(username);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfilePage(profile: profile, colorScheme: widget.colorScheme)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liked Profiles', style: TextStyle(color: widget.colorScheme.buttonForeground)),
        backgroundColor: widget.colorScheme.buttonBackground,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: widget.colorScheme.backgroundGradient),
        child: _likedProfiles.isEmpty
            ? Center(child: Text('No liked profiles yet', style: TextStyle(fontSize: 18, color: widget.colorScheme.textColor)))
            : ListView.builder(
                itemCount: _likedProfiles.length,
                itemBuilder: (context, index) {
                  final profile = _likedProfiles[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    elevation: 4,
                    color: widget.colorScheme.buttonForeground.withOpacity(0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: InkWell(
                        onTap: () => _navigateToProfile(profile['liked_username']),
                        child: Text(
                          profile['liked_username'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: widget.colorScheme.textColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      subtitle: Text(
                        'Liked on: ${profile['timestamp']}',
                        style: TextStyle(color: widget.colorScheme.textColor.withOpacity(0.7)),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class MatchesScreen extends StatefulWidget {
  final String token;
  final AppColorScheme colorScheme;

  const MatchesScreen({super.key, required this.token, required this.colorScheme});

  @override
  _MatchesScreenState createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<dynamic> _matches = [];

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/matches/'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _matches = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print('Fetch matches error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Matches', style: TextStyle(color: widget.colorScheme.buttonForeground)),
        backgroundColor: widget.colorScheme.buttonBackground,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: widget.colorScheme.backgroundGradient),
        child: _matches.isEmpty
            ? Center(child: Text('No matches yet', style: TextStyle(color: widget.colorScheme.textColor)))
            : ListView.builder(
                itemCount: _matches.length,
                itemBuilder: (context, index) {
                  final match = _matches[index];
                  final otherUser = match['user1_username'] == _usernameFromToken(widget.token)
                      ? match['user2_username']
                      : match['user1_username'];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    elevation: 4,
                    color: widget.colorScheme.buttonForeground.withOpacity(0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(otherUser, style: TextStyle(color: widget.colorScheme.textColor)),
                      subtitle: Text('Matched on: ${match['timestamp']}', style: TextStyle(color: widget.colorScheme.textColor.withOpacity(0.7))),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(matchId: match['id'], token: widget.token, colorScheme: widget.colorScheme),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _usernameFromToken(String token) {
    final parts = token.split('.');
    final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
    return payload['username'] ?? 'Unknown';
  }
}

class ChatScreen extends StatefulWidget {
  final int matchId;
  final String token;
  final AppColorScheme colorScheme;

  const ChatScreen({super.key, required this.matchId, required this.token, required this.colorScheme});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Map<String, dynamic>> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  String? _currentUser;
  late IOWebSocketChannel _channel;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _currentUser = _usernameFromToken(widget.token);
    _connectWebSocket();
    _fetchMessages();
  }

  void _connectWebSocket() {
    _channel = IOWebSocketChannel.connect('ws://localhost:8000/ws/chat/${widget.matchId}/');
    _channel.stream.listen(
      (message) {
        final data = jsonDecode(message);
        print('Received WebSocket message: $data');
        setState(() {
          if (!_messages.any((msg) => msg['content'] == data['content'] && msg['timestamp'] == data['timestamp'])) {
            _messages.add(data);
          }
        });
      },
      onError: (error) {
        print('WebSocket error: $error');
        setState(() => _isConnected = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('WebSocket error: $error')),
        );
      },
      onDone: () {
        print('WebSocket closed');
        setState(() => _isConnected = false);
      },
    );
    _channel.ready.then((_) {
      print('WebSocket connection established for match ${widget.matchId}');
      setState(() => _isConnected = true);
    }).catchError((error) {
      print('WebSocket connection failed: $error');
      setState(() => _isConnected = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to chat: $error')),
      );
    });
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/chat/${widget.matchId}/'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      print('Fetch messages status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> fetchedMessages = jsonDecode(response.body);
        setState(() {
          _messages = fetchedMessages.map((msg) => msg as Map<String, dynamic>).toList();
          print('Messages fetched: $_messages');
        });
      } else {
        print('Fetch messages failed: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch messages: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Fetch messages error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching messages: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || !_isConnected) {
      print('Cannot send message: ${_messageController.text.isEmpty ? "Empty message" : "Not connected"}');
      return;
    }
    try {
      final message = {
        'message': _messageController.text, // Changed to 'message' to match backend
        'sender': _currentUser,
        'timestamp': DateTime.now().toIso8601String(),
      };
      print('Sending message: $message');
      _channel.sink.add(jsonEncode(message));
      setState(() {
        _messages.add(message);
      });
      _messageController.clear();
    } catch (e) {
      print('Send message error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  String _usernameFromToken(String token) {
    final parts = token.split('.');
    final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
    return payload['username'] ?? 'Unknown';
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      return DateFormat('MMM d, yyyy, h:mm a').format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat${_isConnected ? '' : ' (Disconnected)'}', style: TextStyle(color: widget.colorScheme.buttonForeground)),
        backgroundColor: widget.colorScheme.buttonBackground,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: widget.colorScheme.backgroundGradient),
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? Center(child: Text('No messages yet', style: TextStyle(color: widget.colorScheme.textColor)))
                  : ListView.builder(
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isMe = message['sender'] == _currentUser || (message['sender_username'] != null && message['sender_username'] == _currentUser);
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? widget.colorScheme.buttonForeground.withOpacity(0.8) : Colors.grey.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message['message'] ?? message['content'], // Handle both keys for compatibility
                                  style: TextStyle(color: widget.colorScheme.textColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTimestamp(message['timestamp']),
                                  style: TextStyle(fontSize: 10, color: widget.colorScheme.textColor.withOpacity(0.7)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _isConnected ? 'Type a message' : 'Disconnected',
                        hintStyle: TextStyle(color: widget.colorScheme.textColor.withOpacity(0.7)),
                        filled: true,
                        fillColor: widget.colorScheme.buttonForeground.withOpacity(0.7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: widget.colorScheme.buttonBackground),
                        ),
                      ),
                      style: TextStyle(color: widget.colorScheme.textColor),
                      enabled: _isConnected,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: widget.colorScheme.buttonForeground),
                    onPressed: _isConnected ? _sendMessage : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _channel.sink.close();
    _messageController.dispose();
    super.dispose();
  }
}

class ProfileCard extends StatefulWidget {
  final String username;
  final String bio;
  final String? videoUrl;
  final String? favoriteFood;
  final String? dreamVacation;
  final VoidCallback onTap;
  final AppColorScheme colorScheme;

  const ProfileCard({super.key, 
    required this.username,
    required this.bio,
    this.videoUrl,
    this.favoriteFood,
    this.dreamVacation,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  _ProfileCardState createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  VideoPlayerController? _videoController;
  String? _errorMessage;
  bool _isPlaying = true;

  List<Widget> _getBadges() {
    List<Widget> badges = [];
    if (widget.favoriteFood != null && widget.favoriteFood!.isNotEmpty) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text('Foodie', style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
      );
    }
    if (widget.dreamVacation != null && widget.dreamVacation!.isNotEmpty) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text('Traveler', style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
      );
    }
    return badges;
  }

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      _videoController = VideoPlayerController.network(widget.videoUrl!)
        ..initialize().then((_) {
          _videoController!.play();
          setState(() {});
        }).catchError((e) {
          setState(() => _errorMessage = 'Failed to load video: $e');
        });
      _videoController!.setLooping(true);
    } else {
      _errorMessage = 'No video available';
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        _videoController!.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 300,
        height: 500,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [widget.colorScheme.buttonForeground, widget.colorScheme.buttonBackground],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_videoController != null && _videoController!.value.isInitialized)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: VideoPlayer(_videoController!),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: widget.colorScheme.buttonBackground.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: Text(_errorMessage ?? 'No video', style: TextStyle(color: widget.colorScheme.textColor))),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(widget.username, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: widget.colorScheme.buttonForeground)),
                        const SizedBox(width: 8),
                        ..._getBadges(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(widget.bio, style: TextStyle(fontSize: 16, color: widget.colorScheme.textColor.withOpacity(0.7))),
                  ],
                ),
              ),
            ),
            if (_videoController != null && _videoController!.value.isInitialized)
              Positioned(
                bottom: 16,
                right: 16,
                child: IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: widget.colorScheme.buttonForeground, size: 30),
                  onPressed: _togglePlayPause,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
}

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> profile;
  final int initialTab;
  final AppColorScheme colorScheme;

  const ProfilePage({super.key, required this.profile, this.initialTab = 0, required this.colorScheme});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  late TabController _tabController;

  List<Widget> _getBadges() {
    List<Widget> badges = [];
    if (widget.profile['favorite_food'] != null && widget.profile['favorite_food'].isNotEmpty) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text('Foodie', style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
      );
    }
    if (widget.profile['dream_vacation'] != null && widget.profile['dream_vacation'].isNotEmpty) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text('Traveler', style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
      );
    }
    return badges;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    final videoUrl = widget.profile['video_url'] as String?;
    if (videoUrl != null && videoUrl.isNotEmpty) {
      _videoController = VideoPlayerController.network(videoUrl)
        ..initialize().then((_) {
          setState(() {});
          _videoController!.play();
        }).catchError((e) {
          print('Profile video init error: $e');
        });
      _videoController!.setLooping(true);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoUrl = widget.profile['video_url'] as String?;
    final imageUrls = (widget.profile['image_urls'] as List<dynamic>?) ?? [];
    final posts = (widget.profile['posts'] as List<dynamic>?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('${widget.profile['username']}\'s Profile', style: TextStyle(color: widget.colorScheme.buttonForeground)),
            const SizedBox(width: 8),
            ..._getBadges(),
          ],
        ),
        backgroundColor: widget.colorScheme.buttonBackground,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: widget.colorScheme.backgroundGradient),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_videoController != null && _videoController!.value.isInitialized)
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: VideoPlayer(_videoController!),
                  )
                else
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: widget.colorScheme.buttonBackground.withOpacity(0.8),
                    child: Center(child: Text('No profile video', style: TextStyle(color: widget.colorScheme.textColor))),
                  ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  labelStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: widget.colorScheme.buttonForeground),
                  unselectedLabelStyle: GoogleFonts.poppins(fontSize: 18, color: widget.colorScheme.textColor.withOpacity(0.7)),
                  labelColor: widget.colorScheme.buttonForeground,
                  unselectedLabelColor: widget.colorScheme.textColor.withOpacity(0.7),
                  indicatorColor: widget.colorScheme.buttonForeground,
                  tabs: const [
                    Tab(text: 'Profile'),
                    Tab(text: 'Posts'),
                  ],
                ),
                SizedBox(
                  height: 400,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Text('Bio:', style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: widget.colorScheme.buttonForeground)),
                            Text(widget.profile['bio'] ?? 'No bio', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: widget.colorScheme.textColor)),
                            const SizedBox(height: 16),
                            Text('Favorite Food:', style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: widget.colorScheme.buttonForeground)),
                            Text(widget.profile['favorite_food'] ?? 'Not set', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: widget.colorScheme.textColor)),
                            const SizedBox(height: 16),
                            Text('Two Truths and a Lie:', style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: widget.colorScheme.buttonForeground)),
                            Text(widget.profile['two_truths_and_a_lie'] ?? 'Not set', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: widget.colorScheme.textColor)),
                            const SizedBox(height: 16),
                            Text('Dream Vacation:', style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: widget.colorScheme.buttonForeground)),
                            Text(widget.profile['dream_vacation'] ?? 'Not set', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: widget.colorScheme.textColor)),
                            const SizedBox(height: 16),
                            Text('Images:', style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: widget.colorScheme.buttonForeground)),
                            const SizedBox(height: 8),
                            imageUrls.isNotEmpty
                                ? Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: imageUrls.map((url) => Image.network(url.toString(), width: 100, height: 100, fit: BoxFit.cover)).toList(),
                                  )
                                : Text('No images available', style: TextStyle(color: widget.colorScheme.textColor)),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        child: posts.isNotEmpty
                            ? Column(
                                children: posts.map((post) => Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: widget.colorScheme.buttonBackground.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                        child: Image.network(
                                          post['image_url'],
                                          width: double.infinity,
                                          height: 200,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              post['caption'],
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                color: widget.colorScheme.textColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Posted: ${post['created_at']}',
                                              style: GoogleFonts.poppins(fontSize: 12, color: widget.colorScheme.textColor.withOpacity(0.7)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                              )
                            : Text('No posts available', style: TextStyle(color: widget.colorScheme.textColor)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}