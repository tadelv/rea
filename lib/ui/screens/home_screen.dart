import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.lightBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Dashboard Tiles
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              mainAxisSpacing: 16.0,
              crossAxisSpacing: 16.0,
              children: [
                DashboardTile(title: "Tile 1", value: "Data 1"),
                DashboardTile(title: "Tile 2", value: "Data 2"),
                DashboardTile(title: "Tile 3", value: "Data 3"),
                DashboardTile(title: "Tile 4", value: "Data 4"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardTile extends StatelessWidget {
  final String title;
  final String value;

  const DashboardTile({Key? key, required this.title, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
			color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueGrey,
              ),
            ),
						Text(getIt<EspressoMachineService>().profileService.currentProfile!.title),
          ],
        ),
      ),
    );
  }
}
