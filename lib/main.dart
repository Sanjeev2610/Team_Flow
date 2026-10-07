import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const TeamFlowApp());
}

// ============================================================
// API SERVICE
// ============================================================

class Api {
  static const baseUrl='http://127.0.0.1:5000';

  static Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 15));
          break;

        case 'POST':
          response = await http
              .post(
                uri,
                headers: headers,
                body: jsonEncode(body ?? {}),
              )
              .timeout(const Duration(seconds: 15));
          break;

        case 'PUT':
          response = await http
              .put(
                uri,
                headers: headers,
                body: jsonEncode(body ?? {}),
              )
              .timeout(const Duration(seconds: 15));
          break;

        case 'PATCH':
          response = await http
              .patch(
                uri,
                headers: headers,
                body: jsonEncode(body ?? {}),
              )
              .timeout(const Duration(seconds: 15));
          break;

        case 'DELETE':
          response = await http
              .delete(uri, headers: headers)
              .timeout(const Duration(seconds: 15));
          break;

        default:
          return {
            'success': false,
            'message': 'Unsupported HTTP method',
          };
      }

      if (response.body.isEmpty) {
        return {
          'success': response.statusCode >= 200 &&
              response.statusCode < 300,
          'message': 'Empty server response',
        };
      }

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        return {
          'success': false,
          'message':
              'Server returned invalid response (${response.statusCode})',
        };
      }

      if (decoded is Map<String, dynamic>) {
        if (!decoded.containsKey('success')) {
          decoded['success'] =
              response.statusCode >= 200 && response.statusCode < 300;
        }

        if (response.statusCode < 200 || response.statusCode >= 300) {
          decoded['success'] = false;
        }

        return decoded;
      }

      return {
        'success': response.statusCode >= 200 &&
            response.statusCode < 300,
        'data': decoded,
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Server request timed out',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Server connection failed: $e',
      };
    }
  }

  // ---------------- AUTH ----------------

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) {
    return request(
      'POST',
      '/login',
      body: {
        'email': email,
        'password': password,
      },
    );
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) {
    return request(
      'POST',
      '/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
      },
    );
  }

  // ---------------- USERS ----------------

  static Future<Map<String, dynamic>> users() {
    return request('GET', '/users');
  }

  // ---------------- TEAMS ----------------

  static Future<Map<String, dynamic>> teams() {
    return request('GET', '/teams');
  }

  static Future<Map<String, dynamic>> createTeam({
    required String name,
    required String description,
    required int createdBy,
  }) {
    return request(
      'POST',
      '/teams',
      body: {
        'team_name': name,
        'description': description,
        'created_by': createdBy,
      },
    );
  }

  // ---------------- PROJECTS ----------------

  static Future<Map<String, dynamic>> projects() {
    return request('GET', '/projects');
  }

  static Future<Map<String, dynamic>> createProject({
    required String name,
    required String description,
    required int teamId,
    required String status,
    required String priority,
    String? startDate,
    String? dueDate,
    required int createdBy,
  }) {
    return request(
      'POST',
      '/projects',
      body: {
        'project_name': name,
        'description': description,
        'team_id': teamId,
        'status': status,
        'priority': priority,
        'start_date': startDate,
        'due_date': dueDate,
        'created_by': createdBy,
      },
    );
  }

  // ---------------- TASKS ----------------

  static Future<Map<String, dynamic>> tasks() {
    return request('GET', '/tasks');
  }

  static Future<Map<String, dynamic>> createTask({
    required String title,
    required String description,
    required int createdBy,
    int? projectId,
    int? assignedTo,
    String priority = 'Medium',
    String status = 'Pending',
    String? dueDate,
  }) {
    return request(
      'POST',
      '/tasks',
      body: {
        'title': title,
        'description': description,
        'created_by': createdBy,
        'project_id': projectId,
        'assigned_to': assignedTo,
        'priority': priority,
        'status': status,
        'due_date': dueDate,
      },
    );
  }

  static Future<Map<String, dynamic>> updateTask(
    int taskId,
    String status,
  ) {
    return request(
      'PUT',
      '/tasks/$taskId',
      body: {
        'status': status,
      },
    );
  }

  // ---------------- MEETINGS ----------------

  static Future<Map<String, dynamic>> meetings() {
    return request('GET', '/meetings');
  }

  static Future<Map<String, dynamic>> createMeeting({
    required String title,
    required String description,
    required String meetingLink,
    required int organizerId,
    String? startTime,
    String? endTime,
    int? teamId,
    int? projectId,
  }) {
    return request(
      'POST',
      '/meetings',
      body: {
        'title': title,
        'description': description,
        'meeting_link': meetingLink,
        'organizer_id': organizerId,
        'start_time': startTime,
        'end_time': endTime,
        'team_id': teamId,
        'project_id': projectId,
        'status': 'Scheduled',
      },
    );
  }

  // ---------------- CHAT ROOMS ----------------

  static Future<Map<String, dynamic>> chats() {
    return request('GET', '/chat-rooms');
  }

  static Future<Map<String, dynamic>> createChat({
    required String name,
    required int createdBy,
    String roomType = 'Direct',
  }) {
    return request(
      'POST',
      '/chat-rooms',
      body: {
        'name': name,
        'room_type': roomType,
        'created_by': createdBy,
      },
    );
  }

  static Future<Map<String, dynamic>> messages(int roomId) {
    return request(
      'GET',
      '/chat-rooms/$roomId/messages',
    );
  }

  static Future<Map<String, dynamic>> sendMessage({
    required int roomId,
    required int senderId,
    required String message,
  }) {
    return request(
      'POST',
      '/chat-rooms/$roomId/messages',
      body: {
        'sender_id': senderId,
        'message_text': message,
      },
    );
  }

  // ---------------- NOTIFICATIONS ----------------

  static Future<Map<String, dynamic>> notifications(int userId) {
    return request(
      'GET',
      '/notifications/$userId',
    );
  }

  static Future<Map<String, dynamic>> readNotification(
    int notificationId,
  ) {
    return request(
      'PUT',
      '/notifications/$notificationId/read',
    );
  }

  // ---------------- PROFILE ----------------

  static Future<Map<String, dynamic>> profile(int userId) {
    return request(
      'GET',
      '/profile/$userId',
    );
  }

  static Future<Map<String, dynamic>> updateProfile(
    int userId,
    Map<String, dynamic> data,
  ) {
    return request(
      'PUT',
      '/profile/$userId',
      body: data,
    );
  }

  // ---------------- SETTINGS ----------------

  static Future<Map<String, dynamic>> settings(int userId) {
    return request(
      'GET',
      '/settings/$userId',
    );
  }

  static Future<Map<String, dynamic>> updateSettings(
    int userId,
    Map<String, dynamic> data,
  ) {
    return request(
      'PUT',
      '/settings/$userId',
      body: data,
    );
  }
}

