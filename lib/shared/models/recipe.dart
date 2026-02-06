class Recipe {
  final String id;
  final String name;
  final String imageAsset;
  final int cookTime;
  final String category;
  final List<String> ingredients;
  final List<String> instructions;
  final int expiringItemsUsed;
  final String mealType;
  final String region;

  Recipe({required this.id, required this.name, required this.imageAsset, required this.cookTime, required this.category, required this.mealType, required this.ingredients, required this.instructions, this.expiringItemsUsed = 0, required this.region});

  Recipe copyWith({int? expiringItemsUsed}) => Recipe(id: id, name: name, imageAsset: imageAsset, cookTime: cookTime, category: category, mealType: mealType, ingredients: ingredients, instructions: instructions, expiringItemsUsed: expiringItemsUsed ?? this.expiringItemsUsed, region: region);
}
