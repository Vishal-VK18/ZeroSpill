import 'package:flutter/material.dart';
import '../../shared/services/recipe_service.dart';
import '../../shared/services/app_settings_service.dart';
import '../../shared/models/recipe.dart';
import '../pantry/add_item_screen.dart';
import '../../core/navigation/main_navigation_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final RecipeService _recipeService = RecipeService();
  final AppSettingsService _settings = AppSettingsService();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            backgroundColor: colorScheme.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  // If we are in the Recipes tab, go back to the Home tab
                  final navState = context.findAncestorStateOfType<MainNavigationScreenState>();
                  if (navState != null) {
                    navState.setPage(0); // Switch to Home tab
                  }
                }
              },
            ),
            title: Column(
              children: [
                Text('Cook with what you have', style: TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
                Text('Region: ${_settings.selectedRegion}', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 11)),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search, color: colorScheme.onSurface),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchQuery = '';
                      _searchController.clear();
                    }
                  });
                },
              ),
            ],
          ),
          body: Column(
            children: [
              if (_isSearching)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: colorScheme.surface,
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Search recipes or ingredients...',
                      hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                      prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.primary, width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
              Expanded(
                child: FutureBuilder<List<Recipe>>(
            // Rebuild when category or settings change
            key: ValueKey('${_selectedCategory}_${_settings.selectedRegion}'),
            future: _selectedCategory == 'All' 
                ? _recipeService.getRecipesSortedByExpiring()
                : _recipeService.getRecipesByCategory(_selectedCategory),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Loading state
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: colorScheme.primary),
                      const SizedBox(height: 16),
                      Text('Loading recipes...', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6))),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                // Error state
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: colorScheme.error, size: 64),
                        const SizedBox(height: 16),
                        Text('Error loading recipes', style: TextStyle(color: colorScheme.error, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                );
              }

              final recipes = snapshot.data ?? [];
              
              // Filter recipes by search query
              final filteredRecipes = _searchQuery.isEmpty
                  ? recipes
                  : recipes.where((recipe) {
                      final nameMatch = recipe.name.toLowerCase().contains(_searchQuery);
                      final ingredientMatch = recipe.ingredients.any(
                        (ingredient) => ingredient.toLowerCase().contains(_searchQuery),
                      );
                      return nameMatch || ingredientMatch;
                    }).toList();
              
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: _recipeService.categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: isSelected ? colorScheme.primary : Colors.transparent, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.3))),
                            child: Text(cat, style: TextStyle(color: isSelected ? Colors.black : colorScheme.onSurface, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal))),
                        ));
                      }).toList()),
                    ),
                  ),
                  if (filteredRecipes.isEmpty)
                    Expanded(
                      child: Center(
                        child: _searchQuery.isEmpty
                            ? _buildNoRecipesState(colorScheme)
                            : _buildNoSearchResultsState(colorScheme),
                      ),
                    )
                  else
                    Expanded(child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: filteredRecipes.length, itemBuilder: (context, index) => _buildRecipeCard(filteredRecipes[index], colorScheme))),
                ],
              );
            },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoRecipesState(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(Icons.soup_kitchen, color: colorScheme.primary, size: 64),
          ),
          const SizedBox(height: 24),
          Text(
            'No matching recipes yet',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add ingredients to your pantry to get smart recipe suggestions!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddItemScreen()),
            ).then((_) => setState(() {})),
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text(
              'Add Ingredients',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResultsState(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            color: colorScheme.onSurface.withValues(alpha: 0.4),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No recipes found',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for something else',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => _showRecipeDetails(recipe),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), color: colorScheme.surface),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(children: [
                  Positioned.fill(
                    child: Image.asset(
                      recipe.imageAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [colorScheme.primary.withValues(alpha: 0.3), colorScheme.secondary.withValues(alpha: 0.2)])),
                          child: Center(child: Icon(Icons.restaurant, color: colorScheme.primary.withValues(alpha: 0.5), size: 64)),
                        );
                      },
                    ),
                  ),
                  if (recipe.expiringItemsUsed > 0) Positioned(top: 12, left: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(12)), child: Text('USES ${recipe.expiringItemsUsed} EXPIRING ITEMS', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w600)))),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(recipe.name, style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(recipe.category, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle)), const SizedBox(width: 6), Text('${recipe.cookTime} mins', style: TextStyle(color: colorScheme.primary, fontSize: 13))]),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(20)), child: const Text('View Recipe', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600))),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecipeDetails(Recipe recipe) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Image header in details
            Stack(
              children: [
                SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.asset(
                      recipe.imageAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: colorScheme.surface,
                          child: Center(child: Icon(Icons.restaurant, color: colorScheme.primary.withValues(alpha: 0.5), size: 80)),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(top: 10, left: 0, right: 0, child: Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))))), // Drag handle
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(recipe.name, style: TextStyle(color: colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)), child: Text('${recipe.cookTime} mins', style: TextStyle(color: colorScheme.primary, fontSize: 12))),
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: colorScheme.onSurface.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Text(recipe.category, style: TextStyle(color: colorScheme.onSurface, fontSize: 12))),
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: colorScheme.onSurface.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Text(recipe.region, style: TextStyle(color: colorScheme.onSurface, fontSize: 12))),
                ]),
                const SizedBox(height: 24),
                Text('Ingredients', style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ...recipe.ingredients.map((i) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle)), const SizedBox(width: 12), Text(i, style: TextStyle(color: colorScheme.onSurface, fontSize: 15))]))),
                const SizedBox(height: 24),
                Text('Instructions', style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ...recipe.instructions.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 24, height: 24, decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.2), shape: BoxShape.circle), child: Center(child: Text('${e.key + 1}', style: TextStyle(color: colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)))),
                  const SizedBox(width: 12),
                  Expanded(child: Text(e.value, style: TextStyle(color: colorScheme.onSurface, fontSize: 15, height: 1.4))),
                ]))),
                const SizedBox(height: 20),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
