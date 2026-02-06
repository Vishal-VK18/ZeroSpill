import 'package:flutter/material.dart';
import '../../shared/services/pantry_service.dart';
import '../../shared/services/notification_service.dart';
import '../../shared/services/recipe_service.dart';
import '../../shared/models/recipe.dart';
import '../pantry/pantry_screen.dart';
import '../pantry/add_item_screen.dart';
import '../recipes/recipes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PantryService _pantryService = PantryService();
  final NotificationService _notificationService = NotificationService();
  final RecipeService _recipeService = RecipeService();

  @override
  Widget build(BuildContext context) {
    final notifications = _notificationService.generateNotificationMessages();
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: FutureBuilder<List<Recipe>>(
          future: _recipeService.getRecipesSortedByExpiring(),
          builder: (context, snapshot) {
            final recipes = (snapshot.data ?? []).take(5).toList();
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(notifications.length, colorScheme),
                  const SizedBox(height: 24),
                  _buildStatsCards(colorScheme),
                  const SizedBox(height: 20),
                  if (_pantryService.totalItems > 0) ...[
                     _buildWasteSavedCard(colorScheme),
                     const SizedBox(height: 24),
                  ],
                  _buildRecipeSuggestions(recipes, colorScheme),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddItem(),
        backgroundColor: colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
    );
  }

  void _navigateToAddItem() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AddItemScreen())).then((_) => setState(() {}));
  }

  void _navigateToPantry() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const PantryScreen())).then((_) => setState(() {}));
  }

  void _navigateToRecipes() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const RecipesScreen())).then((_) => setState(() {}));
  }

  Widget _buildHeader(int notificationCount, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [colorScheme.primary.withValues(alpha: 0.3), colorScheme.secondary.withValues(alpha: 0.3)]),
            border: Border.all(color: colorScheme.primary, width: 2),
          ),
          child: Center(child: Icon(Icons.person, color: colorScheme.primary, size: 24)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WELCOME BACK', style: TextStyle(color: colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
              Text('Hello, User!', style: TextStyle(color: colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _showNotifications(colorScheme),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(12)),
            child: Stack(
              children: [
                Center(child: Icon(Icons.notifications_outlined, color: colorScheme.onSurface, size: 24)),
                if (notificationCount > 0) Positioned(top: 10, right: 12, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showNotifications(ColorScheme colorScheme) {
    final messages = _notificationService.generateNotificationMessages();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Expiry Alerts', style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (messages.isEmpty)
              Padding(padding: const EdgeInsets.all(20), child: Text('No items expiring soon!', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6))))
            else
              ...messages.take(5).map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(m.message, style: TextStyle(color: colorScheme.onSurface, fontSize: 14)),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(ColorScheme colorScheme) {
    if (_pantryService.totalItems == 0) {
      return GestureDetector(
        onTap: _navigateToAddItem,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3), width: 1),
            boxShadow: [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 0)]
          ),
          child: Column(
            children: [
              Icon(Icons.add_shopping_cart, color: colorScheme.primary, size: 48),
              const SizedBox(height: 16),
              Text('Your pantry is empty', style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Add items to track expiry and get recipes', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(child: GestureDetector(onTap: _navigateToPantry, child: _buildStatCard(icon: Icons.warning_amber_rounded, iconColor: Colors.red, value: '${_pantryService.expiringSoonCount}', label: 'EXPIRING SOON', bgColor: colorScheme.error.withValues(alpha: 0.1), colorScheme: colorScheme))),
        const SizedBox(width: 16),
        Expanded(child: GestureDetector(onTap: _navigateToPantry, child: _buildStatCard(icon: Icons.shopping_bag_outlined, iconColor: colorScheme.primary, value: '${_pantryService.totalItems}', label: 'TOTAL ITEMS', bgColor: colorScheme.primary.withValues(alpha: 0.1), colorScheme: colorScheme))),
      ],
    );
  }

  Widget _buildStatCard({required IconData icon, required Color iconColor, required String value, required String label, required Color bgColor, required ColorScheme colorScheme}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 22)),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(color: colorScheme.onSurface, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: iconColor, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildWasteSavedCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2), width: 1)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(Icons.eco, color: colorScheme.primary, size: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('5kg Waste Saved', style: TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Great impact this month!', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeSuggestions(List<Recipe> recipes, ColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('What should I cook today?', style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
            GestureDetector(onTap: _navigateToRecipes, child: Text('See all', style: TextStyle(color: colorScheme.primary, fontSize: 14, fontWeight: FontWeight.w500))),
          ],
        ),
        const SizedBox(height: 16),
        if (recipes.isEmpty)
          GestureDetector(
            onTap: _navigateToAddItem,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1), width: 1, style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Icon(Icons.restaurant_menu, color: colorScheme.onSurface.withValues(alpha: 0.3), size: 40),
                  const SizedBox(height: 12),
                  Text('Add ingredients to see recipes', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14)),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 220,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: recipes.map((recipe) => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RecipesScreen())),
                  child: _buildRecipeCard(recipe, colorScheme)
                ),
              )).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildRecipeCard(Recipe recipe, ColorScheme colorScheme) {
    return Container(
      width: 180,
      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1), width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [colorScheme.primary.withValues(alpha: 0.3), colorScheme.secondary.withValues(alpha: 0.2)])),
            child: Stack(
              children: [
                Center(child: Icon(Icons.restaurant, color: colorScheme.primary.withValues(alpha: 0.5), size: 48)),
                Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8)), child: Text('${recipe.cookTime} MIN', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recipe.name, style: TextStyle(color: colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle)), const SizedBox(width: 6), Expanded(child: Text('Uses ${recipe.expiringItemsUsed} items', style: TextStyle(color: colorScheme.primary, fontSize: 12), overflow: TextOverflow.ellipsis))]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
