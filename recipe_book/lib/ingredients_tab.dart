import 'package:flutter/material.dart';

enum Units { ml, gm, oz, floz }

class IngredientObject {
  String name;
  Units unit;
  double quantity;
  double price;

  IngredientObject(
      {required this.name,
      required this.unit,
      required this.quantity,
      required this.price});
}

class IngredientsTab extends StatelessWidget {
  IngredientsTab({super.key});
  final List<IngredientObject> ingredientsList = [];
  final ValueNotifier<bool> _rebuildList = ValueNotifier(false);

  void addIngredient(IngredientObject newIng) {
    if (!ingredientsList.contains(newIng)) {
      ingredientsList.add(newIng);
      _rebuildList.value = !_rebuildList.value;
    }
  }

  void removeIngredient(IngredientObject newIng) {
    if (ingredientsList.contains(newIng)) {
      ingredientsList.remove(newIng);
      _rebuildList.value = !_rebuildList.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: _rebuildList,
        builder: (context, _, __) {
          return ListView.builder(
            itemCount: ingredientsList.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(ingredientsList[index].name),
              );
            },
          );
        });
  }
}
