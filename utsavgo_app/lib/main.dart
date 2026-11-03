
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabasePublishableKey,
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

// HOME CONTENT

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: const [
        Text(
          'Discover Events',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
            color: darkPurple,
          ),
        ),
        SizedBox(height: 5),
        Text('Discover. Connect. Celebrate.'),
        SizedBox(height: 22),
        Text(
          'Find Something Amazing!',
          style: TextStyle(
            color: purple,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Text('Explore what is happening around you.'),
        SizedBox(height: 25),
        Text(
          'Nearby Events',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Text('Your nearby events will appear here.'),
      ],
    );
  }
}

// PROFILE AND LOGOUT

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(
          Icons.account_circle,
          size: 90,
          color: purple,
        ),
        const SizedBox(height: 15),
        const Text(
          'My Profile',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          user?.email ?? 'User',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: () async {
            try {
              await Supabase.instance.client.auth.signOut();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logout nahi ho paya.'),
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(15),
          ),
        ),
      ],
    );
  }
}

// CREATE EVENT SCREEN

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
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
      final enabled = await Geolocator.isLocationServiceEnabled();

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

  void submitEvent() {
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

    showMessage(
      'Login successful! Online event submission next step mein connect hoga.',
    );
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
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => copyText(locationController.text),
                icon: const Icon(Icons.copy),
                label: const Text('Copy Location'),
              ),
              OutlinedButton.icon(
                onPressed: () => copyText(landmarkController.text),
                icon: const Icon(Icons.copy),
                label: const Text('Copy Landmark'),
              ),
              OutlinedButton.icon(
                onPressed: openMaps,
                icon: const Icon(Icons.map),
                label: const Text('Open Maps'),
              ),
            ],
          ),
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
              onPressed: submitEvent,
              icon: const Icon(Icons.send),
              label: const Text(
                'Submit Event',
                style: TextStyle(fontSize: 16),
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
