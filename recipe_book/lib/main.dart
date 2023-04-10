import 'package:flutter/material.dart';
import "ingredients_tab.dart";
import "recipes_tab.dart";

void main() {
  IngredientsTab i = IngredientsTab();
  RecipesTab r = RecipesTab();
  i.loadFromFile().then(
    (value) {
      runApp(MyApp(
        ingredients: i,
        recipes: r,
      ));
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.ingredients, required this.recipes});

  final IngredientsTab ingredients;
  final RecipesTab recipes;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe Book',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: Typography.whiteRedmond,
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.amber, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: MyHomePage(
        ingredients: ingredients,
        recipes: recipes,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage(
      {super.key, required this.ingredients, required this.recipes});

  final IngredientsTab ingredients;
  final RecipesTab recipes;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late final TabController mainTabController;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    mainTabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        setState(() {});
      });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TabBar(
        labelPadding: const EdgeInsets.all(5),
        controller: mainTabController,
        padding: const EdgeInsets.all(5),
        onTap: (value) {
          if (!mainTabController.indexIsChanging) {
            if (value == 0) {
              // showDialog(
              //   context: context,
              //   builder: (context) {
              //     return widget.ingredients.editIngredientDialog(context, null);
              //   },
              // );
            } else {
              showDialog<IngredientObject>(
                context: context,
                builder: (context) {
                  return widget.ingredients.editIngredientDialog(context, null);
                },
              ).then((value) {
                if (value != null) {
                  widget.ingredients.addIngredient(value);
                }
              });
            }
          }
        },
        tabs: mainTabController.index == 0
            ? const [Text("Add Recipe"), Text("Ingredients")]
            : const [Text("Recipes"), Text("Add Ingredient")],
      ),
      body: TabBarView(
          controller: mainTabController,
          children: [widget.recipes, widget.ingredients]),
    );
  }
}
