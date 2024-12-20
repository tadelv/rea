import 'package:collection/collection.dart';
import 'package:despresso/generated/l10n.dart';
import 'package:despresso/objectbox.g.dart';
import 'package:despresso/ui/widgets/key_value.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

import 'package:despresso/model/coffee.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/screens/coffee_edit.dart';
import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;
import 'package:reactive_flutter_rating_bar/reactive_flutter_rating_bar.dart';

import '../../model/services/ble/machine_service.dart';

class CoffeeSelectionTab extends StatefulWidget {
  final bool saveToRecipe;
  const CoffeeSelectionTab({super.key, required this.saveToRecipe});

  @override
  CoffeeSelectionTabState createState() => CoffeeSelectionTabState();
}

enum EditModes { show, add, edit }

class CoffeeSelectionTabState extends State<CoffeeSelectionTab> {
  final log = Logger('CoffeeSelectionTabState');

  Coffee newCoffee = Coffee();
  int _selectedCoffeeId = 0;
  //String _selectedCoffee;

  late CoffeeService coffeeService;
  late EspressoMachineService machineService;

  final EditModes _editCoffeeMode = EditModes.show;

  List<DropdownMenuItem<int>> coffees = [];

  CoffeeSelectionTabState() {
    newCoffee.name = "<new Beans>";
    newCoffee.id = 0;
    _selectedCoffeeId = 0;
  }

  @override
  void initState() {
    super.initState();
    coffeeService = getIt<CoffeeService>();
    machineService = getIt<EspressoMachineService>();
    coffeeService.addListener(updateCoffee);
    updateCoffee();
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.saveToRecipe)
      coffeeService.setSelectedRecipeCoffee(_selectedCoffeeId);
    coffeeService.removeListener(updateCoffee);
    log.info('Disposed coffeeselection');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).screenBeanSelectTitle),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CoffeeEdit(0)),
          );
        },
        // backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                          width: 150,
                          child:
                              Text(S.of(context).screenBeanSelectSelectBeans)),
                      Expanded(
                        flex: 8,
                        child: DropdownButton(
                          isExpanded: true,
                          alignment: Alignment.centerLeft,
                          value: _selectedCoffeeId,
                          items: coffees,
                          onChanged: (value) {
                            setState(() {
                              _selectedCoffeeId = value!;
                              if (value == 0) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const CoffeeEdit(0)),
                                );
                              } else {
                                coffeeService
                                    .setSelectedCoffee(_selectedCoffeeId);
                              }
                            });
                          },
                        ),
                      ),
                      if (_editCoffeeMode == EditModes.show)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          CoffeeEdit(_selectedCoffeeId)),
                                );
                                // _editCoffeeMode = EditModes.edit;
                                // _editRosterMode = EditModes.show;
                                // _editedCoffee = coffee;
                                // form.value = _editedCoffee.toJson();
                              });
                            },
                            child: Text(S.of(context).edit),
                          ),
                        ),
                    ],
                  ),
                  if (_selectedCoffeeId > 0) coffeeData(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<int>> loadCoffees() {
    // Build and watch the query,
    // set triggerImmediately to emit the query immediately on listen.
    final builder = coffeeService.coffeeBox
        .query(Coffee_.isShot.isNull() | Coffee_.isShot.equals(false))
        .order(Coffee_.name)
        .build();
    var found = builder.find();

    var coffees = found.map((p) {
      final Roaster r = coffeeService.roasterBox.get(p.roaster.targetId)!;
      return DropdownMenuItem(
        value: p.id,
        child: Text("${p.name} (${r.name})"),
      );
    }).toList();
    coffees.insert(0, DropdownMenuItem(value: 0, child: Text(newCoffee.name)));
    return coffees;
  }

  coffeeData() {
    if (_selectedCoffeeId == 0) return;

    var coffee = coffeeService.coffeeBox.get(_selectedCoffeeId)!;
    var roaster = coffeeService.roasterBox.get(coffee.roaster.targetId);
    DateTime d1 = DateTime.now();

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        KeyValueWidget(
            label: S.of(context).screenBeanSelectNameOfBean,
            value:
                coffee.name + (roaster != null ? " by ${roaster.name}" : "")),
        const SizedBox(
          height: 10,
        ),
        if (coffee.description.isNotEmpty)
          KeyValueWidget(
              label: S.of(context).screenBeanSelectDescriptionOfBean,
              value: coffee.description),
        const SizedBox(height: 10),
        KeyValueWidget(
            label: S.of(context).screenBeanSelectTasting, value: coffee.taste),
        const SizedBox(
          height: 10,
        ),
        KeyValueWidget(
            label: S.of(context).screenBeanSelectTypeOfBeans,
            value: coffee.type),
        const SizedBox(
          height: 10,
        ),
        KeyValueWidget(label: "Process", value: coffee.process),
        const SizedBox(
          height: 10,
        ),
        KeyValueWidget(
            label: S.of(context).screenBeanSelectRoastingDate,
            value:
                "${DateFormat.Md().format(coffee.roastDate)}, ${d1.difference(coffee.roastDate).inDays} ${S.of(context).screenBeanSelectDaysAgo}"),
        const SizedBox(height: 10),
        KeyValueWidget(
          label: S.of(context).screenBeanSelectRoastLevel,
          value: "",
          widget: RatingBarIndicator(
            rating: coffee.roastLevel,
            itemBuilder: (context, index) => Icon(
              Icons.star,
              color: Theme.of(context).colorScheme.primary,
            ),
            itemCount: 5,
            itemSize: 20.0,
            direction: Axis.horizontal,
          ),
        ),
        SizedBox(
          height: 10,
        ),
        if (coffee.description.isEmpty == false)
          KeyValueWidget(
              label: S.of(context).screenRecipeCoffeeNotes,
              value: coffee.description)
      ],
    );
  }

  Widget createKeyValue(String key, String? value) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(key, style: Theme.of(context).textTheme.labelLarge),
          if (value != null)
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  void updateCoffee() {
    setState(
      () {
        _selectedCoffeeId = coffeeService.selectedCoffeeId;
        coffees = loadCoffees();
        if (coffees.firstWhereOrNull(
                (element) => element.value == _selectedCoffeeId) ==
            null) {
          _selectedCoffeeId = 0;
        }
      },
    );
  }
}