// ============================================================
// USER MODEL
// ============================================================

class User {
  final int id;
  String name;
  String email;
  String role;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.tryParse('${json['user_id']}') ?? 0,
      name: '${json['name'] ?? ''}',
      email: '${json['email'] ?? ''}',
      role: '${json['role'] ?? 'Employee'}',
    );
  }
}

// ============================================================
// APP
// ============================================================

class TeamFlowApp extends StatefulWidget {
  const TeamFlowApp({super.key});

  @override
  State<TeamFlowApp> createState() => _TeamFlowAppState();
}

class _TeamFlowAppState extends State<TeamFlowApp> {
  bool darkMode = false;

  void toggleTheme() {
    setState(() {
      darkMode = !darkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TeamFlow',
      themeMode:
          darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed:
            const Color(0xff635bff),
        scaffoldBackgroundColor:
            const Color(0xfff7f8fc),
        inputDecorationTheme:
            InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed:
            const Color(0xff635bff),
        brightness: Brightness.dark,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
      ),
      home: LoginScreen(
        onTheme: toggleTheme,
      ),
    );
  }
}

// ============================================================
// LOGIN
// ============================================================

class LoginScreen extends StatefulWidget {
  final VoidCallback onTheme;

  const LoginScreen({
    super.key,
    required this.onTheme,
  });

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  bool loading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> login() async {
    final email =
        emailController.text.trim();

    final password =
        passwordController.text;

    if (email.isEmpty ||
        password.isEmpty) {
      showMessage(
        'Enter email and password',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    final result =
        await Api.login(email, password);

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    if (result['success'] == true) {
      final user =
          User.fromJson(result['user']);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => Dashboard(
            user: user,
          ),
        ),
      );
    } else {
      showMessage(
        result['message'] ??
            'Login failed',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 430,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.groups_rounded,
                  size: 80,
                  color:
                      Color(0xff635bff),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Welcome back',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to TeamFlow',
                  textAlign:
                      TextAlign.center,
                ),
                const SizedBox(height: 30),
                appField(
                  'Email',
                  emailController,
                  Icons.email_outlined,
                  keyboardType:
                      TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                appField(
                  'Password',
                  passwordController,
                  Icons.lock_outline,
                  obscureText:
                      obscurePassword,
                  suffix: IconButton(
                    onPressed: () {
                      setState(() {
                        obscurePassword =
                            !obscurePassword;
                      });
                    },
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed:
                        loading ? null : login,
                    child: loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Text(
                            'Sign In',
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const SignupScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Create an account',
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

// ============================================================
// SIGNUP
// ============================================================

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() =>
      _SignupScreenState();
}

class _SignupScreenState
    extends State<SignupScreen> {
  final nameController =
      TextEditingController();

  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  final confirmController =
      TextEditingController();

  bool loading = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> register() async {
    final name =
        nameController.text.trim();

    final email =
        emailController.text.trim();

    final password =
        passwordController.text;

    final confirm =
        confirmController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      showMessage(
        'Fill all fields',
      );
      return;
    }

    if (password != confirm) {
      showMessage(
        'Passwords do not match',
      );
      return;
    }

    if (password.length < 6) {
      showMessage(
        'Password must contain at least 6 characters',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    final result =
        await Api.register(
      name,
      email,
      password,
    );

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    if (result['success'] == true) {
      showMessage(
        'Account created successfully',
      );

      Navigator.pop(context);
    } else {
      showMessage(
        result['message'] ??
            'Registration failed',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Create Account'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 430,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Join TeamFlow',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                appField(
                  'Full Name',
                  nameController,
                  Icons.person_outline,
                ),
                const SizedBox(height: 15),
                appField(
                  'Email',
                  emailController,
                  Icons.email_outlined,
                  keyboardType:
                      TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),
                appField(
                  'Password',
                  passwordController,
                  Icons.lock_outline,
                  obscureText:
                      obscurePassword,
                  suffix: IconButton(
                    onPressed: () {
                      setState(() {
                        obscurePassword =
                            !obscurePassword;
                      });
                    },
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                appField(
                  'Confirm Password',
                  confirmController,
                  Icons.lock_outline,
                  obscureText:
                      obscureConfirm,
                  suffix: IconButton(
                    onPressed: () {
                      setState(() {
                        obscureConfirm =
                            !obscureConfirm;
                      });
                    },
                    icon: Icon(
                      obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed:
                        loading ? null : register,
                    child: loading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'Create Account',
                          ),
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

// ============================================================
// DASHBOARD
// ============================================================

class Dashboard extends StatefulWidget {
  final User user;

  const Dashboard({
    super.key,
    required this.user,
  });

  @override
  State<Dashboard> createState() =>
      _DashboardState();
}

class _DashboardState
    extends State<Dashboard> {
  int selectedIndex = 0;

  final titles = const [
    'Dashboard',
    'Projects',
    'Teams',
    'Meetings',
    'Tasks',
    'Chats',
    'Notifications',
    'Profile',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(user: widget.user),
      ProjectsPage(user: widget.user),
      TeamsPage(user: widget.user),
      MeetingsPage(user: widget.user),
      TasksPage(user: widget.user),
      ChatsPage(user: widget.user),
      NotificationsPage(user: widget.user),
      ProfilePage(user: widget.user),
      SettingsPage(user: widget.user),
    ];

    final wide =
        MediaQuery.sizeOf(context).width >=
            900;

    return Scaffold(
      drawer: wide
          ? null
          : Drawer(
              child: NavigationPanel(
                selected:
                    selectedIndex,
                onTap: (index) {
                  setState(() {
                    selectedIndex =
                        index;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              SizedBox(
                width: 245,
                child: NavigationPanel(
                  selected:
                      selectedIndex,
                  onTap: (index) {
                    setState(() {
                      selectedIndex =
                          index;
                    });
                  },
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  DashboardHeader(
                    title:
                        titles[selectedIndex],
                    user: widget.user,
                  ),
                  Expanded(
                    child:
                        pages[selectedIndex],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// NAVIGATION
// ============================================================

class NavigationPanel
    extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;

  const NavigationPanel({
    super.key,
    required this.selected,
    required this.onTap,
  });

  static const icons = [
    Icons.dashboard_outlined,
    Icons.folder_outlined,
    Icons.groups_outlined,
    Icons.video_call_outlined,
    Icons.task_alt_outlined,
    Icons.chat_outlined,
    Icons.notifications_outlined,
    Icons.person_outline,
    Icons.settings_outlined,
  ];

  static const labels = [
    'Dashboard',
    'Projects',
    'Teams',
    'Meetings',
    'Tasks',
    'Chats',
    'Notifications',
    'Profile',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context)
          .colorScheme
          .surface,
      child: Column(
        children: [
          const SizedBox(height: 22),
          const Row(
            children: [
              SizedBox(width: 18),
              Icon(
                Icons.groups_rounded,
                size: 38,
                color:
                    Color(0xff635bff),
              ),
              SizedBox(width: 10),
              Text(
                'TeamFlow',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Expanded(
            child: ListView.builder(
              itemCount: labels.length,
              itemBuilder:
                  (context, index) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  child: ListTile(
                    selected:
                        selected == index,
                    selectedTileColor:
                        const Color(
                      0x15635bff,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    leading:
                        Icon(icons[index]),
                    title:
                        Text(labels[index]),
                    onTap: () =>
                        onTap(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HEADER
// ============================================================

class DashboardHeader
    extends StatelessWidget {
  final String title;
  final User user;

  const DashboardHeader({
    super.key,
    required this.title,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final narrow =
        MediaQuery.sizeOf(context).width <
            900;

    return SizedBox(
      height: 72,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 18,
        ),
        child: Row(
          children: [
            if (narrow)
              Builder(
                builder: (context) {
                  return IconButton(
                    onPressed: () {
                      Scaffold.of(context)
                          .openDrawer();
                    },
                    icon:
                        const Icon(Icons.menu),
                  );
                },
              ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const Spacer(),
            CircleAvatar(
              child: Text(
                initials(user.name),
              ),
            ),
            const SizedBox(width: 10),
            if (MediaQuery.sizeOf(context)
                    .width >
                600)
              Text(
                user.name,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HOME
// ============================================================

class HomePage
    extends StatelessWidget {
  final User user;

  const HomePage({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding:
          const EdgeInsets.all(22),
      children: [
        Text(
          'Good day, ${user.name.split(' ').first}! 👋',
          style: const TextStyle(
            fontSize: 28,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Your workspace at a glance.',
        ),
        const SizedBox(height: 22),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            DashboardStat(
              title: 'Projects',
              icon: Icons.folder,
            ),
            DashboardStat(
              title: 'Tasks',
              icon: Icons.task_alt,
            ),
            DashboardStat(
              title: 'Meetings',
              icon: Icons.video_call,
            ),
            DashboardStat(
              title: 'Teams',
              icon: Icons.groups,
            ),
          ],
        ),

        const SizedBox(height: 22),

        DashboardSection(
          title: 'Quick Actions',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.folder,
                ),
                label:
                    const Text('Projects'),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.video_call,
                ),
                label:
                    const Text('Meetings'),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.chat,
                ),
                label:
                    const Text('Messages'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        DashboardSection(
          title: 'Workspace',
          child: Column(
            children: const [
              ListTile(
                leading: Icon(
                  Icons.folder,
                ),
                title:
                    Text('Projects'),
                subtitle: Text(
                  'Manage your team projects',
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.groups,
                ),
                title:
                    Text('Teams'),
                subtitle: Text(
                  'Collaborate with your teams',
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.task_alt,
                ),
                title:
                    Text('Tasks'),
                subtitle: Text(
                  'Track your work',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DashboardStat
    extends StatelessWidget {
  final String title;
  final IconData icon;

  const DashboardStat({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 95,
      child: Card(
        child: Padding(
          padding:
              const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    const Color(
                  0x15635bff,
                ),
                child: Icon(
                  icon,
                  color:
                      const Color(
                    0xff635bff,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                        height: 4),
                    const Text(
                      'Live data',
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

class DashboardSection
    extends StatelessWidget {
  final String title;
  final Widget child;

  const DashboardSection({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PROJECTS
// ============================================================

class ProjectsPage
    extends StatefulWidget {
  final User user;

  const ProjectsPage({
    super.key,
    required this.user,
  });

  @override
  State<ProjectsPage> createState() =>
      _ProjectsPageState();
}

class _ProjectsPageState
    extends State<ProjectsPage> {
  List projects = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadProjects();
  }

  Future<void> loadProjects() async {
    setState(() {
      loading = true;
      error = null;
    });

    final result =
        await Api.projects();

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        projects =
            result['projects'] ?? [];
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
        error =
            result['message'] ??
                'Unable to load projects';
      });
    }
  }

  Future<void> createProject() async {
    final nameController =
        TextEditingController();

    final descriptionController =
        TextEditingController();

    final teamResult =
        await Api.teams();

    if (!mounted) return;

    final availableTeams =
        teamResult['teams'] is List
            ? teamResult['teams']
            : [];

    if (availableTeams.isEmpty) {
      showMessage(
        'Create a team first',
      );
      return;
    }

    int selectedTeam =
        int.tryParse(
              '${availableTeams.first['team_id']}',
            ) ??
            0;

    String status = 'Planning';
    String priority = 'Medium';

    DateTime? startDate;
    DateTime? dueDate;

    final created =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder:
              (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'New Project',
              ),
              content: SizedBox(
                width: 520,
                child:
                    SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      appField(
                        'Project Name',
                        nameController,
                        Icons.folder_outlined,
                      ),
                      const SizedBox(
                          height: 12),
                      appField(
                        'Description',
                        descriptionController,
                        Icons.description_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(
                          height: 12),
                      DropdownButtonFormField<
                          int>(
                        initialValue:
                            selectedTeam,
                        decoration:
                            const InputDecoration(
                          labelText: 'Team',
                          border:
                              OutlineInputBorder(),
                        ),
                        items:
                            availableTeams
                                .map<
                                    DropdownMenuItem<
                                        int>>(
                          (team) {
                            final id =
                                int.tryParse(
                                      '${team['team_id']}',
                                    ) ??
                                    0;

                            return DropdownMenuItem<
                                int>(
                              value: id,
                              child: Text(
                                '${team['team_name'] ?? ''}',
                              ),
                            );
                          },
                        ).toList(),
                        onChanged: (value) {
                          if (value !=
                              null) {
                            setDialogState(
                              () {
                                selectedTeam =
                                    value;
                              },
                            );
                          }
                        },
                      ),
                      const SizedBox(
                          height: 12),
                      DropdownButtonFormField<
                          String>(
                        initialValue:
                            status,
                        decoration:
                            const InputDecoration(
                          labelText: 'Status',
                          border:
                              OutlineInputBorder(),
                        ),
                        items: const [
                          'Planning',
                          'In Progress',
                          'Completed',
                          'On Hold',
                        ]
                            .map(
                              (value) =>
                                  DropdownMenuItem(
                                value: value,
                                child:
                                    Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value !=
                              null) {
                            setDialogState(
                              () {
                                status =
                                    value;
                              },
                            );
                          }
                        },
                      ),
                      const SizedBox(
                          height: 12),
                      DropdownButtonFormField<
                          String>(
                        initialValue:
                            priority,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Priority',
                          border:
                              OutlineInputBorder(),
                        ),
                        items: const [
                          'Low',
                          'Medium',
                          'High',
                          'Critical',
                        ]
                            .map(
                              (value) =>
                                  DropdownMenuItem(
                                value: value,
                                child:
                                    Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value !=
                              null) {
                            setDialogState(
                              () {
                                priority =
                                    value;
                              },
                            );
                          }
                        },
                      ),
                      const SizedBox(
                          height: 8),
                      Row(
                        children: [
                          Expanded(
                            child:
                                OutlinedButton.icon(
                              onPressed:
                                  () async {
                                final date =
                                    await pickDate(
                                  context,
                                  startDate,
                                );

                                if (date !=
                                    null) {
                                  setDialogState(
                                    () {
                                      startDate =
                                          date;
                                    },
                                  );
                                }
                              },
                              icon:
                                  const Icon(
                                Icons
                                    .calendar_today,
                              ),
                              label: Text(
                                startDate ==
                                        null
                                    ? 'Start Date'
                                    : formatDate(
                                        startDate!,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(
                              width: 8),
                          Expanded(
                            child:
                                OutlinedButton.icon(
                              onPressed:
                                  () async {
                                final date =
                                    await pickDate(
                                  context,
                                  dueDate ??
                                      startDate,
                                );

                                if (date !=
                                    null) {
                                  setDialogState(
                                    () {
                                      dueDate =
                                          date;
                                    },
                                  );
                                }
                              },
                              icon:
                                  const Icon(
                                Icons
                                    .event,
                              ),
                              label: Text(
                                dueDate ==
                                        null
                                    ? 'Due Date'
                                    : formatDate(
                                        dueDate!,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(
                    dialogContext,
                    false,
                  ),
                  child:
                      const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (nameController
                        .text
                        .trim()
                        .isEmpty) {
                      return;
                    }

                    final result =
                        await Api.createProject(
                      name: nameController
                          .text
                          .trim(),
                      description:
                          descriptionController
                              .text
                              .trim(),
                      teamId: selectedTeam,
                      status: status,
                      priority: priority,
                      startDate:
                          startDate == null
                              ? null
                              : formatDate(
                                  startDate!,
                                ),
                      dueDate:
                          dueDate == null
                              ? null
                              : formatDate(
                                  dueDate!,
                                ),
                      createdBy:
                          widget.user.id,
                    );

                    if (result['success'] ==
                        true) {
                      if (dialogContext
                          .mounted) {
                        Navigator.pop(
                          dialogContext,
                          true,
                        );
                      }
                    } else {
                      if (context.mounted) {
                        showMessage(
                          result[
                                  'message'] ??
                              'Project creation failed',
                        );
                      }
                    }
                  },
                  child:
                      const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();

    if (created == true) {
      await loadProjects();

      if (mounted) {
        showMessage(
          'Project created successfully',
        );
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  double progressForStatus(
      String status) {
    switch (status) {
      case 'Completed':
        return 1.0;
      case 'In Progress':
        return 0.5;
      case 'On Hold':
        return 0.25;
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: loadProjects,
      child: ListView(
        padding:
            const EdgeInsets.all(22),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Projects',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed:
                    createProject,
                icon:
                    const Icon(Icons.add),
                label:
                    const Text('New Project'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (loading)
            const Padding(
              padding:
                  EdgeInsets.all(50),
              child: Center(
                child:
                    CircularProgressIndicator(),
              ),
            )
          else if (error != null)
            ErrorCard(
              message: error!,
              onRetry: loadProjects,
            )
          else if (projects.isEmpty)
            const EmptyCard(
              icon: Icons.folder_open,
              message:
                  'No projects yet.\nCreate your first project.',
            )
          else
            ...projects.map(
              (project) {
                final status =
                    '${project['status'] ?? 'Planning'}';

                return ProjectCard(
                  name:
                      '${project['project_name'] ?? ''}',
                  description:
                      '${project['description'] ?? ''}',
                  status: status,
                  priority:
                      '${project['priority'] ?? 'Medium'}',
                  teamId:
                      int.tryParse(
                            '${project['team_id']}',
                          ) ??
                          0,
                  progress:
                      progressForStatus(
                    status,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProjectDetailsPage(
                          project:
                              project,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class ProjectCard
    extends StatelessWidget {
  final String name;
  final String description;
  final String status;
  final String priority;
  final int teamId;
  final double progress;
  final VoidCallback onTap;

  const ProjectCard({
    super.key,
    required this.name,
    required this.description,
    required this.status,
    required this.priority,
    required this.teamId,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(16),
        child: Padding(
          padding:
              const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    child: Icon(
                      Icons.folder,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                  Chip(
                    label:
                        Text(priority),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                description.isEmpty
                    ? 'No description'
                    : description,
              ),
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: progress,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(status),
                  const Spacer(),
                  Text(
                    'Team $teamId',
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

class ProjectDetailsPage
    extends StatelessWidget {
  final Map project;

  const ProjectDetailsPage({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Project Details'),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(22),
        children: [
          const Icon(
            Icons.folder,
            size: 70,
            color: Color(0xff635bff),
          ),
          const SizedBox(height: 15),
          Text(
            '${project['project_name'] ?? ''}',
            textAlign:
                TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25),
          infoTile(
            'Description',
            '${project['description'] ?? 'No description'}',
          ),
          infoTile(
            'Status',
            '${project['status'] ?? ''}',
          ),
          infoTile(
            'Priority',
            '${project['priority'] ?? ''}',
          ),
          infoTile(
            'Team ID',
            '${project['team_id'] ?? ''}',
          ),
          infoTile(
            'Start Date',
            '${project['start_date'] ?? '-'}',
          ),
          infoTile(
            'Due Date',
            '${project['due_date'] ?? '-'}',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TEAMS
// ============================================================

class TeamsPage
    extends StatefulWidget {
  final User user;

  const TeamsPage({
    super.key,
    required this.user,
  });

  @override
  State<TeamsPage> createState() =>
      _TeamsPageState();
}

class _TeamsPageState
    extends State<TeamsPage> {
  List teams = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadTeams();
  }

  Future<void> loadTeams() async {
    setState(() {
      loading = true;
      error = null;
    });

    final result =
        await Api.teams();

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        teams =
            result['teams'] ?? [];
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
        error =
            result['message'] ??
                'Unable to load teams';
      });
    }
  }

  Future<void> createTeam() async {
    final nameController =
        TextEditingController();

    final descriptionController =
        TextEditingController();

    final created =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text('Create Team'),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                appField(
                  'Team Name',
                  nameController,
                  Icons.groups,
                ),
                const SizedBox(
                    height: 12),
                appField(
                  'Description',
                  descriptionController,
                  Icons.description,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child:
                  const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController
                    .text
                    .trim()
                    .isEmpty) {
                  return;
                }

                final result =
                    await Api.createTeam(
                  name:
                      nameController
                          .text
                          .trim(),
                  description:
                      descriptionController
                          .text
                          .trim(),
                  createdBy:
                      widget.user.id,
                );

                if (result['success'] ==
                    true) {
                  if (dialogContext
                      .mounted) {
                    Navigator.pop(
                      dialogContext,
                      true,
                    );
                  }
                } else {
                  if (context.mounted) {
                    showMessage(
                      result[
                              'message'] ??
                          'Team creation failed',
                    );
                  }
                }
              },
              child:
                  const Text('Create'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();

    if (created == true) {
      await loadTeams();

      if (mounted) {
        showMessage(
          'Team created successfully',
        );
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: loadTeams,
      child: ListView(
        padding:
            const EdgeInsets.all(22),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Teams',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: createTeam,
                icon:
                    const Icon(Icons.add),
                label:
                    const Text('Create Team'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (loading)
            const Padding(
              padding:
                  EdgeInsets.all(50),
              child: Center(
                child:
                    CircularProgressIndicator(),
              ),
            )
          else if (error != null)
            ErrorCard(
              message: error!,
              onRetry: loadTeams,
            )
          else if (teams.isEmpty)
            const EmptyCard(
              icon: Icons.groups,
              message:
                  'No teams yet.\nCreate your first team.',
            )
          else
            ...teams.map(
              (team) {
                return Card(
                  margin:
                      const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.all(
                      14,
                    ),
                    leading:
                        const CircleAvatar(
                      child: Icon(
                        Icons.groups,
                      ),
                    ),
                    title: Text(
                      '${team['team_name'] ?? ''}',
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${team['description'] ?? 'No description'}\n'
                      'Team ID: ${team['team_id'] ?? '-'}',
                    ),
                    isThreeLine: true,
                    trailing:
                        const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TeamDetailsPage(
                            team: team,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class TeamDetailsPage
    extends StatelessWidget {
  final Map team;

  const TeamDetailsPage({
    super.key,
    required this.team,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Team Details'),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(22),
        children: [
          const Icon(
            Icons.groups,
            size: 75,
            color: Color(0xff635bff),
          ),
          const SizedBox(height: 15),
          Text(
            '${team['team_name'] ?? ''}',
            textAlign:
                TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25),
          infoTile(
            'Description',
            '${team['description'] ?? 'No description'}',
          ),
          infoTile(
            'Team ID',
            '${team['team_id'] ?? '-'}',
          ),
          infoTile(
            'Created By',
            '${team['created_by'] ?? '-'}',
          ),
          infoTile(
            'Created At',
            '${team['created_at'] ?? '-'}',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MEETINGS
// ============================================================

class MeetingsPage
    extends StatefulWidget {
  final User user;

  const MeetingsPage({
    super.key,
    required this.user,
  });

  @override
  State<MeetingsPage> createState() =>
      _MeetingsPageState();
}

class _MeetingsPageState
    extends State<MeetingsPage> {
  List meetings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadMeetings();
  }

  Future<void> loadMeetings() async {
    final result =
        await Api.meetings();

    if (!mounted) return;

    setState(() {
      meetings =
          result['meetings'] ?? [];
      loading = false;
    });
  }

  Future<void> createMeeting() async {
    final titleController =
        TextEditingController();

    final descriptionController =
        TextEditingController();

    final linkController =
        TextEditingController();

    DateTime start =
        DateTime.now().add(
      const Duration(hours: 1),
    );

    DateTime end =
        start.add(
      const Duration(hours: 1),
    );

    final created =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder:
              (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Schedule Meeting',
              ),
              content: SizedBox(
                width: 500,
                child:
                    SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      appField(
                        'Meeting Title',
                        titleController,
                        Icons.video_call,
                      ),
                      const SizedBox(
                          height: 12),
                      appField(
                        'Description',
                        descriptionController,
                        Icons.description,
                        maxLines: 3,
                      ),
                      const SizedBox(
                          height: 12),
                      appField(
                        'Meeting Link',
                        linkController,
                        Icons.link,
                      ),
                      const SizedBox(
                          height: 12),
                      ListTile(
                        leading:
                            const Icon(
                          Icons.calendar_today,
                        ),
                        title: const Text(
                          'Start',
                        ),
                        subtitle: Text(
                          formatDateTime(
                            start,
                          ),
                        ),
                        onTap: () async {
                          final date =
                              await pickDateTime(
                            context,
                            start,
                          );

                          if (date !=
                              null) {
                            setDialogState(
                              () {
                                start =
                                    date;

                                if (end
                                    .isBefore(
                                  start,
                                )) {
                                  end = start
                                      .add(
                                    const Duration(
                                      hours: 1,
                                    ),
                                  );
                                }
                              },
                            );
                          }
                        },
                      ),
                      ListTile(
                        leading:
                            const Icon(
                          Icons.event,
                        ),
                        title: const Text(
                          'End',
                        ),
                        subtitle: Text(
                          formatDateTime(
                            end,
                          ),
                        ),
                        onTap: () async {
                          final date =
                              await pickDateTime(
                            context,
                            end,
                          );

                          if (date !=
                              null) {
                            setDialogState(
                              () {
                                end =
                                    date;
                              },
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(
                    dialogContext,
                    false,
                  ),
                  child:
                      const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (titleController
                        .text
                        .trim()
                        .isEmpty) {
                      return;
                    }

                    final result =
                        await Api.createMeeting(
                      title:
                          titleController
                              .text
                              .trim(),
                      description:
                          descriptionController
                              .text
                              .trim(),
                      meetingLink:
                          linkController
                              .text
                              .trim(),
                      organizerId:
                          widget.user.id,
                      startTime:
                          formatDateTime(
                        start,
                      ),
                      endTime:
                          formatDateTime(
                        end,
                      ),
                    );

                    if (result['success'] ==
                        true) {
                      if (dialogContext
                          .mounted) {
                        Navigator.pop(
                          dialogContext,
                          true,
                        );
                      }
                    } else {
                      if (context.mounted) {
                        showMessage(
                          result[
                                  'message'] ??
                              'Meeting creation failed',
                        );
                      }
                    }
                  },
                  child:
                      const Text('Schedule'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
    linkController.dispose();

    if (created == true) {
      await loadMeetings();

      if (mounted) {
        showMessage(
          'Meeting scheduled',
        );
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: loadMeetings,
      child: ListView(
        padding:
            const EdgeInsets.all(22),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Meetings',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed:
                    createMeeting,
                icon: const Icon(
                  Icons.add,
                ),
                label:
                    const Text('Schedule'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (loading)
            const Center(
              child:
                  CircularProgressIndicator(),
            )
          else if (meetings.isEmpty)
            const EmptyCard(
              icon:
                  Icons.video_call_outlined,
              message:
                  'No meetings scheduled yet.',
            )
          else
            ...meetings.map(
              (meeting) {
                final link =
                    '${meeting['meeting_link'] ?? ''}';

                return Card(
                  margin:
                      const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.all(
                      14,
                    ),
                    leading:
                        const CircleAvatar(
                      child: Icon(
                        Icons.video_call,
                      ),
                    ),
                    title: Text(
                      '${meeting['title'] ?? ''}',
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${meeting['start_time'] ?? ''}\n'
                      '${meeting['description'] ?? ''}',
                    ),
                    isThreeLine: true,
                    trailing: link.isEmpty
                        ? null
                        : IconButton(
                            tooltip:
                                'Meeting link',
                            icon: const Icon(
                              Icons.link,
                            ),
                            onPressed: () {
                              showDialog(
                                context:
                                    context,
                                builder:
                                    (_) =>
                                        AlertDialog(
                                  title:
                                      const Text(
                                    'Meeting Link',
                                  ),
                                  content:
                                      SelectableText(
                                    link,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () =>
                                              Navigator.pop(
                                        context,
                                      ),
                                      child:
                                          const Text(
                                        'Close',
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ============================================================
// TASKS
// ============================================================

class TasksPage
    extends StatefulWidget {
  final User user;

  const TasksPage({
    super.key,
    required this.user,
  });

  @override
  State<TasksPage> createState() =>
      _TasksPageState();
}

class _TasksPageState
    extends State<TasksPage> {
  List tasks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    final result =
        await Api.tasks();

    if (!mounted) return;

    setState(() {
      tasks =
          result['tasks'] ?? [];
      loading = false;
    });
  }

  Future<void> createTask() async {
    final titleController =
        TextEditingController();

    final descriptionController =
        TextEditingController();

    String priority = 'Medium';

    final created =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder:
              (context, setDialogState) {
            return AlertDialog(
              title:
                  const Text('New Task'),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    appField(
                      'Task',
                      titleController,
                      Icons.task_alt,
                    ),
                    const SizedBox(
                        height: 12),
                    appField(
                      'Description',
                      descriptionController,
                      Icons.description,
                      maxLines: 3,
                    ),
                    const SizedBox(
                        height: 12),
                    DropdownButtonFormField<
                        String>(
                      initialValue:
                          priority,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Priority',
                        border:
                            OutlineInputBorder(),
                      ),
                      items: const [
                        'Low',
                        'Medium',
                        'High',
                        'Critical',
                      ]
                          .map(
                            (value) =>
                                DropdownMenuItem(
                              value: value,
                              child:
                                  Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value !=
                            null) {
                          setDialogState(
                            () {
                              priority =
                                  value;
                            },
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(
                    dialogContext,
                    false,
                  ),
                  child:
                      const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (titleController
                        .text
                        .trim()
                        .isEmpty) {
                      return;
                    }

                    final result =
                        await Api.createTask(
                      title:
                          titleController
                              .text
                              .trim(),
                      description:
                          descriptionController
                              .text
                              .trim(),
                      createdBy:
                          widget.user.id,
                      priority:
                          priority,
                    );

                    if (result['success'] ==
                        true) {
                      if (dialogContext
                          .mounted) {
                        Navigator.pop(
                          dialogContext,
                          true,
                        );
                      }
                    } else {
                      if (context.mounted) {
                        showMessage(
                          result[
                                  'message'] ??
                              'Task creation failed',
                        );
                      }
                    }
                  },
                  child:
                      const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();

    if (created == true) {
      await loadTasks();
    }
  }

  Future<void> completeTask(
      int taskId) async {
    final result =
        await Api.updateTask(
      taskId,
      'Completed',
    );

    if (result['success'] == true) {
      await loadTasks();
    } else {
      showMessage(
        result['message'] ??
            'Unable to update task',
      );
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: loadTasks,
      child: ListView(
        padding:
            const EdgeInsets.all(22),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tasks',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: createTask,
                icon:
                    const Icon(Icons.add),
                label:
                    const Text('New Task'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (loading)
            const Center(
              child:
                  CircularProgressIndicator(),
            )
          else if (tasks.isEmpty)
            const EmptyCard(
              icon:
                  Icons.task_alt,
              message:
                  'No tasks yet.',
            )
          else
            ...tasks.map(
              (task) {
                final completed =
                    '${task['status']}' ==
                        'Completed';

                return Card(
                  margin:
                      const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: ListTile(
                    leading: Checkbox(
                      value: completed,
                      onChanged:
                          completed
                              ? null
                              : (_) {
                                  final id =
                                      int.tryParse(
                                    '${task['task_id']}',
                                  );

                                  if (id !=
                                      null) {
                                    completeTask(
                                      id,
                                    );
                                  }
                                },
                    ),
                    title: Text(
                      '${task['title'] ?? ''}',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        decoration: completed
                            ? TextDecoration
                                .lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      '${task['description'] ?? ''}\n'
                      'Status: ${task['status'] ?? 'Pending'}',
                    ),
                    isThreeLine: true,
                    trailing: Chip(
                      label: Text(
                        '${task['priority'] ?? 'Medium'}',
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ============================================================
// CHATS
// ============================================================

class ChatsPage
    extends StatefulWidget {
  final User user;

  const ChatsPage({
    super.key,
    required this.user,
  });

  @override
  State<ChatsPage> createState() =>
      _ChatsPageState();
}

class _ChatsPageState
    extends State<ChatsPage> {
  List rooms = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadChats();
  }

  Future<void> loadChats() async {
    final result =
        await Api.chats();

    if (!mounted) return;

    setState(() {
      rooms =
          result['chat_rooms'] ??
              result['chats'] ??
              [];
      loading = false;
    });
  }

  Future<void> createChat() async {
    final nameController =
        TextEditingController();

    String roomType = 'Direct';

    final created =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder:
              (context, setDialogState) {
            return AlertDialog(
              title:
                  const Text('New Chat'),
              content: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  appField(
                    'Chat Name',
                    nameController,
                    Icons.chat,
                  ),
                  const SizedBox(
                      height: 12),
                  DropdownButtonFormField<
                      String>(
                    initialValue:
                        roomType,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Chat Type',
                      border:
                          OutlineInputBorder(),
                    ),
                    items: const [
                      'Direct',
                      'Team',
                      'Project',
                      'Meeting',
                    ]
                        .map(
                          (value) =>
                              DropdownMenuItem(
                            value: value,
                            child:
                                Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value !=
                          null) {
                        setDialogState(
                          () {
                            roomType =
                                value;
                          },
                        );
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(
                    dialogContext,
                    false,
                  ),
                  child:
                      const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (nameController
                        .text
                        .trim()
                        .isEmpty) {
                      return;
                    }

                    final result =
                        await Api.createChat(
                      name:
                          nameController
                              .text
                              .trim(),
                      createdBy:
                          widget.user.id,
                      roomType:
                          roomType,
                    );

                    if (result['success'] ==
                        true) {
                      if (dialogContext
                          .mounted) {
                        Navigator.pop(
                          dialogContext,
                          true,
                        );
                      }
                    } else {
                      if (context.mounted) {
                        showMessage(
                          result[
                                  'message'] ??
                              'Chat creation failed',
                        );
                      }
                    }
                  },
                  child:
                      const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();

    if (created == true) {
      await loadChats();
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: loadChats,
      child: ListView(
        padding:
            const EdgeInsets.all(22),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Chats',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: createChat,
                icon:
                    const Icon(Icons.add),
                label:
                    const Text('New Chat'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (loading)
            const Center(
              child:
                  CircularProgressIndicator(),
            )
          else if (rooms.isEmpty)
            const EmptyCard(
              icon: Icons.chat,
              message:
                  'No chats yet.',
            )
          else
            ...rooms.map(
              (room) {
                return Card(
                  margin:
                      const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: ListTile(
                    leading:
                        const CircleAvatar(
                      child: Icon(
                        Icons.chat,
                      ),
                    ),
                    title: Text(
                      '${room['name'] ?? 'Chat'}',
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${room['room_type'] ?? 'Chat'}',
                    ),
                    trailing:
                        const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ChatRoomPage(
                            user: widget.user,
                            room: room,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ============================================================
// CHAT ROOM
// ============================================================

class ChatRoomPage
    extends StatefulWidget {
  final User user;
  final Map room;

  const ChatRoomPage({
    super.key,
    required this.user,
    required this.room,
  });

  @override
  State<ChatRoomPage> createState() =>
      _ChatRoomPageState();
}

class _ChatRoomPageState
    extends State<ChatRoomPage> {
  final controller =
      TextEditingController();

  List messages = [];
  Timer? timer;
  bool sending = false;

  int get roomId =>
      int.tryParse(
        '${widget.room['room_id']}',
      ) ??
      0;

  @override
  void initState() {
    super.initState();

    loadMessages();

    timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        loadMessages();
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  Future<void> loadMessages() async {
    final result =
        await Api.messages(roomId);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        messages =
            result['messages'] ?? [];
      });
    }
  }

  Future<void> sendMessage() async {
    final text =
        controller.text.trim();

    if (text.isEmpty || sending) {
      return;
    }

    setState(() {
      sending = true;
    });

    controller.clear();

    final result =
        await Api.sendMessage(
      roomId: roomId,
      senderId: widget.user.id,
      message: text,
    );

    if (!mounted) return;

    setState(() {
      sending = false;
    });

    if (result['success'] == true) {
      await loadMessages();
    } else {
      controller.text = text;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ??
                'Message could not be sent',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.room['name'] ?? 'Chat'}',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet.\nStart the conversation.',
                      textAlign:
                          TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    reverse: false,
                    padding:
                        const EdgeInsets.all(
                      15,
                    ),
                    itemCount:
                        messages.length,
                    itemBuilder:
                        (context, index) {
                      final message =
                          messages[index];

                      final senderId =
                          int.tryParse(
                        '${message['sender_id']}',
                      );

                      final mine =
                          senderId ==
                              widget.user.id;

                      return Align(
                        alignment: mine
                            ? Alignment
                                .centerRight
                            : Alignment
                                .centerLeft,
                        child: Container(
                          constraints:
                              const BoxConstraints(
                            maxWidth: 320,
                          ),
                          margin:
                              const EdgeInsets
                                  .only(
                            bottom: 10,
                          ),
                          padding:
                              const EdgeInsets
                                  .all(
                            12,
                          ),
                          decoration:
                              BoxDecoration(
                            color: mine
                                ? const Color(
                                    0xff635bff,
                                  )
                                : Theme.of(
                                    context,
                                  )
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              15,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                mine
                                    ? 'You'
                                    : '${message['sender_name'] ?? ''}',
                                style:
                                    TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                  color: mine
                                      ? Colors
                                          .white
                                      : null,
                                ),
                              ),
                              const SizedBox(
                                  height: 4),
                              Text(
                                '${message['message_text'] ?? ''}',
                                style:
                                    TextStyle(
                                  color: mine
                                      ? Colors
                                          .white
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller:
                          controller,
                      textInputAction:
                          TextInputAction.send,
                      onSubmitted:
                          (_) => sendMessage(),
                      decoration:
                          InputDecoration(
                        hintText:
                            'Type a message...',
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                      width: 8),
                  IconButton.filled(
                    onPressed: sending
                        ? null
                        : sendMessage,
                    icon: const Icon(
                      Icons.send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// NOTIFICATIONS
// ============================================================

class NotificationsPage
    extends StatefulWidget {
  final User user;

  const NotificationsPage({
    super.key,
    required this.user,
  });

  @override
  State<NotificationsPage> createState() =>
      _NotificationsPageState();
}

class _NotificationsPageState
    extends State<NotificationsPage> {
  List notifications = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void>
      loadNotifications() async {
    final result =
        await Api.notifications(
      widget.user.id,
    );

    if (!mounted) return;

    setState(() {
      notifications =
          result['notifications'] ??
              [];
      loading = false;
    });
  }

  Future<void> markRead(int id) async {
    await Api.readNotification(id);
    await loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: loadNotifications,
      child: ListView(
        padding:
            const EdgeInsets.all(22),
        children: [
          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 28,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (loading)
            const Center(
              child:
                  CircularProgressIndicator(),
            )
          else if (notifications.isEmpty)
            const EmptyCard(
              icon:
                  Icons.notifications_none,
              message:
                  'No notifications.',
            )
          else
            ...notifications.map(
              (notification) {
                final read =
                    notification[
                            'is_read'] ==
                        true ||
                    '${notification['is_read']}' ==
                        '1';

                return Card(
                  margin:
                      const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: ListTile(
                    leading: Icon(
                      read
                          ? Icons
                              .notifications_none
                          : Icons
                              .notifications_active,
                    ),
                    title: Text(
                      '${notification['title'] ?? ''}',
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${notification['message'] ?? ''}',
                    ),
                    onTap: () {
                      final id =
                          int.tryParse(
                        '${notification['notification_id']}',
                      );

                      if (id != null &&
                          !read) {
                        markRead(id);
                      }
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ============================================================
// PROFILE
// ============================================================

class ProfilePage
    extends StatefulWidget {
  final User user;

  const ProfilePage({
    super.key,
    required this.user,
  });

  @override
  State<ProfilePage> createState() =>
      _ProfilePageState();
}

class _ProfilePageState
    extends State<ProfilePage> {
  final phoneController =
      TextEditingController();

  final locationController =
      TextEditingController();

  final skillsController =
      TextEditingController();

  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    phoneController.dispose();
    locationController.dispose();
    skillsController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    final result =
        await Api.profile(
      widget.user.id,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final user =
          result['user'] ?? {};

      phoneController.text =
          '${user['phone'] ?? ''}';

      locationController.text =
          '${user['location'] ?? ''}';

      skillsController.text =
          '${user['skills'] ?? ''}';
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> saveProfile() async {
    setState(() {
      saving = true;
    });

    final result =
        await Api.updateProfile(
      widget.user.id,
      {
        'name': widget.user.name,
        'phone':
            phoneController.text.trim(),
        'location':
            locationController.text.trim(),
        'skills':
            skillsController.text.trim(),
      },
    );

    if (!mounted) return;

    setState(() {
      saving = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          result['success'] == true
              ? 'Profile updated successfully'
              : result['message'] ??
                  'Profile update failed',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    return ListView(
      padding:
          const EdgeInsets.all(22),
      children: [
        const Text(
          'Profile',
          style: TextStyle(
            fontSize: 28,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(height: 25),
        CircleAvatar(
          radius: 45,
          child: Text(
            initials(widget.user.name),
            style: const TextStyle(
              fontSize: 28,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.user.name,
          textAlign:
              TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        Text(
          widget.user.email,
          textAlign:
              TextAlign.center,
        ),
        const SizedBox(height: 5),
        Text(
          widget.user.role,
          textAlign:
              TextAlign.center,
        ),
        const SizedBox(height: 25),
        appField(
          'Phone',
          phoneController,
          Icons.phone,
        ),
        const SizedBox(height: 14),
        appField(
          'Location',
          locationController,
          Icons.location_on,
        ),
        const SizedBox(height: 14),
        appField(
          'Skills',
          skillsController,
          Icons.star,
          maxLines: 3,
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 50,
          child: FilledButton(
            onPressed:
                saving ? null : saveProfile,
            child: saving
                ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                : const Text(
                    'Save Profile',
                  ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SETTINGS
// ============================================================

class SettingsPage
    extends StatefulWidget {
  final User user;

  const SettingsPage({
    super.key,
    required this.user,
  });

  @override
  State<SettingsPage> createState() =>
      _SettingsPageState();
}

class _SettingsPageState
    extends State<SettingsPage> {
  bool notifications = true;
  bool sound = true;
  bool darkMode = false;

  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final result =
        await Api.settings(
      widget.user.id,
    );

    if (!mounted) return;

    final settings =
        result['settings'] ?? {};

    setState(() {
      notifications =
          settings[
                  'notifications_enabled'] !=
              false;

      sound =
          settings[
                  'sound_enabled'] !=
              false;

      darkMode =
          settings['dark_mode'] == true ||
          '${settings['dark_mode']}' ==
              '1';

      loading = false;
    });
  }

  Future<void> saveSettings() async {
    setState(() {
      saving = true;
    });

    final result =
        await Api.updateSettings(
      widget.user.id,
      {
        'notifications_enabled':
            notifications,
        'sound_enabled': sound,
        'dark_mode': darkMode,
      },
    );

    if (!mounted) return;

    setState(() {
      saving = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          result['success'] == true
              ? 'Settings saved'
              : result['message'] ??
                  'Settings update failed',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    return ListView(
      padding:
          const EdgeInsets.all(22),
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 28,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title:
                    const Text(
                  'Notifications',
                ),
                subtitle:
                    const Text(
                  'Receive workspace notifications',
                ),
                value: notifications,
                onChanged: (value) {
                  setState(() {
                    notifications =
                        value;
                  });
                },
              ),
              SwitchListTile(
                title:
                    const Text(
                  'Sound',
                ),
                subtitle:
                    const Text(
                  'Enable notification sounds',
                ),
                value: sound,
                onChanged: (value) {
                  setState(() {
                    sound = value;
                  });
                },
              ),
              SwitchListTile(
                title:
                    const Text(
                  'Dark Mode',
                ),
                subtitle:
                    const Text(
                  'Use dark appearance',
                ),
                value: darkMode,
                onChanged: (value) {
                  setState(() {
                    darkMode = value;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 50,
          child: FilledButton(
            onPressed: saving
                ? null
                : saveSettings,
            child: saving
                ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                : const Text(
                    'Save Settings',
                  ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// COMMON WIDGETS
// ============================================================

Widget appField(
  String label,
  TextEditingController controller,
  IconData icon, {
  bool obscureText = false,
  Widget? suffix,
  int maxLines = 1,
  TextInputType? keyboardType,
}) {
  return Column(
    crossAxisAlignment:
        CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontWeight:
              FontWeight.w600,
        ),
      ),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        obscureText: obscureText,
        maxLines:
            obscureText ? 1 : maxLines,
        keyboardType: keyboardType,
        decoration:
            InputDecoration(
          prefixIcon:
              Icon(icon),
          suffixIcon: suffix,
          hintText: label,
        ),
      ),
    ],
  );
}

class EmptyCard
    extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyCard({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              icon,
              size: 55,
              color:
                  const Color(0xff635bff),
            ),
            const SizedBox(height: 15),
            Text(
              message,
              textAlign:
                  TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorCard
    extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              size: 55,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign:
                  TextAlign.center,
            ),
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh,
              ),
              label:
                  const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

Widget infoTile(
  String title,
  String value,
) {
  return Card(
    margin:
        const EdgeInsets.only(
      bottom: 10,
    ),
    child: ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight:
              FontWeight.bold,
        ),
      ),
      subtitle: Padding(
        padding:
            const EdgeInsets.only(
          top: 5,
        ),
        child: Text(value),
      ),
    ),
  );
}

String initials(String name) {
  final parts =
      name.trim().split(
    RegExp(r'\s+'),
  );

  if (parts.isEmpty ||
      parts.first.isEmpty) {
    return 'U';
  }

  if (parts.length == 1) {
    return parts.first[0]
        .toUpperCase();
  }

  return '${parts.first[0]}${parts.last[0]}'
      .toUpperCase();
}

String formatDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String formatDateTime(DateTime date) {
  return '${formatDate(date)} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}:00';
}

Future<DateTime?> pickDate(
  BuildContext context,
  DateTime? initial,
) {
  return showDatePicker(
    context: context,
    initialDate:
        initial ?? DateTime.now(),
    firstDate:
        DateTime(2020),
    lastDate:
        DateTime(2100),
  );
}

Future<DateTime?> pickDateTime(
  BuildContext context,
  DateTime initial,
) async {
  final date =
      await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate:
        DateTime.now(),
    lastDate:
        DateTime(2100),
  );

  if (date == null) {
    return null;
  }

  final time =
      await showTimePicker(
    context: context,
    initialTime:
        TimeOfDay.fromDateTime(
      initial,
    ),
  );

  if (time == null) {
    return null;
  }

  return DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
}