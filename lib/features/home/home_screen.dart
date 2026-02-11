import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../shared/services/recipe_service.dart';
import '../../shared/models/recipe.dart';
import '../pantry/add_item_screen.dart';
import '../recipes/recipes_screen.dart';
import '../notifications/notification_screen.dart';
import '../../shared/models/pantry_item.dart';
import '../../shared/services/app_settings_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RecipeService _recipeService = RecipeService();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pure black background
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .collection('pantry')
              .snapshots(),
          builder: (context, pantrySnapshot) {
            // Calculate stats from Firestore
            int totalItems = 0;
            int expiringSoonCount = 0;
            
            if (pantrySnapshot.hasData) {
              totalItems = pantrySnapshot.data!.docs.length;
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final int notifyDays = AppSettingsService().expiryAlertDays;
              
              for (var doc in pantrySnapshot.data!.docs) {
                final item = PantryItem.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                final expiry = DateTime(item.expiryDate.year, item.expiryDate.month, item.expiryDate.day);
                final difference = expiry.difference(today).inDays;
                
                if (expiry.isBefore(today) || expiry.isAtSameMomentAs(today) || difference <= notifyDays) {
                  expiringSoonCount++;
                }
              }
            }

            return FutureBuilder<List<Recipe>>(
              future: _recipeService.getRecipesSortedByExpiring(),
              builder: (context, recipeSnapshot) {
                final recipes = (recipeSnapshot.data ?? []).take(5).toList();
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(expiringSoonCount, colorScheme),
                      const SizedBox(height: 24),
                      _buildStatsCards(expiringSoonCount, totalItems, colorScheme),
                      const SizedBox(height: 20),
                      if (totalItems > 0) ...[
                         _buildWasteSavedCard(colorScheme),
                         const SizedBox(height: 24),
                      ],
                      _buildRecipeSuggestions(recipes, colorScheme),
                      const SizedBox(height: 100), // Extra space for FAB
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: _buildFAB(colorScheme),
    );
  }

  void _navigateToAddItem() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AddItemScreen())).then((_) => setState(() {}));
  }

  void _navigateToRecipes() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const RecipesScreen())).then((_) => setState(() {}));
  }

  Future<void> _uploadProfilePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${user.uid}.jpg');

      await storageRef.putFile(File(image.path));
      final downloadUrl = await storageRef.getDownloadURL();

      // Save URL to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'profilePicture': downloadUrl});

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildHeader(int notificationCount, ColorScheme colorScheme) {
    return Row(
      children: [
        // Avatar with green border - Tappable to edit
        GestureDetector(
          onTap: _uploadProfilePicture,
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .get(),
            builder: (context, snapshot) {
              String? profilePicUrl;
              if (snapshot.hasData) {
                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                profilePicUrl = data['profilePicture'] as String?;
              }

              return Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.primary, width: 3),
                  image: profilePicUrl != null
                      ? DecorationImage(
                          image: NetworkImage(profilePicUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: profilePicUrl == null ? const Color(0xFF1A1A1A) : null,
                ),
                child: profilePicUrl == null
                    ? Icon(Icons.person, color: colorScheme.primary, size: 28)
                    : null,
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WELCOME BACK',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text(
                      'Hello, User!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  final name = data['name'] ?? 'User';

                  return Text(
                    'Hello, $name!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        // Notification bell
        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              shape: BoxShape.circle,
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                if (notificationCount > 0)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards(int expiringSoonCount, int totalItems, ColorScheme colorScheme) {
    if (totalItems == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(Icons.add_shopping_cart, color: colorScheme.primary, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Your pantry is empty',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items to track expiry and get recipes',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        // Expiring Soon Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3D1F1F), Color(0xFF2A1515)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.red.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                ),
                const SizedBox(height: 20),
                Text(
                  '$expiringSoonCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'EXPIRING SOON',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Total Items Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1F3D2A), Color(0xFF15291C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.inventory_2_outlined, color: colorScheme.primary, size: 24),
                ),
                const SizedBox(height: 20),
                Text(
                  '$totalItems',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'TOTAL ITEMS',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWasteSavedCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8B7355), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF3D3525),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco, color: Color(0xFF8B7355), size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '5kg Waste Saved',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Great impact this month!',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 14,
                  ),
                ),
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
            const Text(
              'What should I cook today?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: _navigateToRecipes,
              child: Text(
                'See all',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recipes.isEmpty)
          GestureDetector(
            onTap: _navigateToAddItem,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add ingredients to see recipes',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(right: index < recipes.length - 1 ? 16 : 0),
                  child: GestureDetector(
                    onTap: _navigateToRecipes,
                    child: _buildRecipeCard(recipes[index], colorScheme),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRecipeCard(Recipe recipe, ColorScheme colorScheme) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with badge
          Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.4),
                  colorScheme.secondary.withValues(alpha: 0.3),
                ],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.restaurant,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 56,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${recipe.cookTime} MIN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Uses your ingredients',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(ColorScheme colorScheme) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToAddItem,
          borderRadius: BorderRadius.circular(20),
          child: const Center(
            child: Icon(
              Icons.add,
              color: Colors.black,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}
