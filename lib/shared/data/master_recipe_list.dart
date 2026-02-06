import '../models/recipe.dart';

final List<Recipe> masterRecipeList = [
  // TAMIL NADU
  // Breakfast
  Recipe(
    id: 'tn_bf_1',
    name: 'Classic Idli',
    region: 'Tamil Nadu',
    mealType: 'Breakfast',
    category: 'Breakfast',
    imageAsset: 'assets/images/idli.png',
    cookTime: 20,
    ingredients: ['Idli Rice', 'Urad Dal', 'Fenugreek Seeds', 'Salt', 'Water'],
    instructions: [
      'Soak rice and dal separately for 4 hours.',
      'Grind to a smooth batter and ferment overnight.',
      'Grease idli moulds with oil.',
      'Pour batter and steam for 10-12 minutes.',
      'Serve hot with chutney and sambar.'
    ],
  ),
  Recipe(
    id: 'tn_bf_2',
    name: 'Crispy Dosa',
    region: 'Tamil Nadu',
    mealType: 'Breakfast',
    category: 'Breakfast',
    imageAsset: 'assets/images/dosa.png',
    cookTime: 10,
    ingredients: ['Dosa Batter', 'Oil', 'Salt'],
    instructions: [
      'Heat a tawa/griddle on medium heat.',
      'Pour a ladle of batter and spread thin.',
      'Drizzle oil around edges.',
      'Cook until golden brown and crisp.',
      'Fold and serve hot.'
    ],
  ),
  Recipe(
    id: 'tn_bf_3',
    name: 'Ven Pongal',
    region: 'Tamil Nadu',
    mealType: 'Breakfast',
    category: 'Breakfast',
    imageAsset: 'assets/images/pongal.png',
    cookTime: 30,
    ingredients: ['Raw Rice', 'Moong Dal', 'Black Peppercorns', 'Cumin Seeds', 'Ghee', 'Cashews', 'Ginger', 'Curry Leaves'],
    instructions: [
      'Pressure cook rice and moong dal until soft.',
      'Heat ghee in a pan.',
      'Fry cashews, pepper, cumin, ginger, and curry leaves.',
      'Add the tempering to the cooked rice and mix well.',
      'Serve hot with coconut chutney.'
    ],
  ),
   Recipe(
    id: 'tn_bf_4',
    name: 'Rava Upma',
    region: 'Tamil Nadu',
    mealType: 'Breakfast',
    category: 'Breakfast',
    imageAsset: 'assets/images/upma.png',
    cookTime: 15,
    ingredients: ['Rava (Semolina)', 'Onion', 'Green Chillies', 'Mustard Seeds', 'Urad Dal', 'Curry Leaves', 'Oil', 'Water'],
    instructions: [
      'Roast rava until aromatic and set aside.',
      'Heat oil, temper mustard seeds, urad dal, and curry leaves.',
      'Sauté onions and chillies.',
      'Add water and salt, bring to a boil.',
      'Slowly add roasted rava while stirring continuously.',
      'Cover and cook on low heat for 5 mins.'
    ],
  ),
  Recipe(
    id: 'tn_bf_5',
    name: 'Adai',
    region: 'Tamil Nadu',
    mealType: 'Breakfast',
    category: 'Breakfast',
    imageAsset: 'assets/images/adai.png',
    cookTime: 20,
    ingredients: ['Rice', 'Toor Dal', 'Chana Dal', 'Red Chillies', 'Fennel Seeds', 'Onion', 'Curry Leaves'],
    instructions: [
      'Soak rice and dals together for 3 hours.',
      'Grind coarsely with red chillies and fennel.',
      'Add chopped onions and curry leaves to batter.',
      'Make thick pancakes on hot tawa.',
      'Cook continuously on both sides with oil.', 
      'Serve with avial or jaggery.'
    ],
  ),
  
  // Lunch
  Recipe(
    id: 'tn_lun_1',
    name: 'Sambar Sadam',
    region: 'Tamil Nadu',
    mealType: 'Lunch',
    category: 'Rice',
    imageAsset: 'assets/images/sambar_rice.png',
    cookTime: 40,
    ingredients: ['Rice', 'Toor Dal', 'Tamarind', 'Mixed Vegetables', 'Sambar Powder', 'Mustard Seeds', 'Curry Leaves', 'Ghee'],
    instructions: [
      'Cook rice and dal together until soft.',
      'Boil vegetables in tamarind water with sambar powder.',
      'Mash rice and dal, add to the vegetable mixture.',
      'Cook for 5 mins, add salt.',
      'Temper mustard seeds and curry leaves in ghee and add.',
      'Serve hot with papad.'
    ],
  ),
  Recipe(
    id: 'tn_lun_2',
    name: 'Lemon Rice',
    region: 'Tamil Nadu',
    mealType: 'Lunch',
    category: 'Rice',
    imageAsset: 'assets/images/lemon_rice.png',
    cookTime: 15,
    ingredients: ['Cooked Rice', 'Lemon Juice', 'Turmeric Powder', 'Peanuts', 'Mustard Seeds', 'Green Chillies', 'Curry Leaves', 'Oil'],
    instructions: [
      'Heat oil, add mustard seeds, peanuts, and chillies.',
      'Add turmeric powder and curry leaves.',
      'Switch off flame and add lemon juice.',
      'Mix this tempering with cooked rice gently.',
      'Adjust salt and serve.'
    ],
  ),
  Recipe(
    id: 'tn_lun_3',
    name: 'Vatha Kuzhambu',
    region: 'Tamil Nadu',
    mealType: 'Lunch',
    category: 'Curry',
    imageAsset: 'assets/images/vatha_kuzhambu.png',
    cookTime: 30,
    ingredients: ['Tamarind', 'Turkey Berry (Sundakkai)', 'Sambar Powder', 'Sesame Oil', 'Mustard Seeds', 'Fenugreek Seeds', 'Curry Leaves'],
    instructions: [
      'Extract tamarind juice.',
      'Heat generous amount of sesame oil.',
      'Fry turkey berries, mustard, and fenugreek seeds.',
      'Add tamarind extract, sambar powder, and salt.',
      'Boil until oil separates and gravy thickens.',
      'Serve with hot rice.'
    ],
  ),
  Recipe(
    id: 'tn_lun_4',
    name: 'Keerai Masiyal',
    region: 'Tamil Nadu',
    mealType: 'Lunch',
    category: 'Side Dish',
    imageAsset: 'assets/images/keerai.png',
    cookTime: 20,
    ingredients: ['Spinach', 'Moong Dal', 'Garlic', 'Cumin Seeds', 'Mustard Seeds', 'Red Chillies'],
    instructions: [
      'Boil spinach and moong dal with garlic.',
      'Mash well when cooked.',
      'Heat oil, temper mustard, cumin, and red chillies.',
      'Add to the mashed spinach.',
      'Serve with rice and ghee.'
    ],
  ),
  Recipe(
    id: 'tn_lun_5',
    name: 'Curd Rice',
    region: 'Tamil Nadu',
    mealType: 'Lunch',
    category: 'Rice',
    imageAsset: 'assets/images/curd_rice.png',
    cookTime: 10,
    ingredients: ['Cooked Rice', 'Curd', 'Milk', 'Mustard Seeds', 'Green Chillies', 'Ginger', 'Curry Leaves', 'Pomegranate Seeds'],
    instructions: [
      'Mash cooked rice well.',
      'Mix with curd and milk.',
      'Temper mustard seeds, ginger, chillies, and curry leaves.',
      'Add to rice mix.',
      'Garnish with pomegranate seeds.'
    ],
  ),

  // Dinner
  Recipe(
    id: 'tn_din_1',
    name: 'Kothu Parotta',
    region: 'Tamil Nadu',
    mealType: 'Dinner',
    category: 'Main Course',
    imageAsset: 'assets/images/kothu_parotta.png',
    cookTime: 25,
    ingredients: ['Parotta', 'Onion', 'Tomato', 'Eggs', 'Chicken Salna', 'Fennel Seeds', 'Curry Leaves'],
    instructions: [
      'Shred parotta into small pieces.',
      'Sauté fennel, onions, tomatoes, and curry leaves.',
      'Add eggs and scramble.',
      'Add shredded parotta and salna.',
      'Cook on high heat while mashing everything together.',
      'Serve hot.'
    ],
  ),
  Recipe(
    id: 'tn_din_2',
    name: 'Chapati Kurma',
    region: 'Tamil Nadu',
    mealType: 'Dinner',
    category: 'Main Course',
    imageAsset: 'assets/images/chapati_kurma.png',
    cookTime: 30,
    ingredients: ['Wheat Flour', 'Mixed Vegetables', 'Coconut', 'Fennel Seeds', 'Garlic', 'Ginger', 'Spices'],
    instructions: [
      'Make soft dough with wheat flour and water, roll into chapatis and cook.',
      'Grind coconut, fennel, ginger, garlic paste.',
      'Sauté spices and vegetables.',
      'Add ground paste and water, cook until veggies are soft.',
      'Serve chapatis with vegetable kurma.'
    ],
  ),
  Recipe(
    id: 'tn_din_3',
    name: 'Idiyappam',
    region: 'Tamil Nadu',
    mealType: 'Dinner',
    category: 'Main Course',
    imageAsset: 'assets/images/idiyappam.png',
    cookTime: 20,
    ingredients: ['Rice Flour', 'Hot Water', 'Salt', 'Coconut Milk', 'Sugar'],
    instructions: [
      'Mix rice flour with hot water to form soft dough.',
      'Press through idiyappam maker onto steamer plates.',
      'Steam for 10 minutes.',
      'Extract coconut milk and add sugar.',
      'Serve idiyappam with sweetened coconut milk.'
    ],
  ),
  Recipe(
    id: 'tn_din_4',
    name: 'Uthappam',
    region: 'Tamil Nadu',
    mealType: 'Dinner',
    category: 'Main Course',
    imageAsset: 'assets/images/uthappam.png',
    cookTime: 15,
    ingredients: ['Dosa Batter', 'Onion', 'Tomato', 'Green Chillies', 'Coriander Leaves', 'Oil'],
    instructions: [
      'Heat tawa, pour thick batter.',
      'Sprinkle chopped onions, tomatoes, chillies on top.',
      'Drizzle oil around edges.',
      'Flip and cook until golden.',
      'Serve with chutney.'
    ],
  ),
  Recipe(
    id: 'tn_din_5',
    name: 'Tomato Rice',
    region: 'Tamil Nadu',
    mealType: 'Dinner',
    category: 'Rice',
    imageAsset: 'assets/images/tomato_rice.png',
    cookTime: 25,
    ingredients: ['Rice', 'Tomatoes', 'Onion', 'Ginger Garlic Paste', 'Spices (Cinnamon, Cloves)', 'Mint Leaves'],
    instructions: [
      'Soak rice.',
      'Sauté spices, onions, ginger garlic paste.',
      'Add tomatoes and cook until mushy.',
      'Add mint leaves and rice.',
      'Add water and pressure cook.',
      'Serve with raita.'
    ],
  ),

  // Snacks
  Recipe(
    id: 'tn_snk_1',
    name: 'Medhu Vada',
    region: 'Tamil Nadu',
    mealType: 'Snacks',
    category: 'Snacks',
    imageAsset: 'assets/images/medhu_vada.png',
    cookTime: 30,
    ingredients: ['Urad Dal', 'Onion', 'Green Chillies', 'Whole Pepper', 'Curry Leaves', 'Oil'],
    instructions: [
      'Soak urad dal for 2 hours and grind to fluffy batter (add very little water).',
      'Mix chopped onions, chillies, pepper, curry leaves, salt.',
      'Heat oil.',
      'Shape batter into doughnuts on wet palm.',
      'Deep fry until golden brown.',
      'Serve with sambar.'
    ],
  ),
  Recipe(
    id: 'tn_snk_2',
    name: 'Sundal',
    region: 'Tamil Nadu',
    mealType: 'Snacks',
    category: 'Healthy',
    imageAsset: 'assets/images/sundal.png',
    cookTime: 15,
    ingredients: ['Chickpeas (Chana)', 'Mustard Seeds', 'Red Chillies', 'Curry Leaves', 'Coconut (Grated)'],
    instructions: [
      'Soak and pressure cook chickpeas.',
      'Heat oil, temper mustard, chillies, curry leaves.',
      'Add cooked chickpeas and salt.',
      'Toss well.',
      'Garnish with grated coconut.'
    ],
  ),
  Recipe(
    id: 'tn_snk_3',
    name: 'Bajji',
    region: 'Tamil Nadu',
    mealType: 'Snacks',
    category: 'Snacks',
    imageAsset: 'assets/images/bajji.png',
    cookTime: 20,
    ingredients: ['Besan (Gram Flour)', 'Rice Flour', 'Chilli Powder', 'Raw Banana/Onion/Chilli', 'Oil'],
    instructions: [
      'Mix besan, rice flour, chilli powder, salt, water to thick batter.',
      'Slice vegetables thinly.',
      'Heat oil for deep frying.',
      'Dip slices in batter and fry until golden.',
      'Serve hot with chutney.'
    ],
  ),
  Recipe(
    id: 'tn_snk_4',
    name: 'Paniyaaram',
    region: 'Tamil Nadu',
    mealType: 'Snacks',
    category: 'Snacks',
    imageAsset: 'assets/images/panyaram.png',
    cookTime: 20,
    ingredients: ['Idli Batter', 'Onion', 'Green Chillies', 'Mustard Seeds', 'Oil'],
    instructions: [
      'Temper mustard, onions, chillies in oil.',
      'Add to idli batter.',
      'Heat paniyaaram pan, add drop of oil in each hole.',
      'Pour batter and cook covered.',
      'Flip and cook other side.',
      'Serve with spicy chutney.'
    ],
  ),
  Recipe(
    id: 'tn_snk_5',
    name: 'Murukku',
    region: 'Tamil Nadu',
    mealType: 'Snacks',
    category: 'Snacks',
    imageAsset: 'assets/images/murukku.png',
    cookTime: 45,
    ingredients: ['Rice Flour', 'Urad Dal Flour', 'Butter', 'Sesame Seeds', 'Oil'],
    instructions: [
      'Mix flours, butter, sesame seeds, salt, water to make dough.',
      'Fill murukku press with dough.',
      'Press into spirals on ladle or plastic sheet.',
      'Deep fry in hot oil until golden.',
      'Store in airtight container.'
    ],
  ),

  // KARNATAKA
  // Breakfast
  Recipe(
    id: 'ka_bf_1',
    name: 'Bisi Bele Bath',
    region: 'Karnataka',
    mealType: 'Breakfast',
    category: 'MAIN',
    imageAsset: 'assets/images/bbb.png',
    cookTime: 45,
    ingredients: ['Rice', 'Toor Dal', 'Mixed Vegetables', 'Bisi Bele Bath Powder', 'Tamarind', 'Ghee', 'Cashews'],
    instructions: [
      'Cook rice and dal together.',
      'Boil vegetables with tamarind water and salt.',
      'Add spice powder and cooked rice-dal mix.',
      'Simmer to porridge consistency.',
      'Temper with ghee, mustard, cashews.',
      'Serve hot with boondi.'
    ],
  ),
  Recipe(
    id: 'ka_bf_2',
    name: 'Ragi Mudde',
    region: 'Karnataka',
    mealType: 'Lunch', // Traditionally lunch, but user asked for structure
    category: 'Healthy',
    imageAsset: 'assets/images/ragi_mudde.png',
    cookTime: 20,
    ingredients: ['Ragi Flour', 'Water', 'Ghee'],
    instructions: [
      'Boil water with a drop of ghee.',
      'Add ragi flour and cook without stirring for few mins.',
      'Stir vigorously to form a lump.',
      'Steam for 5 mins.',
      'Shape into balls using wet hands.',
      'Serve with saaru.'
    ],
  ),
  Recipe(
    id: 'ka_bf_3',
    name: 'Akki Roti',
    region: 'Karnataka',
    mealType: 'Breakfast',
    category: 'Breakfast',
    imageAsset: 'assets/images/akki_roti.png',
    cookTime: 25,
    ingredients: ['Rice Flour', 'Onion', 'Green Chillies', 'Cumin Seeds', 'Dill Leaves', 'Carrot (Grated)'],
    instructions: [
      'Mix all ingredients with water to make soft dough.',
      'Pat dough on a greased banana leaf or foil to make thin roti.',
      'Flip onto heated tawa.',
      'Cook with oil on both sides.',
      'Serve with coconut chutney.'
    ],
  ),
  Recipe(
    id: 'ka_bf_4',
    name: 'Neer Dosa',
    region: 'Karnataka',
    mealType: 'Breakfast',
    category: 'Breakfast',
    imageAsset: 'assets/images/neer_dosa.png',
    cookTime: 20,
    ingredients: ['Rice', 'Coconut (Grated)', 'Salt', 'Water'],
    instructions: [
      'Soak rice for 4 hours.',
      'Grind with coconut and plenty of water to watery consistency.',
      'Pour onto hot tawa (do not spread like regular dosa).',
      'Cover and cook (do not flip).',
      'Fold and serve with jaggery mix or chutney.'
    ],
  ),
  Recipe(
    id: 'ka_bf_5',
    name: 'Chow Chow Bath',
    region: 'Karnataka',
    mealType: 'Breakfast',
    category: 'Breakfast',
    imageAsset: 'assets/images/chow_chow.png',
    cookTime: 30,
    ingredients: ['Rava', 'Vegetables', 'Sugar', 'Ghee', 'Kesari Powder', 'Spices'],
    instructions: [
      'Prepare Khara Bath (Upma with veggies and masala).',
      'Prepare Kesari Bath (Sweet semolina pudding with saffron/orange color).',
      'Serve one scoop of each side-by-side.',
      'Enjoy the sweet and spicy combo.'
    ],
  ),

  // ANDHRA PRADESH
  Recipe(
    id: 'ap_bf_1',
    name: 'Pesarattu',
    region: 'Andhra Pradesh',
    mealType: 'Breakfast',
    category: 'Breakfast',
    imageAsset: 'assets/images/pesarattu.png',
    cookTime: 20,
    ingredients: ['Whole Moong Dal (Green Gram)', 'Ginger', 'Green Chillies', 'Onion', 'Cumin Seeds'],
    instructions: [
      'Soak moong dal overnight.',
      'Grind with ginger, chillies to smooth batter.',
      'Spread like dosa on hot tawa.',
      'Sprinkle chopped onions and fried cumin.',
      'Cook until crisp.',
      'Serve with ginger chutney.'
    ],
  ),
  Recipe(
    id: 'ap_lun_1',
    name: 'Hyderabadi Biryani',
    region: 'Andhra Pradesh',
    mealType: 'Lunch',
    category: 'Main Course',
    imageAsset: 'assets/images/biryani.png',
    cookTime: 60,
    ingredients: ['Basmati Rice', 'Chicken/Mutton', 'Yogurt', 'Fried Onions', 'Biryani Masala', 'Saffron', 'Mint'],
    instructions: [
      'Marinate meat with yogurt and spices strictly for 2 hours.',
      'Cook rice till 70% done.',
      'Layer meat and rice in heavy bottom pot.',
      'Top with fried onions, saffron milk, mint.',
      'Seal pot and cook on "Dum" (low heat) for 30 mins.',
      'Serve with raita and salan.'
    ],
  ),
  Recipe(
    id: 'ap_din_1',
    name: 'Gongura Mutton',
    region: 'Andhra Pradesh',
    mealType: 'Dinner',
    category: 'Curry',
    imageAsset: 'assets/images/gongura_mutton.png',
    cookTime: 45,
    ingredients: ['Mutton', 'Gongura (Sorrel) Leaves', 'Onion', 'Green Chillies', 'Ginger Garlic Paste', 'Spices'],
    instructions: [
      'Pressure cook mutton with ginger garlic paste.',
      'Sauté gongura leaves until mushy.',
      'Heat oil, sauté onions and spices.',
      'Add mutton and gongura paste.',
      'Simmer until oil floats.',
      'Serve with steaming rice.'
    ],
  ),

  // UTTAR PRADESH
  Recipe(
    id: 'up_bf_1',
    name: 'Bedmi Puri with Aloo Sabzi',
    region: 'Uttar Pradesh',
    mealType: 'Breakfast',
    category: 'Breakfast',
    imageAsset: 'assets/images/bedmi_puri.png',
    cookTime: 40,
    ingredients: ['Wheat Flour', 'Urad Dal Paste', 'Potatoes', 'Tomatoes', 'Spices (Fennel, Coriander)', 'Oil'],
    instructions: [
      'Knead flour with urad dal paste and fennel to stiff dough.',
      'Fry spiced potato tomato curry.',
      'Roll dough into pooris and deep fry.',
      'Serve hot pooris with spicy aloo sabzi.'
    ],
  ),
  Recipe(
    id: 'up_lun_1',
    name: 'Tehri',
    region: 'Uttar Pradesh',
    mealType: 'Lunch',
    category: 'Rice',
    imageAsset: 'assets/images/tehri.png',
    cookTime: 30,
    ingredients: ['Basmati Rice', 'Potatoes', 'Cauliflower', 'Peas', 'Turmeric', 'Spices'],
    instructions: [
      'Wash rice.',
      'Sauté vegetables with whole spices.',
      'Add turmeric (generous amount for yellow color).',
      'Add rice and water.',
      'Pressure cook or open cook until rice is fluffy.',
      'Serve with curd and pickle.'
    ],
  ),
];
