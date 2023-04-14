import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import "dart:io";

enum Units { ml, gm, oz, floz }

class IngredientObject {
  String name;
  Units unit;
  double quantity;
  double price;
  double pricePerUnit;

  double unitsInStock;

  static List<String> get labels => ["Name", "Price Per Unit", "Unit", "Stock"];

  List<String> get values => [
        name,
        pricePerUnit.toStringAsFixed(2),
        unit.name,
        unitsInStock.toStringAsFixed(2)
      ];

  IngredientObject(
      {required this.name,
      required this.unit,
      required this.quantity,
      required this.price,
      this.unitsInStock = 0})
      : pricePerUnit = (price == 0 || quantity == 0) ? 0 : price / quantity;

  bool sameAs(IngredientObject other) {
    return name == other.name &&
        unit == other.unit &&
        quantity == other.quantity &&
        price == other.price;
  }

  Map<String, dynamic> toJson() => {
        "name": name,
        "unit": unit.name,
        "quantity": quantity,
        "price": price,
        "stock": unitsInStock
      };

  static IngredientObject? fromJson(Map<String, dynamic> json) {
    var n = json["name"];
    int? u = Units.values.indexWhere((element) => element.name == json["unit"]);
    if (u < 0) u = null;
    var q = json["quantity"];
    var p = json["price"];
    var s = json["stock"];
    if ([n, u, q, p].contains(null)) {
      return null;
    }
    return IngredientObject(
        name: n,
        price: p!,
        quantity: q!,
        unit: Units.values[u!],
        unitsInStock: s);
  }
}

class IngredientsList extends ChangeNotifier {
  static const String jsonName = "ingredientsList";
  final List<IngredientObject> ingList = [];

  int get length => ingList.length;
  bool get isEmpty => ingList.isEmpty;

  bool modified = false;
  bool saving = false;

  IngredientObject operator [](int i) => ingList[i];

  operator []=(int i, IngredientObject value) {
    if (value != ingList[i]) {
      ingList[i] = value;
      notifyListeners();
    }
  }

  void add(IngredientObject newIng, {bool isLoadedValue = false}) {
    if (ingList
        .where(
          (element) => element.name == newIng.name,
        )
        .isEmpty) {
      ingList.add(newIng);
      if (!isLoadedValue) {
        notifyListeners();
        modified = true;
      }
    }
  }

  void addAll(List<IngredientObject> newList) {
    for (var el in newList) {
      add(el, isLoadedValue: true);
    }
    notifyListeners();
  }

  void remove(IngredientObject newIng) {
    if (ingList.contains(newIng)) {
      ingList.remove(newIng);
      notifyListeners();
      modified = true;
    }
  }

  Map<String, dynamic> toJson() =>
      {jsonName: List.generate(length, (index) => ingList[index].toJson())};

  static List<IngredientObject> ingredientsFromJson(Map<String, dynamic> json) {
    List<dynamic> iList = json[jsonName] ?? [];
    List<IngredientObject> retVal = [];
    for (var el in iList) {
      IngredientObject? ing = IngredientObject.fromJson(el);
      if (ing != null) {
        retVal.add(ing);
      }
    }
    return retVal;
  }
}

class IngredientsTab extends StatelessWidget {
  static const String savingFolderName = "SaveData";
  static const String ingredientsFileName = "SavedIngredients";
  final File ingFile = File(
      "${Directory.current.path}/$savingFolderName/$ingredientsFileName.json");

  IngredientsTab({super.key}) {
    Timer.periodic(const Duration(seconds: 60), (timer) {
      if (ingredientsList.modified &&
          !ingredientsList.isEmpty &&
          !ingredientsList.saving) {
        saveToFile();
      }
    });
  }

  final IngredientsList ingredientsList = IngredientsList();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  void addIngredient(IngredientObject newIng) {
    ingredientsList.add(newIng);
  }

  void removeIngredient(IngredientObject newIng) {
    ingredientsList.remove(newIng);
  }

  Future loadFromFile() async {
    if (await ingFile.exists()) {
      String fileContent = await ingFile.readAsString();
      var loadedList =
          IngredientsList.ingredientsFromJson(jsonDecode(fileContent));
      ingredientsList.ingList.addAll(loadedList);
    }
  }

