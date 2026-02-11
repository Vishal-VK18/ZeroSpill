import 'recipe.dart';

class RecipeModel {
  final String id;
  final String name;
  final String region;
  final String category;
  final List<String> ingredients;
  final List<String> steps;
  final int prepTime;

  RecipeModel({
    required this.id,
    required this.name,
    required this.region,
    required this.category,
    required this.ingredients,
    required this.steps,
    required this.prepTime,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Recipe',
      region: json['region']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      ingredients: json['ingredients'] != null 
          ? List<String>.from((json['ingredients'] as List).map((e) => e?.toString() ?? ''))
          : [],
      steps: json['steps'] != null
          ? List<String>.from((json['steps'] as List).map((e) => e?.toString() ?? ''))
          : [],
      prepTime: json['prepTime'] is int 
          ? json['prepTime'] as int 
          : int.tryParse(json['prepTime']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'region': region,
      'category': category,
      'ingredients': ingredients,
      'steps': steps,
      'prepTime': prepTime,
    };
  }

  // Convert RecipeModel to Recipe for use in the app
  Recipe toRecipe() {
    return Recipe(
      id: id,
      name: name,
      region: region,
      category: category,
      mealType: category, // JSON uses category for both
      ingredients: ingredients,
      instructions: steps, // JSON calls them "steps", app calls them "instructions"
      cookTime: prepTime, // JSON calls it "prepTime", app calls it "cookTime"
      imageAsset: _getImageAssetPath(), // Generate image path based on recipe
      expiringItemsUsed: 0, // Will be calculated by RecipeService
    );
  }

  // Generate image asset path based on recipe ID or name
  String _getImageAssetPath() {
    // Use a default placeholder for now, can be customized per recipe later
    final cleanName = name.toLowerCase().replaceAll(' ', '_');
    return 'assets/images/$cleanName.png';
  }
}
