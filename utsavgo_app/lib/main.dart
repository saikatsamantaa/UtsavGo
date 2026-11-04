
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
  final displayNameController = TextEditingController();

  bool isLogin = true;
  bool loading = false;
  bool hidePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    displayNameController.dispose();
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
        final displayName = displayNameController.text.trim();
        if (displayName.isEmpty) {
          showMessage('Apna account name enter karo.');
          return;
        }
        final response = await client.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: 'utsavgo://login-callback',
          data: {'display_name': displayName},
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
                  if (!isLogin) ...[
                    TextFormField(
                      controller: displayNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Your Name / Nickname',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (!isLogin && (value == null || value.trim().isEmpty)) {
                          return 'Apna naam enter karo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
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
      const EventsMapScreen(),
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
            icon: Icon(Icons.map_outlined),
            label: 'Map',
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

// IN-APP MAP WITH APPROVED EVENTS
class EventsMapScreen extends StatefulWidget {
  const EventsMapScreen({super.key});
  @override
  State<EventsMapScreen> createState() => _EventsMapScreenState();
}
class _EventsMapScreenState extends State<EventsMapScreen> {
  final MapController mapController = MapController();
  LatLng? myLocation;
  List<Map<String, dynamic>> events = [];
  bool loading = true;
  String? error;
  @override
  void initState() { super.initState(); loadMap(); }
  Future<void> loadMap() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) throw Exception('Phone ka GPS ON karo.');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Location permission allow karo.');
      }
      final pos = await Geolocator.getCurrentPosition();
      final rows = await Supabase.instance.client.from('events').select('*')
        .eq('status', 'approved').not('latitude', 'is', null).not('longitude', 'is', null);
      if (!mounted) return;
      setState(() {
        myLocation = LatLng(pos.latitude, pos.longitude);
        events = List<Map<String, dynamic>>.from(rows);
        loading = false; error = null;
      });
      mapController.move(myLocation!, 12);
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString(); });
    }
  }
  @override
  Widget build(BuildContext context) {
    final center = myLocation ?? const LatLng(22.5726, 88.3639);
    final markers = <Marker>[
      if (myLocation != null) Marker(point: myLocation!, width: 48, height: 48,
        child: const Icon(Icons.my_location, color: Colors.blue, size: 34)),
      ...events.where((e) => e['latitude'] != null && e['longitude'] != null).map((e) {
        final point = LatLng((e['latitude'] as num).toDouble(), (e['longitude'] as num).toDouble());
        return Marker(point: point, width: 46, height: 46, child: GestureDetector(
          onTap: () => showModalBottomSheet(context: context, isScrollControlled: true,
            builder: (_) => SafeArea(child: ListTile(
              leading: const Icon(Icons.celebration, color: purple),
              title: Text(e['title']?.toString() ?? 'Event'),
              subtitle: Text(e['location_text']?.toString() ?? ''),
              trailing: const Icon(Icons.open_in_new),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailsScreen(event: e)));
              },
            ))),
          child: const Icon(Icons.location_on, color: Colors.red, size: 42),
        ));
      }),
    ];
    return Stack(children: [
      FlutterMap(mapController: mapController, options: MapOptions(initialCenter: center, initialZoom: 5),
        children: [
          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.utsavgo'),
          MarkerLayer(markers: markers),
        ]),
      if (loading) const Center(child: Card(child: Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator()))),
      if (error != null) Positioned(top: 12, left: 12, right: 12, child: Card(
        child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          Text(error!, textAlign: TextAlign.center),
          TextButton(onPressed: () { setState(() { loading = true; }); loadMap(); }, child: const Text('Try Again')),
        ])))),
      Positioned(right: 14, bottom: 18, child: FloatingActionButton(
        heroTag: 'map_refresh', onPressed: () { setState(() { loading = true; }); loadMap(); },
        child: const Icon(Icons.my_location))),
    ]);
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
        .select('*')
        .eq('status', 'approved')
        .order('event_date', ascending: true)
        .order('event_time', ascending: true);

    final events = List<Map<String, dynamic>>.from(response);

    // GPS ke through nearby events ko distance ke hisaab se sort/filter karo.
    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return events;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return events;
      }

      final position = await Geolocator.getCurrentPosition();
      final nearby = <Map<String, dynamic>>[];

      for (final event in events) {
        final lat = event['latitude'];
        final lng = event['longitude'];
        if (lat == null || lng == null) continue;

        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          (lat as num).toDouble(),
          (lng as num).toDouble(),
        );

        // Nearby radius: 50 km. Distance app ke andar use hoti hai.
        if (distance <= 50000) {
          event['_distance_meters'] = distance;
          nearby.add(event);
        }
      }

      nearby.sort((a, b) =>
          (a['_distance_meters'] as double)
              .compareTo(b['_distance_meters'] as double));

      // Agar 50 km ke andar koi GPS-tagged event nahi mila,
      // to approved events ko blank screen ki jagah dikhao.
      // Isse purane ya bina coordinates wale events bhi visible rahenge.
      if (nearby.isEmpty) return events;

      return nearby;
    } catch (_) {
      // GPS unavailable ho to approved events ko hide mat karo.
      return events;
    }
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
                                  'Posted by: ${event['profiles'] is Map ? (event['profiles']['display_name'] ?? 'UtsavGo User') : 'UtsavGo User'}',
                                  style: const TextStyle(
                                    color: purple,
                                    fontWeight: FontWeight.w600,
                                  ),
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
        padding: const EdgeInsets.all(18),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: photoUrl.isNotEmpty
                ? Image.network(
                    photoUrl,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox(
                      height: 200,
                      child: Center(
                        child: Icon(Icons.broken_image, size: 60),
                      ),
                    ),
                  )
                : const SizedBox(
                    height: 200,
                    child: Center(
                      child: Icon(Icons.celebration, size: 60),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          Text(
            event['title']?.toString() ?? 'Event',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: darkPurple,
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text((event['profiles'] is Map
                  ? (event['profiles']['display_name'] ?? 'UtsavGo User').toString()
                  : 'UtsavGo User')),
              subtitle: const Text('Event Organizer'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final creatorId = event['created_by']?.toString() ?? '';
                if (creatorId.isNotEmpty) {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => OrganizerProfileScreen(userId: creatorId),
                  ));
                }
              },
            ),
          ),
          if ((event['created_by']?.toString() ?? '').isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: FollowButton(userId: event['created_by'].toString()),
            ),
          const SizedBox(height: 15),
          detailRow(Icons.category, 'Category', event['category']),
          detailRow(
            Icons.location_on,
            'Location',
            event['location_text'],
          ),
          detailRow(Icons.place, 'Landmark', event['landmark']),
          if ((event['landmark']?.toString().trim() ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: () async {
                final landmark = event['landmark'].toString().trim();
                await Clipboard.setData(ClipboardData(text: landmark));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Landmark copied!')),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Landmark'),
            ),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final latitude = event['latitude'];
              final longitude = event['longitude'];
              final location = event['location_text']?.toString() ?? '';
              final landmark = event['landmark']?.toString() ?? '';

              final String query;
              if (latitude != null && longitude != null) {
                query = '$latitude,$longitude';
              } else {
                query = Uri.encodeComponent('$location $landmark'.trim());
              }

              if (query.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Event location is not available.')),
                );
                return;
              }

              final uri = Uri.parse(
                'https://www.google.com/maps/search/?api=1&query=$query',
              );
              final opened = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
              if (!opened && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Google Maps open nahi ho paya.')),
                );
              }
            },
            icon: const Icon(Icons.map),
            label: const Text('Open in Google Maps'),
          ),
          detailRow(
            Icons.calendar_month,
            'Date',
            event['event_date'],
          ),
          detailRow(
            Icons.access_time,
            'Time',
            event['event_time'],
          ),
          const SizedBox(height: 15),
          const Text(
            'About This Event',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: darkPurple,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            (event['description'] ?? 'No description available.')
                .toString(),
            style: const TextStyle(fontSize: 16),
          ),
          if (socialLink.isNotEmpty) ...[
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.tryParse(socialLink);
                if (uri != null &&
                    (uri.scheme == 'https' || uri.scheme == 'http')) {
                  await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
              icon: const Icon(Icons.link),
              label: const Text('Open Event Link'),
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(15),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget detailRow(IconData icon, String label, dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: purple),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$label: $text',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// PROFILE AND EVENT HISTORY

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  bool loading = true;
  bool saving = false;
  Map<String, dynamic> profile = {};
  int followers = 0;
  int following = 0;
  List<Map<String, dynamic>> postedEvents = [];

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser!;
      final row = await client.from('profiles').select('*').eq('id', user.id).maybeSingle();
      profile = row ?? {};
      nameController.text = profile['display_name']?.toString() ??
          user.userMetadata?['display_name']?.toString() ?? '';
      usernameController.text = profile['username']?.toString() ?? '';
      final followerRows = await client.from('user_follows').select('follower_id').eq('following_id', user.id);
      final followingRows = await client.from('user_follows').select('following_id').eq('follower_id', user.id);
      followers = (followerRows as List).length;
      following = (followingRows as List).length;
      final eventRows = await client.from('events').select('*')
          .eq('created_by', user.id).eq('status', 'approved')
          .order('created_at', ascending: false);
      postedEvents = List<Map<String, dynamic>>.from(eventRows);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile load nahi hua: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> saveProfile() async {
    final name = nameController.text.trim();
    final username = usernameController.text.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();
    if (name.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name aur username dono bharo.')));
      return;
    }
    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(username)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username 3-20 characters ka ho: a-z, 0-9 ya underscore.')));
      return;
    }
    setState(() => saving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'display_name': name,
        'username': username,
        'updated_at': DateTime.now().toIso8601String(),
      });
      await Supabase.instance.client.auth.updateUser(UserAttributes(data: {'display_name': name}));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile save ho gaya!')));
        await loadProfile();
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        final duplicate = e.code == '23505' || e.message.toLowerCase().contains('duplicate');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
          duplicate ? 'Ye username pehle se kisi ne le rakha hai. Dusra username choose karo.' : 'Profile save nahi hua: ${e.message}',
        )));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile save nahi hua: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: loadProfile,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const SizedBox(height: 10),
          Row(children: [
            const CircleAvatar(radius: 42, backgroundColor: Color(0xFFE9DDF8),
              child: Icon(Icons.person, size: 48, color: purple)),
            const SizedBox(width: 24),
            Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _profileStat(postedEvents.length, 'Events'),
              _profileStat(followers, 'Followers'),
              _profileStat(following, 'Following'),
            ])),
          ]),
          const SizedBox(height: 14),
          Text(nameController.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text('@${usernameController.text}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 5),
          Text(user?.email ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 22),
          TextField(controller: nameController, decoration: const InputDecoration(
            labelText: 'Your Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
          const SizedBox(height: 12),
          TextField(controller: usernameController, autocorrect: false,
            textCapitalization: TextCapitalization.none,
            decoration: const InputDecoration(labelText: 'Unique Username (without @)',
              prefixText: '@', border: OutlineInputBorder(), prefixIcon: Icon(Icons.alternate_email))),
          const SizedBox(height: 10),
          const Text('3-20 characters • lowercase letters, numbers and _ only',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: saving ? null : saveProfile,
            style: ElevatedButton.styleFrom(backgroundColor: purple, foregroundColor: Colors.white),
            child: Text(saving ? 'Saving...' : 'Edit / Save Profile')),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyEventsScreen())),
            icon: const Icon(Icons.history), label: const Text('My Events / History')),
          const SizedBox(height: 22),
          const Text('My Events', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (postedEvents.isEmpty) const Text('Abhi koi approved event post nahi kiya.')
          else GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            itemCount: postedEvents.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1),
            itemBuilder: (context, index) {
              final event = postedEvents[index];
              final photo = event['photo_url']?.toString() ?? '';
              return InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => EventDetailsScreen(event: event))),
                child: Stack(fit: StackFit.expand, children: [
                  photo.isNotEmpty ? Image.network(photo, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE9DDF8), child: Icon(Icons.celebration)))
                    : const ColoredBox(color: Color(0xFFE9DDF8), child: Icon(Icons.celebration)),
                  Align(alignment: Alignment.bottomCenter, child: Container(
                    color: Colors.black54, width: double.infinity, padding: const EdgeInsets.all(6),
                    child: Text(event['title']?.toString() ?? 'Event',
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                ]),
              );
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async { try { await Supabase.instance.client.auth.signOut(); } catch (_) {} },
            icon: const Icon(Icons.logout), label: const Text('Logout'),
            style: ElevatedButton.styleFrom(backgroundColor: purple, foregroundColor: Colors.white)),
        ],
      ),
    );
  }

  Widget _profileStat(int count, String label) => Column(children: [
    Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
    Text(label, style: const TextStyle(fontSize: 12)),
  ]);
}

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = loadEvents();
  }

  Future<List<Map<String, dynamic>>> loadEvents() async {
    final user = Supabase.instance.client.auth.currentUser!;
    final rows = await Supabase.instance.client.from('events')
        .select().eq('created_by', user.id).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Color statusColor(String status) {
    if (status == 'approved') return Colors.green;
    if (status == 'rejected') return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Events / History')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('History load nahi hui: ${snapshot.error}'));
          }
          final events = snapshot.data ?? [];
          if (events.isEmpty) return const Center(child: Text('Abhi aapne koi event submit nahi kiya.'));
          return RefreshIndicator(
            onRefresh: () async => setState(() => future = loadEvents()),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(14),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final e = events[index];
                final status = (e['status'] ?? 'pending').toString();
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: status == 'approved'
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EventDetailsScreen(event: e),
                              ),
                            );
                          }
                        : null,
                    child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e['title']?.toString() ?? 'Event',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Status: ${status.toUpperCase()}',
                          style: TextStyle(color: statusColor(status), fontWeight: FontWeight.bold)),
                      if (status == 'pending') const Text('Admin review ka wait ho raha hai.'),
                      if (status == 'approved') const Text('Aapka event approve ho gaya hai.'),
                      if (status == 'rejected') ...[
                        const SizedBox(height: 6),
                        Text('Reject reason: ${e['rejection_reason']?.toString().trim().isNotEmpty == true ? e['rejection_reason'] : 'Reason abhi available nahi hai.'}',
                            style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 5),
                      Text('Submitted: ${e['created_at'] ?? ''}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      if (status == 'approved') ...[
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Icon(Icons.touch_app, size: 16, color: purple),
                            SizedBox(width: 5),
                            Text('Tap to view event details',
                                style: TextStyle(color: purple, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ]),
                  ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = loadFollowing();
  }

  Future<List<Map<String, dynamic>>> loadFollowing() async {
    final uid = Supabase.instance.client.auth.currentUser!.id;
    final rows = await Supabase.instance.client.from('user_follows')
        .select('following_id, profiles!user_follows_following_id_fkey(id, display_name)')
        .eq('follower_id', uid).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Following load nahi hui: ${snapshot.error}'));
        final rows = snapshot.data ?? [];
        if (rows.isEmpty) return const Center(child: Text('Aap abhi kisi ko follow nahi kar rahe.'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final profile = Map<String, dynamic>.from(rows[index]['profiles'] ?? {});
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(profile['display_name']?.toString() ?? 'UtsavGo User'),
              subtitle: const Text('Following'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => OrganizerProfileScreen(userId: profile['id'].toString()),
              )),
            );
          },
        );
      },
    );
  }
}

