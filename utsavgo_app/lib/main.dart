
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl =
    'https://lutcdpnwhpwadxttlgze.supabase.co';

const String supabasePublishableKey =
    'sb_publishable_YK1izeYNqP4sqTCiQ9W-7A_SPVD80Iv';

const purple = Color(0xFF7138C8);
const darkPurple = Color(0xFF25143D);

bool isUtsavGoAuthCallback(Uri uri) {
  if (uri.scheme != 'utsavgo' ||
      uri.host != 'login-callback') {
    return false;
  }

  const authParameters = {
    'access_token',
    'code',
    'error',
    'error_code',
    'error_description',
  };

  final fragmentParameters =
      Uri.splitQueryString(uri.fragment);

  return authParameters.any(
    (parameter) =>
        uri.queryParameters.containsKey(parameter) ||
        fragmentParameters.containsKey(parameter),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabasePublishableKey,
    authOptions: FlutterAuthClientOptions(
      detectSessionInUriPredicate: isUtsavGoAuthCallback,
    ),
  );

  runApp(const UtsavGoApp());
}

class UtsavGoApp extends StatelessWidget {
  const UtsavGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UtsavGo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: purple),
        scaffoldBackgroundColor: const Color(0xFFF8F6FC),
      ),
      home: const AuthGate(),
    );
  }
}

// LOGIN SESSION CHECK

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = client.auth.currentSession;

        if (session == null) {
          return const AuthScreen();
        }

        return const HomeScreen();
      },
    );
  }
}

// LOGIN AND SIGNUP SCREEN

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLogin = true;
  bool loading = false;
  bool hidePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final client = Supabase.instance.client;
      final email = emailController.text.trim();
      final password = passwordController.text;

      if (isLogin) {
        await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        showMessage('Login successful!');
      } else {
        final response = await client.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: 'utsavgo://login-callback',
        );

        if (response.session == null) {
          showMessage(
            'Account created! Email inbox check karo aur verification link open karo.',
          );
        } else {
          showMessage('Account created successfully!');
        }
      }
    } on AuthException catch (e) {
      showMessage(e.message);
    } catch (e) {
      showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.celebration,
                    size: 75,
                    color: purple,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'UtsavGo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: darkPurple,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Discover. Connect. Celebrate.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 35),
                  Text(
                    isLogin ? 'Welcome Back!' : 'Create Your Account',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 25),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email enter karo';
                      }
                      if (!value.contains('@') ||
                          !value.contains('.')) {
                        return 'Valid email enter karo';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: hidePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            hidePassword = !hidePassword;
                          });
                        },
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Password minimum 6 characters ka hona chahiye';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: loading ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        foregroundColor: Colors.white,
                      ),
                      child: loading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : Text(
                              isLogin ? 'LOGIN' : 'CREATE ACCOUNT',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: loading
                        ? null
                        : () {
                            setState(() {
                              isLogin = !isLogin;
                            });
                          },
                    child: Text(
                      isLogin
                          ? "New user? Create an account"
                          : 'Already have an account? Login',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// HOME SCREEN

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeContent(),
      const Center(child: Text('Explore Events')),
      const CreateEventScreen(),
      const Center(child: Text('Following')),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.celebration, color: purple),
            SizedBox(width: 8),
            Text(
              'UtsavGo',
              style: TextStyle(
                color: darkPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Following',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// HOME CONTENT - APPROVED EVENTS

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late Future<List<Map<String, dynamic>>> eventsFuture;

  @override
  void initState() {
    super.initState();
    eventsFuture = fetchEvents();
  }

  Future<List<Map<String, dynamic>>> fetchEvents() async {
    final response = await Supabase.instance.client
        .from('events')
        .select()
        .eq('status', 'approved')
        .order('event_date', ascending: true)
        .order('event_time', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> refreshEvents() async {
    setState(() {
      eventsFuture = fetchEvents();
    });
    await eventsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refreshEvents,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Discover Events',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: darkPurple,
            ),
          ),
          const SizedBox(height: 5),
          const Text('Discover. Connect. Celebrate.'),
          const SizedBox(height: 22),
          const Text(
            'Find Something Amazing!',
            style: TextStyle(
              color: purple,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text('Explore what is happening around you.'),
          const SizedBox(height: 25),
          const Text(
            'Nearby Events',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: eventsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Column(
                  children: [
                    const Text(
                      'Events load nahi ho paye.',
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          eventsFuture = fetchEvents();
                        });
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                );
              }

              final events = snapshot.data ?? [];

              if (events.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Abhi koi approved event available nahi hai.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return Column(
                children: events.map((event) {
                  final photoUrl =
                      event['photo_url']?.toString() ?? '';

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EventDetailsScreen(event: event),
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 18),
                      clipBehavior: Clip.antiAlias,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (photoUrl.isNotEmpty)
                            Image.network(
                              photoUrl,
                              width: double.infinity,
                              height: 190,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) {
                                return const SizedBox(
                                  height: 120,
                                  child: Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 45,
                                    ),
                                  ),
                                );
                              },
                            ),
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event['title']?.toString() ??
                                      'Untitled Event',
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                    color: darkPurple,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Category: ${event['category'] ?? ''}',
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Location: ${event['location_text'] ?? ''}',
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Date: ${event['event_date'] ?? ''}',
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Time: ${event['event_time'] ?? ''}',
                                ),
                                const SizedBox(height: 8),
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.touch_app,
                                      size: 17,
                                      color: purple,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Tap to view full details',
                                      style: TextStyle(
                                        color: purple,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// EVENT DETAILS SCREEN

class EventDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> event;

  const EventDetailsScreen({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = event['photo_url']?.toString() ?? '';
    final socialLink = event['social_link']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FC),
      appBar: AppBar(
        title: const Text('Event Details'),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padd