import '../models/recipe.dart';
import '../repositories/recipe_repository.dart';
import '../../shared/services/pantry_service.dart';
import '../../shared/services/app_settings_service.dart';

class RecipeService {
  static final RecipeService _instance = RecipeService._internal();
  factory RecipeService() => _instance;
  RecipeService._internal();

  final PantryService _pantryService = PantryService();
  final AppSettingsService _settings = AppSettingsService();
  final RecipeRepository _repository = RecipeRepository();

  // Cache recipes by region to avoid reloading
  final Map<String, List<Recipe>> _recipeCache = {};

  Future<List<Recipe>> _loadRecipesForRegion(String region) async {
    // Check cache first
    if (_recipeCache.containsKey(region)) {
      return _recipeCache[region]!;
    }

    // Load from JSON via RecipeRepository
    final recipeModels = await _repository.loadRecipesByRegion(region);
    final recipes = recipeModels.map((model) => model.toRecipe()).toList();
    
    // Cache the results
    _recipeCache[region] = recipes;
    
    print('📚 Loaded ${recipes.length} recipes from $region JSON');
    
    return recipes;
  }

  Future<List<Recipe>> _filterRecipes(bool sortByExpiry) async {
    if (_pantryService.totalItems == 0) return [];

    final pantryItemNames = _pantryService.getItems().map((i) => i.name.toLowerCase()).toSet();
    final region = _settings.selectedRegion;

    // Load recipes for the current region
    final allRecipes = await _loadRecipesForRegion(region);

    // Filter recipes that have at least one ingredient currently in pantry
    var matchingRecipes = allRecipes.where((recipe) {
      // Check if any ingredient matches a pantry item
      // We do a simple partial match: if pantry has "Milk 2L", it matches "Milk"
      for (var ingredient in recipe.ingredients) {
        if (pantryItemNames.any((name) => name.contains(ingredient.toLowerCase()) || ingredient.toLowerCase().contains(name))) {
          return true;
        }
      }
      return false;
    }).toList();

    if (sortByExpiry) {
      // Sort by number of expiring items used
      matchingRecipes.sort((a, b) => b.expiringItemsUsed.compareTo(a.expiringItemsUsed));
    }

    return matchingRecipes;
  }

  Future<List<Recipe>> getRecipesSortedByExpiring() async {
    return await _filterRecipes(true);
  }

  Future<List<Recipe>> getRecipesByCategory(String category) async {
    final allRecipes = await getRecipesSortedByExpiring();
    if (category == 'All') return allRecipes;
    return allRecipes.where((r) => r.category == category).toList();
  }

  void clearCache() {
    _recipeCache.clear();
    _repository.clearCache();
  }

  List<String> get categories => ['All', 'Breakfast', 'Lunch', 'Dinner', 'Snacks'];
}
