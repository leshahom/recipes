import 'package:flutter/material.dart';
import "recipes_tab.dart";
import "ingredients_tab.dart";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe Book',
      theme: ThemeData(
        textTheme: Typography.whiteRedmond,
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.amber, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Recipe Book'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: TabBar(
            padding: const EdgeInsets.all(5),
            onTap: (value) {
              if (DefaultTabController.of(context).index == value) {
                if (value == 0) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return Text("Add Recipe");
                    },
                  );
                }else{
                  showDialog(
                    context: context,
                    builder: (context) {
                      return Text("Add Ingredient");
                    },
                  );
                }
              }
            },
            tabs: DefaultTabController.of(context).index == 0
                ? const [Text("Add Recipe"), Text("Ingredients")]
                : const [Text("Recipes"), Text("Add Ingredient")],
          ),
          body: TabBarView(children: [RecipesTab(), IngredientsTab()]),
        ));
  }
}
