import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/screens/coffee_screen.dart';
import 'package:despresso/ui/screens/espresso_screen.dart';
import 'package:despresso/ui/screens/water_screen.dart';
import 'package:flutter/material.dart';
import '../model/services/ble/ble_service.dart';
import 'theme.dart' as theme;

class LandingPage extends StatefulWidget {
  LandingPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool available = false;

  late CoffeeService coffeeSelection;
  late ProfileService profileService;

  late BLEService bleService;

  @override
  void initState() {
    super.initState();
    coffeeSelection = getIt<CoffeeService>();
    coffeeSelection.addListener(() {
      setState(() {});
    });

    bleService = getIt<BLEService>();

    profileService = getIt<ProfileService>();
    profileService.addListener(() {
      setState(() {});
    });
  }

  Widget _buildButton(child, onpress) {
    var color = theme.Colors.backgroundColor;
    return Container(
        padding: EdgeInsets.all(10.0),
        child: TextButton(
          style: ButtonStyle(
            foregroundColor:
                MaterialStateProperty.all<Color>(theme.Colors.primaryColor),
            backgroundColor: MaterialStateProperty.all<Color>(color),
          ),
          onPressed: onpress,
          child: Container(
            height: 50,
            padding: EdgeInsets.all(10.0),
            child: child,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    Widget coffee;
    var currentCoffee = coffeeSelection.currentCoffee;
    if (currentCoffee != null) {
      coffee = Row(children: [
        Spacer(
          flex: 2,
        ),
        Text(
          currentCoffee.roaster,
          style: theme.TextStyles.tabSecondary,
        ),
        Spacer(
          flex: 1,
        ),
        Text(
          currentCoffee.name,
          style: theme.TextStyles.tabSecondary,
        ),
        Spacer(
          flex: 2,
        ),
      ]);
    } else {
      coffee = Text(
        'No Coffee selected',
        style: theme.TextStyles.tabSecondary,
      );
    }
    Widget profile;
    var currentProfile = profileService.currentProfile;
    // if (currentProfile != null) {
    //   profile = Text(
    //     currentProfile.name,
    //     style: theme.TextStyles.tabSecondary,
    //   );
    // } else {
    //   profile = Text(
    //     'No Profile selected',
    //     style: theme.TextStyles.tabSecondary,
    //   );
    // }
    return DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            bottom: const TabBar(
              tabs: [
                Tab(
                  icon: Icon(Icons.directions_car),
                  child: Text(
                    'Espresso',
                    style: theme.TextStyles.tabLabel,
                  ),
                ),
                Tab(
                  icon: Icon(Icons.directions_transit),
                  child: Text(
                    'Steam',
                    style: theme.TextStyles.tabLabel,
                  ),
                ),
                Tab(
                  icon: Icon(Icons.directions_bike),
                  child: Text(
                    "Flush",
                    style: theme.TextStyles.tabLabel,
                  ),
                ),
                Tab(
                  icon: Icon(Icons.directions_bike),
                  child: Text(
                    'Water',
                    style: theme.TextStyles.tabLabel,
                  ),
                )
              ],
            ),
          ),
          body: TabBarView(
            children: [
              Container(
                child: EspressoScreen(),
              ),
              Icon(Icons.directions_transit),
              Icon(Icons.directions_bike),
              Icon(Icons.directions_bike),
            ],
          ),
          drawer: Drawer(
            // Add a ListView to the drawer. This ensures the user can scroll
            // through the options in the drawer if there isn't enough vertical
            // space to fit everything.
            child: ListView(
              // Important: Remove any padding from the ListView.
              padding: EdgeInsets.zero,
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                  child: Text('Drawer Header'),
                ),
                ListTile(
                  title: const Text('Profiles'),
                  onTap: () {
                    // Update the state of the app
                    // ...
                    // Then close the drawer
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Coffees'),
                  onTap: () {
                    // Update the state of the app
                    // ...
                    // Then close the drawer
                    configureCoffee();
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Settings'),
                  onTap: () {
                    // Update the state of the app
                    // ...
                    bleService.startScan();
                    // Then close the drawer
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ));
  }

  void configureCoffee() {
    var snackBar = SnackBar(
        content: const Text('Configure your coffee'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Some code to undo the change.
          },
        ));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
