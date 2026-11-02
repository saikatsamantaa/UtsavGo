
import 'package:flutter/material.dart';

void main() {
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7138C8),
          primary: const Color(0xFF7138C8),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F6FC),
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

  final List<String> categories = [
    'All',
    'Puja',
    'Concert',
    'Sports',
    'Fair',
    'Expo',
    'Education',
  ];

  int selectedCategory = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Color(0xFF7138C8), size: 30),
            SizedBox(width: 8),
            Text(
              'UtsavGo',
              style: TextStyle(
                color: Color(0xFF25143D),
                fontWeight: FontWeight.bold,
                fontSize: 23,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none,
                color: Color(0xFF25143D)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          buildHome(),
          const Center(child: Text('Explore Events')),
          const Center(child: Text('Add New Event')),
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
            color: Color(0xFF25143D),
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
              colors: [Color(0xFF7138C8), Color(0xFF9A62E8)],
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
                selectedColor: const Color(0xFF7138C8),
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
              child: Icon(
                eventIcon,
                size: 32,
                color: const Color(0xFF7138C8),
              ),
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
                  Text(location,
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 5),
                  Text(date,
                      style: const TextStyle(
                        color: Color(0xFF7138C8),
                        fontSize: 12,
                      )),
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
