import 'package:flutter/material.dart';
import '../../features/home/home_screen.dart';
import '../../features/pantry/pantry_screen.dart';
import '../../features/recipes/recipes_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/ai/screens/ai_main_screen.dart'; 

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const PantryScreen(),
    const RecipesScreen(),
    const AiMainScreen(), 
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: colorScheme.surface,
          indicatorColor: colorScheme.primary.withOpacity(0.2),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined), 
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined), 
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Pantry',
            ),
            NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined), 
              selectedIcon: Icon(Icons.restaurant_menu),
              label: 'Recipes',
            ),
            NavigationDestination(
              icon: Icon(Icons.smart_toy_outlined), 
              selectedIcon: Icon(Icons.smart_toy),
              label: 'AI',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline), 
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