  Future saveToFile() async {
    ingredientsList.saving = true;
    File? oldFile;
    if (await ingFile.exists()) {
      oldFile = await ingFile.rename("${ingredientsFileName}_old.json");
    } else {
      await ingFile.create(recursive: true);
    }

    await ingFile.writeAsString(jsonEncode(ingredientsList.toJson()));
    await oldFile?.delete();
    ingredientsList.modified = false;
    ingredientsList.saving = false;
  }

  Widget editIngredientDialog(BuildContext context, IngredientObject? ingObj) {
    Units? u = ingObj?.unit;
    double? q = ingObj?.quantity;
    double? p = ingObj?.price;
    double s = ingObj?.unitsInStock ?? 0;
    String? n = ingObj?.name;
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(10),
        height: 400,
        width: 150,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() == true) {
                      formKey.currentState?.save();
                      Navigator.of(context).pop(IngredientObject(
                          name: n!,
                          unit: u!,
                          quantity: q!,
                          price: p!,
                          unitsInStock: s));
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            ),
            Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    validator: (value) {
                      if (value == null) {
                        return "Name is required";
                      }
                    },
                    onSaved: (value) {
                      n = value;
                    },
                    initialValue: n,
                    autofocus: true,
                    decoration: const InputDecoration(hintText: "Name"),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          validator: (value) {
                            if (value == null) {
                              return "Price is required";
                            }
                            double? newP = double.tryParse(value);
                            if (newP == null || newP < 0) {
                              return "Has to be real, positive number";
                            }
                          },
                          onSaved: (value) {
                            p = double.parse(value!);
                          },
                          decoration: const InputDecoration(hintText: "Price"),
                          initialValue: p?.toString(),
                        ),
                      ),
                      const Text("\$"),
                    ],
                  ),
                  TextFormField(
                    validator: (value) {
                      if (value == null) {
                        return "Quantity is required";
                      }
                      double? newQ = double.tryParse(value);
                      if (newQ == null || newQ < 0) {
                        return "Has to be real, positive number";
                      }
                    },
                    onSaved: (value) {
                      q = double.parse(value!);
                    },
                    decoration: const InputDecoration(hintText: "Quantity"),
                    initialValue: q?.toString(),
                  ),
                  DropdownButtonFormField<Units>(
                    hint: const Text("Units"),
                    value: u,
                    items: Units.values
                        .asNameMap()
                        .keys
                        .map<DropdownMenuItem<Units>>(
                            (e) => DropdownMenuItem<Units>(
                                  child: Text(e),
                                  value: Units.values.byName(e),
                                ))
                        .toList(),
                    onChanged: (value) {
                      u = value;
                    },
                  ),
                  TextFormField(
                    validator: (value) {
                      double newQ = double.parse(value ?? "0");
                      if (newQ < 0) {
                        return "Has to be real, positive number";
                      }
                    },
                    onSaved: (value) {
                      s = double.parse(value ?? "0");
                    },
                    decoration: const InputDecoration(hintText: "Stock"),
                    initialValue: s.toString(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: ingredientsList,
        builder: (context, _) {
          return DataTable(
              showCheckboxColumn: false,
              headingRowHeight: 40,
              dataRowHeight: 40,
              headingRowColor: MaterialStatePropertyAll<Color>(
                  Theme.of(context).colorScheme.onSecondary),
              dataRowColor: MaterialStatePropertyAll<Color>(
                  Colors.white.withOpacity(0.1)),
              columns: IngredientObject.labels
                  .map<DataColumn>((e) => DataColumn(label: Text(e)))
                  .toList(),
              rows: ingredientsList.ingList
                  .map<DataRow>((ingredient) => DataRow(
                      onSelectChanged: (_) {
                        int index = ingredientsList.ingList.indexWhere(
                          (element) => element.name == ingredient.name,
                        );
                        if (index >= 0) {
                          showDialog<IngredientObject>(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) {
                              return editIngredientDialog(context, ingredient);
                            },
                          ).then((value) {
                            if (value != null &&
                                !ingredientsList[index].sameAs(value)) {
                              ingredientsList[index] = value;
                              ingredientsList.modified = true;
                            }
                          });
                        }
                      },
                      cells: ingredient.values
                          .map<DataCell>((e) => DataCell(
                                Text(e),
                              ))
                          .toList()))
                  .toList());
        });
  }
}
