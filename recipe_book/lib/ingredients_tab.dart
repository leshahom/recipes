import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import "dart:io";

enum Units { ml, gm, oz, floz }

class IngredientObject {
  String name;
  Units unit;
  double quantity;
  double price;
  double pricePerUnit;

  double? unitsInStock;
  String? notes;

  static List<String> get labels =>
      ["Name", "Price Per Unit", "Unit", "Stock", "Notes"];

  List<String> get stringValues => [
        name,
        pricePerUnit.toStringAsFixed(2),
        unit.name,
        unitsInStock!.toStringAsFixed(2),
        notes!
      ];

  List<dynamic> get values =>
      [name, pricePerUnit, unit.name, unitsInStock, notes];

  IngredientObject(
      {required this.name,
      required this.unit,
      required this.quantity,
      required this.price,
      this.unitsInStock,
      this.notes})
      : pricePerUnit = ((price == 0 || quantity == 0) ? 0 : price / quantity) {
    unitsInStock ??= 0;
    notes ??= "";
  }

  bool sameAs(IngredientObject other) {
    return name == other.name &&
        unit == other.unit &&
        quantity == other.quantity &&
        price == other.price &&
        unitsInStock == other.unitsInStock &&
        notes == other.notes;
  }

  Map<String, dynamic> toJson() => {
        "name": name,
        "unit": unit.name,
        "quantity": quantity,
        "price": price,
        "stock": unitsInStock,
        "notes": notes
      };

  static IngredientObject? fromJson(Map<String, dynamic> json) {
    var n = json["name"];
    int? u = Units.values.indexWhere((element) => element.name == json["unit"]);
    if (u < 0) u = null;
    var q = json["quantity"];
    var p = json["price"];
    var s = json["stock"];
    var t = json["notes"];
    if ([n, u, q, p].contains(null)) {
      return null;
    }
    return IngredientObject(
        name: n,
        price: p!,
        quantity: q!,
        unit: Units.values[u!],
        unitsInStock: s,
        notes: t);
  }
}

class IngredientsList extends ChangeNotifier {
  static const String jsonName = "ingredientsList";
  final List<IngredientObject> ingList = [];

  int get length => ingList.length;
  bool get isEmpty => ingList.isEmpty;

  bool modified = false;
  bool saving = false;
  int sortIndex = 0;
  bool sortAsc = true;

  IngredientObject operator [](int i) => ingList[i];

  operator []=(int i, IngredientObject value) {
    if (value != ingList[i]) {
      ingList[i] = value;
      notifyListeners();
    }
  }

