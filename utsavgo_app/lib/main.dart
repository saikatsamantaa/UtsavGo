
import 'package:flutter/material.dart';

void main() {
  runApp(const UtsavGoApp());
}

const purple = Color(0xFF7138C8);
const darkPurple = Color(0xFF25143D);
const backgroundColor = Color(0xFFF8F6FC);

class UtsavGoApp extends StatelessWidget {
  const UtsavGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UtsavGo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: purple,
          primary: purple,
        ),
        scaffoldBackgroundColor: backgroundColor,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  int selectedCategory = 0;

  final List<String> categories = [
    'All',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.celebration, color: purple, size: 30),
            SizedBox(width: 8),
            Text(
              'UtsavGo',
              style: TextStyle(
                color: darkPurple,
                fontWeight: FontWeight.bold,
                fontSize: 23,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none,
              color: darkPurple,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          buildHome(),
          const Center(child: Text('Explore Events')),
          const CreateEventScreen(),
          const Center(child: Text('Following')),
          const Center(child: Text('Your Profile')),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFEDE2FC),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
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

  Widget buildHome() {
    return ListView(
      padding: const EdgeInsets.all(16),
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
        const Text(
          'Discover. Connect. Celebrate.',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 20),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search events, places...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [purple, Color(0xFF9A62E8)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Find Something Amazing!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Explore what is happening around you.',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 12),
              Icon(Icons.celebration, color: Colors.white, size: 38),
            ],
          ),
        ),
        const SizedBox(height: 25),
        const Text(
          'Categories',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final selected = selectedCategory == index;
              return ChoiceChip(
                label: Text(categories[index]),
                selected: selected,
                onSelected: (_) {
                  setState(() => selectedCategory = index);
                },
                selectedColor: purple,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 25),
        const Text(
          'Nearby Events',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        eventCard(
          'Durga Puja Celebration',
          'Kolkata',
          '25 October 2026',
          Icons.temple_hindu,
        ),
        eventCard(
          'Live Music Concert',
          'Kolkata',
          '28 October 2026',
          Icons.music_note,
        ),
        eventCard(
          'Local Sports Tournament',
          'Paschim Medinipur',
          '02 November 2026',
          Icons.sports_cricket,
        ),
      ],
    );
  }

  Widget eventCard(
    String title,
    String location,
    String date,
    IconData eventIcon,
  ) {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              height: 65,
              width: 65,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE2FC),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(eventIcon, size: 32, color: purple),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    location,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    date,
                    style: const TextStyle(
                      color: purple,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final eventNameController = TextEditingController();
  final locationController = TextEditingController();
  final landmarkController = TextEditingController();
  final descriptionController = TextEditingController();
  final socialLinkController = TextEditingController();

  final List<String> eventCategories = [
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

  String selectedCategory = 'Puja';
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void dispose() {
    eventNameController.dispose();
    locationController.dispose();
    landmarkController.dispose();
    descriptionController.dispose();
    socialLinkController.dispose();
    super.dispose();
  }

  Future<void> chooseDate() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );

    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  Future<void> chooseTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() => selectedTime = time);
    }
  }

  void submitEvent() {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select event date and time.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Form completed! Database connection will be added next.',
        ),
      ),
    );
  }

  InputDecoration fieldDecoration(
    String label,
    IconData icon, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: purple),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: purple, width: 1.5),
      ),
    );
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
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
          const Text(
            'Share something exciting happening near you.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: eventNameController,
            decoration: fieldDecoration(
              'Event name',
              Icons.celebration,
              hint: 'Enter event name',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter event name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: selectedCategory,
            decoration: fieldDecoration(
              'Event category',
              Icons.category_outlined,
            ),
            items: eventCategories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedCategory = value);
              }
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: locationController,
            decoration: fieldDecoration(
              'Location / Area',
              Icons.location_on_outlined,
              hint: 'Example: Kolkata',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter location';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: landmarkController,
            decoration: fieldDecoration(
              'Landmark',
              Icons.place_outlined,
              hint: 'Example: Near railway station',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a landmark';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          InkWell(
            onTap: chooseDate,
            child: InputDecorator(
              decoration: fieldDecoration(
                'Event date',
                Icons.calendar_month,
              ),
              child: Text(
                selectedDate == null
                    ? 'Select event date'
                    : formatDate(selectedDate!),
                style: TextStyle(
                  color: selectedDate == null
                      ? Colors.grey.shade600
                      : Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          InkWell(
            onTap: chooseTime,
            child: InputDecorator(
              decoration: fieldDecoration(
                'Event time',
                Icons.access_time,
              ),
              child: Text(
                selectedTime == null
                    ? 'Select event time'
                    : selectedTime!.format(context),
                style: TextStyle(
                  color: selectedTime == null
                      ? Colors.grey.shade600
                      : Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: descriptionController,
            maxLines: 4,
            decoration: fieldDecoration(
              'Event description',
              Icons.description_outlined,
              hint: 'Tell people about this event',
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: socialLinkController,
            keyboardType: TextInputType.url,
            decoration: fieldDecoration(
              'Social media link (optional)',
              Icons.link,
              hint: 'Instagram, Facebook, etc.',
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: submitEvent,
              icon: const Icon(Icons.send),
              label: const Text(
                'Submit Event',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Note: Events will need admin approval before appearing publicly.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }
}
