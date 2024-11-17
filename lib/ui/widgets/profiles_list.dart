import 'package:despresso/model/de1shotclasses.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/screens/profiles_advanced_edit_screen.dart';
import 'package:despresso/ui/widgets/profile_graph.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class ProfileDetailItem extends StatelessWidget {
  final De1ShotProfile profile;

  const ProfileDetailItem({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        physics: ScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(
                height: 300,
                child: ProfileGraphWidget(
                    key: Key(profile.id), selectedProfile: profile)),
            Flex(
                direction: Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      flex: 2,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Author: ${profile.shotHeader.author}",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              "Profile notes:",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              profile.shotHeader.notes,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ])),
                  Expanded(
                      child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                          Text(
                            "Technical data:",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                              "Total volume: ${profile.shotHeader.targetVolume}"),
                          Text(
                              "Expected weight: ${profile.shotHeader.targetWeight}"),
                          Text(
                            "Steps:",
                            style: Theme.of(context).textTheme.titleMedium,
                          )
                        ] +
                        profile.shotFrames.map((step) {
                          return Text(step.name);
                        }).toList(),
                  )),
                ]),
          ],
        ));
  }
}

class ProfileListItem extends StatelessWidget {
  final String title;
  final String description;
  final String author;
  final bool isSelected;
  final void Function() callback;

  const ProfileListItem(
      {super.key,
      required this.title,
      required this.description,
      required this.author,
      required this.isSelected,
      required this.callback});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => callback(),
        child: Card(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(author),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )));
  }
}

class ProfilesList extends StatefulWidget {
  // discerns between picking a profile for the shot and browsing profiles
  final bool isBrowsingOnly;
	final De1ShotProfile? fromSelectedProfile;
  const ProfilesList({super.key, required this.isBrowsingOnly, this.fromSelectedProfile});

  @override
  State<StatefulWidget> createState() {
    return ProfilesListState();
  }
}

class ProfilesListState extends State<ProfilesList> {
  final log = Logger('ProfilesList');

  late ProfileService profileService;
  De1ShotProfile? _selectedProfile;

  List<De1ShotProfile> _filteredProfiles = [];
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Profiles"),
          actions: _selectedProfile != null
              ? [
                  IconButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    AdvancedProfilesEditScreen(
                                        _selectedProfile!)));
                      },
                      icon: Icon(Icons.edit)),
                  IconButton(
                      onPressed: () => showDialog<void>(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                                title: Text("Are you sure?"),
                                content: const Text(
                                    "Do you really want to delete this profile?"),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Cancel")),
                                  TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        profileService
                                            .delete(_selectedProfile!);
                                        setState(() {
                                          _selectedProfile = null;
                                        });
                                        loadAndSetProfiles();
                                      },
                                      child: Text("Really delete"))
                                ],
                              )),
                      icon: Icon(Icons.delete)),
                ]
              : [],
        ),
        body: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    width: 400,
                    child: Column(
                      children: [
                        TextField(
                          controller: controller,
                          decoration: InputDecoration(
                              suffixIcon: IconButton(
                                  onPressed: () => controller.text = "",
                                  icon: Icon(Icons.clear))),
                        ),
                        Flexible(
                            child: ListView.builder(
                                itemCount: _filteredProfiles.length,
                                itemBuilder: (context, index) {
                                  var profile = _filteredProfiles[index];
                                  return ProfileListItem(
                                    title: profile.title,
                                    description: profile.shotHeader.notes,
                                    author: profile.shotHeader.author,
                                    isSelected: _selectedProfile == profile,
                                    callback: () {
                                      setState(() {
                                        _selectedProfile = profile;
                                      });
                                      if (widget.isBrowsingOnly) {
                                        return;
                                      }
                                      getIt<CoffeeService>()
                                          .setSelectedRecipeProfile(
                                              profile.id, profile.title);
                                    },
                                  );
                                })),
                        TextButton(
                          child: Text(
                            "Add new profile",
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      AdvancedProfilesEditScreen(
                                          De1ShotProfile.createNew())),
                            );
                          },
                        ),
                      ],
                    )),
                Expanded(
                    flex: 1,
                    child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Container(
                            child: _selectedProfile == null
                                ? Text("Nothing selected")
                                : ProfileDetailItem(
                                    profile: _selectedProfile!))))
              ],
            )));
  }

  @override
  void dispose() {
    profileService.removeListener(loadAndSetProfiles);
    controller.removeListener(loadAndSetProfiles);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
		_selectedProfile = widget.fromSelectedProfile;
    profileService = getIt<ProfileService>();
    profileService.addListener(loadAndSetProfiles);
    controller.addListener(loadAndSetProfiles);
    loadAndSetProfiles();
  }

  void loadAndSetProfiles() {
    final searchString = controller.text.toLowerCase();
    var items = profileService.profiles;
    final filteredProfiles = items.where((item) {
      return item.title.toLowerCase().contains(searchString) ||
          item.id.toLowerCase().contains(searchString) ||
          item.shotHeader.type.toLowerCase().contains(searchString) ||
          item.shotHeader.notes.toLowerCase().contains(searchString) ||
          item.shotHeader.author.toLowerCase().contains(searchString);
    }).toList();
    setState(() {
      _filteredProfiles = filteredProfiles;
    });
  }
}
