import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/screens/coffee_selection.dart';
import 'package:despresso/ui/screens/profiles_screen.dart';
import 'package:flutter/material.dart';

import '../../model/shotstate.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  RecipeScreenState createState() => RecipeScreenState();
}

class RecipeScreenState extends State<RecipeScreen> {
  late EspressoMachineService machineService;
  late ProfileService profileService;
  late CoffeeService coffeeService;
  late ScaleService scaleService;

  List<ShotState> dataPoints = [];
  EspressoMachineState currentState = EspressoMachineState.disconnected;

  @override
  void initState() {
    super.initState();
    machineService = getIt<EspressoMachineService>();

    // Scale services is consumed as stream
    scaleService = getIt<ScaleService>();
    profileService = getIt<ProfileService>();
    coffeeService = getIt<CoffeeService>();
    coffeeService.addListener(coffeeServiceListener);
    profileService.addListener(profileServiceListener);
  }

  @override
  void dispose() {
    super.dispose();
    coffeeService.removeListener(coffeeServiceListener);
    profileService.removeListener(profileServiceListener);
  }

  machineStateListener() {
    setState(() => {currentState = machineService.state.coffeeState});
    // machineService.de1?.setIdleState();
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                const Text("Current Shot Recipe"),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Container(
                        color: Colors.black38,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Expanded(child: Text("Selected Base Profile")),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => const ProfilesScreen()),
                                              );
                                            },
                                            child: Text(profileService.currentProfile?.title ?? "No Profile selected"),
                                          ),
                                          Text(
                                              "Stop weight: ${profileService.currentProfile?.shotHeader.targetWeight.toStringAsFixed(1)} g")
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                // Row(
                                //   children: [
                                //     Expanded(child: Text("Dial In Layer")),
                                //     Expanded(
                                //       child: ElevatedButton(
                                //         onPressed: () {},
                                //         child: Text("Reduced Flow"),
                                //       ),
                                //     ),
                                //   ],
                                // ),
                                const Divider(),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Expanded(child: Text("Selected Bean")),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => const CoffeeSelectionTab()),
                                              );
                                            },
                                            child: Text(coffeeService.currentCoffee?.name ?? "No Coffee selected"),
                                          ),
                                          Text(
                                              "Dose: ${coffeeService.currentCoffee?.grinderDoseWeight.toStringAsFixed(1)} g"),
                                          Text("Grind Settings: ${coffeeService.currentCoffee?.grinderSettings ?? ''}"),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                              ]),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text("Details"),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(flex: 6, child: Text("Graph")),
                        Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                const Text("Description"),
                                Text(profileService.currentProfile?.shotHeader.notes ?? ""),
                                Text(coffeeService.currentCoffee?.description ?? ""),
                              ],
                            )),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: _buildControls(),
    );
  }

  void coffeeServiceListener() {
    setState(() {});
  }

  void profileServiceListener() {
    setState(() {});
  }
}