class FollowButton extends StatefulWidget {
  final String userId;
  const FollowButton({super.key, required this.userId});

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool following = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    checkFollow();
  }

  Future<void> checkFollow() async {
    final me = Supabase.instance.client.auth.currentUser?.id;
    if (me == null || me == widget.userId) {
      if (mounted) setState(() => loading = false);
      return;
    }
    try {
      final row = await Supabase.instance.client.from('user_follows')
          .select('follower_id').eq('follower_id', me)
          .eq('following_id', widget.userId).maybeSingle();
      if (mounted) setState(() { following = row != null; loading = false; });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> toggle() async {
    final me = Supabase.instance.client.auth.currentUser?.id;
    if (me == null) return;
    setState(() => loading = true);
    try {
      if (following) {
        await Supabase.instance.client.from('user_follows')
            .delete().eq('follower_id', me).eq('following_id', widget.userId);
      } else {
        await Supabase.instance.client.from('user_follows').insert({
          'follower_id': me, 'following_id': widget.userId,
        });
      }
      if (mounted) setState(() { following = !following; loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Follow update nahi hua: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = Supabase.instance.client.auth.currentUser?.id;
    if (me == widget.userId) return const SizedBox.shrink();
    return OutlinedButton(
      onPressed: loading ? null : toggle,
      child: Text(loading ? 'Please wait...' : following ? 'Following' : 'Follow'),
    );
  }
}

class OrganizerProfileScreen extends StatefulWidget {
  final String userId;
  const OrganizerProfileScreen({super.key, required this.userId});
  @override
  State<OrganizerProfileScreen> createState() => _OrganizerProfileScreenState();
}

class _OrganizerProfileScreenState extends State<OrganizerProfileScreen> {
  late Future<Map<String, dynamic>?> profileFuture;
  @override
  void initState() { super.initState(); profileFuture = loadProfile(); }
  Future<Map<String, dynamic>?> loadProfile() async {
    return await Supabase.instance.client.from('profiles')
      .select('*').eq('id', widget.userId).maybeSingle();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Profile load nahi hua: ${snapshot.error}'));
          final profile = snapshot.data;
          if (profile == null) return const Center(child: Text('Profile nahi mila.'));
          return PublicProfileContent(userId: widget.userId, profile: profile);
        },
      ),
    );
  }
}

class PublicProfileContent extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> profile;
  const PublicProfileContent({super.key, required this.userId, required this.profile});
  @override
  State<PublicProfileContent> createState() => _PublicProfileContentState();
}

