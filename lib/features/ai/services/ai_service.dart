import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/ai_message.dart';
import '../../../shared/models/pantry_item.dart';

enum AiIntent {
  expiry,
  recipe,
  pantry,
  storage,
  recipe_specific,
  unknown
}

class AiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Local storage tips database
  final Map<String, String> _storageTips = {
    "tomato": "🍅 **Tomatoes**: Store at room temperature away from sunlight. Refrigeration makes them mealy.",
    "potato": "🥔 **Potatoes**: Store in a cool, dark, well-ventilated place. Keep away from onions!",
    "onion": "🧅 **Onions**: Keep in a cool, dry, dark place with good circulation.",
    "milk": "🥛 **Milk**: Store in the coldest part of the fridge (back of bottom shelf), never in the door.",
    "bread": "🍞 **Bread**: Store in a cool, dry place or freeze it. The fridge dries it out fast!",
    "banana": "🍌 **Bananas**: Store on the counter. Hang them to prevent bruising.",
    "apple": "🍎 **Apples**: Store in the crisper drawer of your fridge.",
    "berry": "🍓 **Berries**: Wash only right before eating. Store in the fridge.",
    "egg": "🥚 **Eggs**: Keep in their original carton on a fridge shelf.",
    "garlic": "🧄 **Garlic**: Store in a cool, dark place with good air circulation.",
    "rice": "🍚 **Rice**: Store in an airtight container in a cool, dry place.",
    "pasta": "🍝 **Pasta**: Store in an airtight container in a cool, dry place.",
  };

  // Local recipe database
  final List<Map<String, dynamic>> _recipes = [
    {
      "name": "Vegetable Stir Fry",
      "ingredients": ["onion", "bell pepper", "carrot", "broccoli", "garlic", "soy sauce"],
    },
    {
      "name": "Tomato Basil Soup",
      "ingredients": ["tomato", "onion", "garlic", "basil", "cream"],
    },
    {
      "name": "Potato Salad",
      "ingredients": ["potato", "onion", "mayonnaise", "mustard", "celery"],
    },
    {
      "name": "Classic Omelette",
      "ingredients": ["egg", "milk", "cheese", "spinach", "onion"],
    },
    {
      "name": "Grilled Cheese",
      "ingredients": ["bread", "cheese", "butter"],
    },
    {
      "name": "Tomato Curry",
      "ingredients": ["tomato", "onion", "spices", "oil"],
    },
    {
        "name": "Fried Rice",
        "ingredients": ["rice", "egg", "onion", "carrot", "peas", "soy sauce"]
    },
    {
        "name": "Pasta with Tomato Sauce",
        "ingredients": ["pasta", "tomato", "onion", "garlic", "basil", "cheese"]
    },
    {
        "name": "Banana Bread",
        "ingredients": ["banana", "flour", "sugar", "butter", "egg"]
    },
    {
        "name": "Garlic Butter Rice",
        "ingredients": ["rice", "garlic", "butter", "parsley"]
    }
  ];

  AiIntent _detectIntent(String message) {
    message = message.toLowerCase();

    // Check for specific recipe request (ingredient + recipe keyword)
    if (message.contains("recipe") || message.contains("cook") || message.contains("make")) {
        List<String> ingredients = ["rice", "tomato", "potato", "onion", "egg", "chicken", "pasta", "banana", "bread", "milk"];
        bool hasIngredient = ingredients.any((i) => message.contains(i));
        
        if (hasIngredient) {
            return AiIntent.recipe_specific;
        }
        return AiIntent.recipe;
    }

    if (message.contains("expire") || message.contains("expiry") || message.contains("soon"))
      return AiIntent.expiry;

    if (message.contains("what do i have") || message.contains("pantry") || message.contains("items") || message.contains("list"))
      return AiIntent.pantry;

    if (message.contains("store") || message.contains("keep fresh") || message.contains("storage") || message.contains("how do i keep"))
      return AiIntent.storage;

    return AiIntent.unknown;
  }

  Future<AiMessage> generateResponse(String input, String uid) async {
    final intent = _detectIntent(input);

    switch (intent) {
      case AiIntent.expiry:
        return await _checkExpiry(uid);
      case AiIntent.recipe:
        return await _suggestRecipe(uid);
      case AiIntent.recipe_specific:
        return await _suggestSpecificRecipe(uid, input);
      case AiIntent.pantry:
        return await _getPantrySummary(uid);
      case AiIntent.storage:
        return _getStorageTips(input);
      case AiIntent.unknown:
      default:
        // Check if user is asking for specific item storage without explicit keyword
        for (var key in _storageTips.keys) {
            if (input.toLowerCase().contains(key)) {
                return _createMessage(_storageTips[key]!);
            }
        }
        
        return _createMessage(
          "I can help you manage your food!\n\nTry asking:\n• What is expiring?\n• What can I cook?\n• Recipes with rice\n• How do I store tomatoes?",
        );
    }
  }

  Future<AiMessage> _checkExpiry(String uid) async {
    try {
      final snapshot = await _firestore.collection('users').doc(uid).collection('pantry').get();
      
      if (snapshot.docs.isEmpty) {
         return _createMessage("Your pantry is empty! Add items to check expiry.");
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      List<Map<String, dynamic>> expiringItems = [];
      
      for (var doc in snapshot.docs) {
        final item = PantryItem.fromMap(doc.data(), doc.id);
        final expiry = DateTime(item.expiryDate.year, item.expiryDate.month, item.expiryDate.day);
        final days = expiry.difference(today).inDays;
        
        if (days >= 0) { 
             expiringItems.add({
                "name": item.name,
                "days": days,
                "display": days < 0 ? "Expired" : (days == 0 ? "Today" : (days == 1 ? "1 day left" : "$days days left"))
             });
        }
      }

      // Sort by expiryDate ascending (days)
      expiringItems.sort((a, b) => (a['days'] as int).compareTo(b['days'] as int));

      if (expiringItems.isEmpty) {
        return _createMessage("✅ You have no items expiring in the next few days.");
      }

      // Filter to show relevant ones
      final relevantItems = expiringItems.take(5).toList();
      
      String listText = relevantItems.map((e) => "• **${e['name']}** – ${e['display']}").join("\n");
      
      return _createMessage("You have ${expiringItems.where((e) => (e['days'] as int) <= 3).length} items expiring soon:\n\n$listText\n\nCook them soon to avoid waste!");

    } catch (e) {
      return _createMessage("Error checking your pantry.");
    }
  }

  Future<AiMessage> _suggestRecipe(String uid) async {
    try {
      final snapshot = await _firestore.collection('users').doc(uid).collection('pantry').get();
      
      if (snapshot.docs.isEmpty) {
        return _createMessage("Your pantry is empty. Add items to get recipe suggestions!");
      }

      // Get user ingredients
      final userItems = snapshot.docs.map((d) {
        final item = PantryItem.fromMap(d.data(), d.id);
        final name = item.name.toLowerCase();
        final daysLeft = item.daysUntilExpiry; 
        return {"name": name, "days": daysLeft};
      }).toList();
            
      List<Map<String, dynamic>> suggestions = [];

      for (var recipe in _recipes) {
        List<String> required = (recipe['ingredients'] as List).cast<String>();
        int matchCount = 0;
        bool usesExpiring = false;
        
        for (var req in required) {
           var match = userItems.where((u) => u['name'] == req || (u['name'] as String).contains(req) || req.contains(u['name'] as String));
           if (match.isNotEmpty) {
             matchCount++;
             if ((match.first['days'] as int) <= 2) {
               usesExpiring = true;
             }
           }
        }

        double matchPercentage = matchCount / required.length;
        
        // Suggest if we have at least 50% of ingredients
        if (matchPercentage >= 0.50) {
          suggestions.add({
            "name": recipe['name'],
            "priority": usesExpiring ? 1 : 0,
            "info": usesExpiring ? "(uses expiring ingredients)" : ""
          });
        }
      }
      
      // Sort: Prioritize recipes using near-expiry ingredients.
      suggestions.sort((a, b) => (b['priority'] as int).compareTo(a['priority'] as int));

      if (suggestions.isEmpty) {
        return _createMessage("I couldn't find a recipe with your current ingredients. Try adding more basics like onions, tomatoes, or eggs.");
      }

      String listText = suggestions.take(3).map((e) => "• **${e['name']}** ${e['info']}").join("\n");
      
      return _createMessage("You can cook these soon:\n\n$listText");

    } catch (e) {
      return _createMessage("I couldn't analyze your ingredients properly.");
    }
  }
  
  Future<AiMessage> _suggestSpecificRecipe(String uid, String input) async {
      String inputLower = input.toLowerCase();
      List<String> recipesFound = [];
      
      for (var recipe in _recipes) {
          bool matches = false;
          
          // Check ingredients
          for (var ing in (recipe['ingredients'] as List)) {
              if (inputLower.contains(ing.toString().toLowerCase())) {
                  matches = true;
                  break;
              }
          }
           
          if (matches) {
              recipesFound.add(recipe['name']);
          }
      }
      
      if (recipesFound.isEmpty) {
          return _createMessage("I couldn't find any specific recipes for that.");
      }
      
      return _createMessage("Here are some recipes:\n\n" + recipesFound.map((e) => "• $e").join("\n"));
  }
  
  Future<AiMessage> _getPantrySummary(String uid) async {
    try {
      final snapshot = await _firestore.collection('users').doc(uid).collection('pantry').get();
      int total = snapshot.docs.length;
      
      Map<String, int> categories = {};
      int expiringCount = 0;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      for (var doc in snapshot.docs) {
          final item = PantryItem.fromMap(doc.data(), doc.id);
          categories[item.category] = (categories[item.category] ?? 0) + 1;
          
          final expiry = DateTime(item.expiryDate.year, item.expiryDate.month, item.expiryDate.day);
          if (expiry.difference(today).inDays <= 3 && expiry.difference(today).inDays >= 0) {
              expiringCount++;
          }
      }
      
      String categoryText = categories.entries.take(4).map((e) => "• ${e.value} ${e.key}").join("\n");
      String expiringText = expiringCount > 0 ? "\n\n⚠️ $expiringCount items expiring soon." : "";
      
      return _createMessage("You currently have **$total items**:\n\n$categoryText$expiringText");
    } catch (e) {
      return _createMessage("Error reading pantry summary.");
    }
  }

  AiMessage _getStorageTips(String input) {
    String lowerInput = input.toLowerCase();
    
    for (var key in _storageTips.keys) {
      if (lowerInput.contains(key)) {
        return _createMessage(_storageTips[key]!);
      }
    }
    
    return _createMessage("I can give storage tips for tomatoes, milk, potatoes, etc. Just ask: 'How do I store milk?'");
  }

  AiMessage _createMessage(String text) {
    return AiMessage(
      id: _uuid.v4(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }
}