  void sortIngredients(int idx, bool asc) {
    sortIndex = idx;
    sortAsc = asc;
    ingList.sort(
      (a, b) {
        return (asc ? a : b)
            .stringValues[idx]
            .compareTo((!asc ? a : b).stringValues[idx]);
      },
    );
    notifyListeners();
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
    Timer.periodic(const Duration(seconds: 10), (timer) {
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
    if (await ingFile.exists()) {
      await ingFile.copy(
          "${"${Directory.current.path}/$savingFolderName/$ingredientsFileName"}_old.json");
    } else {
      await ingFile.create(recursive: true);
    }

    await ingFile.writeAsString(jsonEncode(ingredientsList.toJson()));
    ingredientsList.modified = false;
    ingredientsList.saving = false;
  }

  Widget editIngredientDialog(BuildContext context, IngredientObject? ingObj) {
    Units? u = ingObj?.unit;
    double? q = ingObj?.quantity;
    double? p = ingObj?.price;
    double? s = ingObj?.unitsInStock;
    String? n = ingObj?.name;
    String? t = ingObj?.notes;
    return LayoutBuilder(builder: (context, constraints) {
      return Dialog(
        child: Container(
          padding: const EdgeInsets.all(9),
          height: max(constraints.maxHeight * 2 / 3, 500),
          width: max(constraints.maxWidth / 2, 400),
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
                            unitsInStock: s,
                            notes: t));
                      }
                    },
                    child: const Text("Save"),
                  ),
                  if (ingObj != null)
                    ElevatedButton(
                      onPressed: () {
                        showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return Dialog(
                              child: SizedBox(
                                height: 100,
                                width: 100,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    const Text("Delete?"),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(true);
                                          },
                                          child: const Text("Yes"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(false);
                                          },
                                          child: const Text("No"),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ).then((value) {
                          if (value == true) {
                            ingredientsList.remove(ingObj);
                            ingredientsList.modified = true;
                            Navigator.of(context).pop();
                          }
                        });
                      },
                      child: const Text("Delete"),
                    ),
                ],
              ),
              Expanded(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty == true) {
                            return "Name is required";
                          }
                          bool nameUsed = ingredientsList.ingList
                              .where((element) =>
                                  element.name == value && element != ingObj)
                              .isNotEmpty;
                          if (nameUsed) {
                            return "Ingredient with this name already exists";
                          }
                        },
                        onSaved: (value) {
                          n = value;
                        },
                        initialValue: n,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: "Name",
                          labelStyle: TextStyle(fontSize: 20),
                          alignLabelWithHint: true,
                          floatingLabelAlignment: FloatingLabelAlignment.center,
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
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
                                  return "Has to be real, non negative number";
                                }
                              },
                              onSaved: (value) {
                                p = double.parse(value!);
                              },
                              decoration: const InputDecoration(
                                labelText: "Price",
                                alignLabelWithHint: true,
                                labelStyle: TextStyle(fontSize: 20),
                                floatingLabelAlignment:
                                    FloatingLabelAlignment.center,
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.auto,
                              ),
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
                          if (newQ == null || newQ <= 0) {
                            return "Has to be real, positive number";
                          }
                        },
                        onSaved: (value) {
                          q = double.parse(value!);
                        },
                        decoration: const InputDecoration(
                          labelText: "Quantity",
                          alignLabelWithHint: true,
                          labelStyle: TextStyle(fontSize: 20),
                          floatingLabelAlignment: FloatingLabelAlignment.center,
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                        initialValue: q?.toString(),
                      ),
                      DropdownButtonFormField<Units>(
                        decoration: const InputDecoration(
                          labelText: "Units",
                          labelStyle: TextStyle(fontSize: 20),
                          alignLabelWithHint: true,
                          floatingLabelAlignment: FloatingLabelAlignment.center,
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                        value: u,
                        validator: (value) {
                          if (value == null) {
                            return "Units required";
                          }
                        },
                        items: Units.values
                            .asNameMap()
                            .keys
                            .map<DropdownMenuItem<Units>>(
                                (e) => DropdownMenuItem<Units>(
                                      value: Units.values.byName(e),
                                      child: Text(e),
                                    ))
                            .toList(),
                        onChanged: (value) {
                          u = value;
                        },
                      ),
                      TextFormField(
                        validator: (value) {
                          double newQ = double.tryParse(value ?? "0") ?? 0;
                          if (newQ < 0) {
                            return "Has to be real, non-negative number";
                          }
                        },
                        onSaved: (value) {
                          s = double.tryParse(value ?? "");
                        },
                        decoration: const InputDecoration(
                          labelText: "Stock",
                          alignLabelWithHint: true,
                          labelStyle: TextStyle(fontSize: 20),
                          floatingLabelAlignment: FloatingLabelAlignment.center,
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                        initialValue: s?.toString(),
                      ),
                      TextFormField(
                        maxLines: 3,
                        onSaved: (value) {
                          t = value;
                        },
                        decoration: const InputDecoration(
                          labelText: "Notes",
                          labelStyle: TextStyle(fontSize: 20),
                          alignLabelWithHint: true,
                          floatingLabelAlignment: FloatingLabelAlignment.center,
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                        initialValue: t,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
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
              sortAscending: ingredientsList.sortAsc,
              sortColumnIndex: ingredientsList.sortIndex,
              headingRowColor: MaterialStatePropertyAll<Color>(
                  Theme.of(context).colorScheme.onSecondary),
              dataRowColor: MaterialStatePropertyAll<Color>(
                  Colors.white.withOpacity(0.1)),
              columns: IngredientObject.labels
                  .map<DataColumn>((e) => DataColumn(
                        onSort: (columnIndex, ascending) {
                          ingredientsList.sortIngredients(
                              columnIndex, ascending);
                        },
                        label: Text(e),
                      ))
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
                      cells: ingredient.stringValues
                          .map<DataCell>((e) => DataCell(
                                Text(e),
                              ))
                          .toList()))
                  .toList());
        });
  }
}