class _PublicProfileContentState extends State<PublicProfileContent> {
  late Future<List<dynamic>> dataFuture;
  @override
  void initState() { super.initState(); dataFuture = loadData(); }
  Future<List<dynamic>> loadData() async {
    final client = Supabase.instance.client;
    final followers = await client.from('user_follows').select('follower_id').eq('following_id', widget.userId);
    final following = await client.from('user_follows').select('following_id').eq('follower_id', widget.userId);
    final events = await client.from('events').select('*').eq('created_by', widget.userId)
      .eq('status', 'approved').order('created_at', ascending: false);
    return [followers, following, events];
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Profile details load nahi hue: ${snapshot.error}'));
        final data = snapshot.data!;
        final events = List<Map<String, dynamic>>.from(data[2]);
        return ListView(padding: const EdgeInsets.all(18), children: [
          Row(children: [
            const CircleAvatar(radius: 42, child: Icon(Icons.person, size: 48)),
            const SizedBox(width: 22),
            Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _profileStat(events.length, 'Events'),
              _profileStat((data[0] as List).length, 'Followers'),
              _profileStat((data[1] as List).length, 'Following'),
            ])),
          ]),
          const SizedBox(height: 14),
          Text(widget.profile['display_name']?.toString() ?? 'UtsavGo User',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          Text('@${widget.profile['username'] ?? 'username'}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 14),
          FollowButton(userId: widget.userId),
          const SizedBox(height: 20),
          const Text('Events', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (events.isEmpty) const Text('Is user ne abhi koi approved event post nahi kiya.')
          else GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemBuilder: (context, i) => InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailsScreen(event: events[i]))),
              child: Image.network(events[i]['photo_url']?.toString() ?? '', fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE9DDF8), child: Icon(Icons.celebration))),
            ),
          ),
        ]);
      },
    );
  }
}

