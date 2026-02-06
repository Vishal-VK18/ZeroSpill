import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/recipe_model.dart';

class RecipeRepository {
  static final RecipeRepository _instance = RecipeRepository._internal();
  factory RecipeRepository() => _instance;
  RecipeRepository._internal();

  final Map<String, List<RecipeModel>> _cache = {};

  Future<List<RecipeModel>> loadRecipesByRegion(String region) async {
    if (_cache.containsKey(region)) {
      return _cache[region]!;
    }

    final String fileName = region.toLowerCase().replaceAll(' ', '_');
    final String jsonString = await rootBundle.loadString('assets/recipes/$fileName.json');
    final List<dynamic> jsonList = json.decode(jsonString) as List;
    
    final recipes = jsonList.map((json) => RecipeModel.fromJson(json as Map<String, dynamic>)).toList();
    _cache[region] = recipes;
    
    return recipes;
  }

  Future<List<RecipeModel>> getRecipesByCategory(String region, String category) async {
    final allRecipes = await loadRecipesByRegion(region);
    if (category == 'All') return allRecipes;
    return allRecipes.where((r) => r.category == category).toList();
  }

  void clearCache() {
    _cache.clear();
  }

  List<String> get availableRegions => [
    'Tamil Nadu',
    'Karnataka',
    'Andhra Pradesh',
    'Kerala',
    'Maharashtra',
    'Punjab',
    'West Bengal',
  ];

  List<String> get categories => ['All', 'Breakfast', 'Lunch', 'Dinner', 'Snacks'];
}