Widget _profileStat(int count, String label) => Column(children: [
  Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
  Text(label, style: const TextStyle(fontSize: 12)),
]);

// CREATE EVENT SCREEN

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() =>
      _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final landmarkController = TextEditingController();
  final descriptionController = TextEditingController();
  final socialController = TextEditingController();

  final categories = [
    'Puja',
    'Concert',
    'Sports',
    'Fair',
    'Expo',
    'Education',
    'Business',
    'Political',
    'Dance Academy',
  ];

  String category = 'Puja';
  XFile? eventPhoto;
  DateTime? eventDate;
  TimeOfDay? eventTime;
  LatLng? selectedLocation;
  bool gettingLocation = false;
  bool submitting = false;

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    landmarkController.dispose();
    descriptionController.dispose();
    socialController.dispose();
    super.dispose();
  }

  InputDecoration decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: purple),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Future<void> pickPhoto(ImageSource source) async {
    try {
      final photo = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (photo != null && mounted) {
        setState(() => eventPhoto = photo);
      }
    } catch (e) {
      showMessage('Photo select nahi ho payi.');
    }
  }

  Future<void> showPhotoOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                pickPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                pickPhoto(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> getCurrentLocation() async {
    setState(() => gettingLocation = true);

    try {
      final enabled =
          await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        showMessage('Phone ka Location/GPS ON karo.');
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        showMessage('Location permission nahi mili.');
        return;
      }

      final position = await Geolocator.getCurrentPosition();

      if (!mounted) return;

      setState(() {
        selectedLocation = LatLng(
          position.latitude,
          position.longitude,
        );
      });

      locationController.text =
          '${position.latitude}, ${position.longitude}';

      showMessage('Current location select ho gayi.');
    } catch (e) {
      showMessage('Location nahi mil payi. Dobara try karo.');
    } finally {
      if (mounted) {
        setState(() => gettingLocation = false);
      }
    }
  }

  Future<void> chooseMapLocation() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLocation: selectedLocation,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        selectedLocation = result;
        locationController.text =
            '${result.latitude}, ${result.longitude}';
      });
    }
  }

  Future<void> chooseDate() async {
    final now = DateTime.now();

    final result = await showDatePicker(
      context: context,
      initialDate: eventDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );

    if (result != null && mounted) {
      setState(() => eventDate = result);
    }
  }

  Future<void> chooseTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: eventTime ?? TimeOfDay.now(),
    );

    if (result != null && mounted) {
      setState(() => eventTime = result);
    }
  }

  Future<void> copyText(String value) async {
    if (value.trim().isEmpty) {
      showMessage('Pehle location enter karo.');
      return;
    }

    await Clipboard.setData(ClipboardData(text: value));
    showMessage('Copied!');
  }

  Future<void> openMaps() async {
    Uri uri;

    if (selectedLocation != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query='
        '${selectedLocation!.latitude},${selectedLocation!.longitude}',
      );
    } else if (locationController.text.trim().isNotEmpty) {
      final query = Uri.encodeComponent(
        '${locationController.text} ${landmarkController.text}',
      );

      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$query',
      );
    } else {
      showMessage('Pehle location enter karo.');
      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        showMessage('Google Maps open nahi ho paya.');
      }
    } catch (e) {
      showMessage('Google Maps open nahi ho paya.');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // SUBMIT EVENT TO SUPABASE

  Future<void> submitEvent() async {
    if (submitting) return;

    if (!formKey.currentState!.validate()) return;

    if (eventPhoto == null) {
      showMessage('Event ki ek photo upload karo.');
      return;
    }

    if (eventDate == null || eventTime == null) {
      showMessage('Event ki date aur time select karo.');
      return;
    }

    if (locationController.text.trim().isEmpty) {
      showMessage('Event ki location enter karo.');
      return;
    }

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      showMessage('Pehle login karo.');
      return;
    }

    setState(() => submitting = true);

    try {
      showMessage('Event upload ho raha hai. Please wait...');

      final extension =
          eventPhoto!.name.split('.').last.toLowerCase();

      final storagePath =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$extension';

      final contentType = extension == 'png'
          ? 'image/png'
          : extension == 'webp'
              ? 'image/webp'
              : 'image/jpeg';

      await client.storage
          .from('event-photos')
          .uploadBinary(
            storagePath,
            await eventPhoto!.readAsBytes(),
            fileOptions: FileOptions(
              contentType: contentType,
            ),
          );

      final photoUrl = client.storage
          .from('event-photos')
          .getPublicUrl(storagePath);

      final date =
          '${eventDate!.year.toString().padLeft(4, '0')}-'
          '${eventDate!.month.toString().padLeft(2, '0')}-'
          '${eventDate!.day.toString().padLeft(2, '0')}';

      final time =
          '${eventTime!.hour.toString().padLeft(2, '0')}:'
          '${eventTime!.minute.toString().padLeft(2, '0')}:00';

      await client.from('events').insert({
        'title': nameController.text.trim(),
        'category': category,
        'location_text': locationController.text.trim(),
        'landmark': landmarkController.text.trim().isEmpty
            ? null
            : landmarkController.text.trim(),
        'event_date': date,
        'event_time': time,
        'description': descriptionController.text.trim(),
        'social_link': socialController.text.trim().isEmpty
            ? null
            : socialController.text.trim(),
        'latitude': selectedLocation?.latitude,
        'longitude': selectedLocation?.longitude,
        'photo_url': photoUrl,
        'status': 'pending',
        'created_by': user.id,
      });

      if (!mounted) return;

      showMessage(
        'Event successfully submit ho gaya! Admin approval ka wait karo.',
      );

      nameController.clear();
      locationController.clear();
      landmarkController.clear();
      descriptionController.clear();
      socialController.clear();

      setState(() {
        eventPhoto = null;
        eventDate = null;
        eventTime = null;
        selectedLocation = null;
        category = 'Puja';
      });
    } on StorageException catch (e) {
      showMessage('Photo upload error: ${e.message}');
    } on PostgrestException catch (e) {
      showMessage('Database error: ${e.message}');
    } catch (e) {
      showMessage('Event submit nahi hua. Dobara try karo.');
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Create an Event',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: darkPurple,
            ),
          ),
          const SizedBox(height: 6),
          const Text('Share an event happening near you.'),
          const SizedBox(height: 22),
          const Text(
            'Event Photo (1 photo only)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: showPhotoOptions,
            child: Container(
              height: 175,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: eventPhoto == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          size: 42,
                          color: purple,
                        ),
                        SizedBox(height: 8),
                        Text('Add one event photo'),
                        Text(
                          'Gallery or Camera • No videos',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(eventPhoto!.path),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.red,
                              ),
                            );
                          },
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton.filled(
                            tooltip: 'Remove photo',
                            onPressed: () {
                              setState(() => eventPhoto = null);
                            },
                            icon: const Icon(Icons.delete),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: nameController,
            decoration: decoration('Event name', Icons.celebration),
            validator: (v) =>
                v == null || v.trim().isEmpty
                    ? 'Enter event name'
                    : null,
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: category,
            decoration: decoration('Category', Icons.category),
            items: categories.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => category = value);
              }
            },
          ),
          const SizedBox(height: 22),
          const Text(
            'Event Location',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: gettingLocation ? null : getCurrentLocation,
            icon: const Icon(Icons.my_location),
            label: Text(
              gettingLocation
                  ? 'Getting location...'
                  : 'Use Current Location',
            ),
          ),
          OutlinedButton.icon(
            onPressed: chooseMapLocation,
            icon: const Icon(Icons.map_outlined),
            label: const Text('Select Location on Map'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: locationController,
            decoration: decoration(
              'Location / Area (manual entry allowed)',
              Icons.location_on,
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty
                    ? 'Enter location'
                    : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: landmarkController,
            decoration: decoration(
              'Landmark (manual entry)',
              Icons.place,
            ),
          ),
          const SizedBox(height: 10),
          const SizedBox(height: 22),
          const Text(
            'Event Date & Time',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: chooseDate,
            icon: const Icon(Icons.calendar_month),
            label: Text(
              eventDate == null
                  ? 'Select Event Date'
                  : '${eventDate!.day}/${eventDate!.month}/${eventDate!.year}',
            ),
          ),
          OutlinedButton.icon(
            onPressed: chooseTime,
            icon: const Icon(Icons.access_time),
            label: Text(
              eventTime == null
                  ? 'Select Event Time'
                  : eventTime!.format(context),
            ),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: descriptionController,
            maxLines: 4,
            decoration: decoration(
              'Event Description',
              Icons.description,
            ),
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: socialController,
            decoration: decoration(
              'Social Link (Optional)',
              Icons.link,
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 25),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: submitting ? null : submitEvent,
              icon: submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(
                submitting ? 'Submitting...' : 'Submit Event',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Events require admin approval before appearing publicly.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// MAP PICKER

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const MapPickerScreen({
    super.key,
    this.initialLocation,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng currentPoint;

  @override
  void initState() {
    super.initState();
    currentPoint =
        widget.initialLocation ?? const LatLng(22.5726, 88.3639);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Event Location'),
        backgroundColor: Colors.white,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: currentPoint,
          initialZoom: 13,
          onTap: (tapPosition, point) {
            setState(() => currentPoint = point);
          },
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.utsavgo',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: currentPoint,
                width: 50,
                height: 50,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 45,
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(15),
            ),
            onPressed: () {
              Navigator.pop(context, currentPoint);
            },
            child: const Text('Confirm Location'),
          ),
        ),
      ),
    );
  }
}
