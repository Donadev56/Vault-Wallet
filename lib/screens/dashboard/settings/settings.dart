import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/widgets/snackbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _nameController = TextEditingController();
  File? _profileImage;
  File? _backgroundImage;
  bool wasPImageChanged = false;
  bool wasBImageChanged = false;
  final ImagePicker _picker = ImagePicker();
  Color primaryColor = Color(0XFF1B1B1B);
  Color textColor = Color.fromARGB(255, 255, 255, 255);
  Color secondaryColor = Colors.greenAccent;
  Color actionsColor = Color(0XFF353535);
  Color surfaceTintColor = Color(0XFF454545);
  final publicDataManager = PublicDataManager();
  bool isDarkMode = false;

  void setLightMode() {
    setState(() {
      isDarkMode = !isDarkMode;
      primaryColor = Color(0xFFE4E4E4);
      textColor = Color(0xFF0A0A0A);
      actionsColor = Color(0xFFCACACA);
      surfaceTintColor = Color(0xFFBABABA);
      secondaryColor = Color(0xFF960F51);
    });
  }

  void setDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
      primaryColor = Color(0XFF1B1B1B);
      textColor = Color.fromARGB(255, 255, 255, 255);
      secondaryColor = Colors.greenAccent;
      actionsColor = Color(0XFF353535);
      surfaceTintColor = Color(0XFF454545);
    });
  }

  Future<void> getThemeMode() async {
    try {
      final savedMode =
          await publicDataManager.getDataFromPrefs(key: "isDarkMode");
      if (savedMode == null) {
        return;
      }
      if (savedMode == "true") {
        setDarkMode();
      } else {
        setLightMode();
      }
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<void> toggleMode() async {
    try {
      if (isDarkMode) {
        setLightMode();

        await publicDataManager.saveDataInPrefs(
            data: "false", key: "isDarkMode");
      } else {
        setDarkMode();
        await publicDataManager.saveDataInPrefs(
            data: "true", key: "isDarkMode");
      }
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<void> _pickProfileImage() async {
    log("Picking profile image");
    final File? image = await _pickImage();
    if (image != null) {
      setState(() {
        _profileImage = image;
        wasPImageChanged = true;
      });
    }
  }

  Future<void> _pickBackgroundImage() async {
    final File? image = await _pickImage();
    if (image != null) {
      setState(() {
        _backgroundImage = image;
        wasBImageChanged = true;
      });
    }
  }

  Future<File?> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      return File(image.path);
    } else {
      return null;
    }
  }

  Future<bool> saveData() async {
    try {
      final PublicDataManager prefs = PublicDataManager();
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      if (_nameController.text.isNotEmpty) {
        await prefs.saveDataInPrefs(
            data: _nameController.text, key: "userName");
      }

      final String moonImagesPath = path.join(appDocDir.path, "moon", "images");
      final Directory moonImagesDir = Directory(moonImagesPath);

      if (!await moonImagesDir.exists()) {
        await moonImagesDir.create(recursive: true);
      }

      final String profileFilePath =
          path.join(moonImagesPath, "profileName.png");
      final String backgroundFilePath =
          path.join(moonImagesPath, "backgroundName.png");
      if (wasPImageChanged) {
        if (_profileImage != null) {
          await _profileImage!.copy(profileFilePath);
        }
      }
      if (wasBImageChanged) {
        if (_backgroundImage != null) {
          await _backgroundImage!.copy(backgroundFilePath);
        }
      }

      return true;
    } catch (e) {
      log("Error saving images: $e");
      return false;
    }
  }

  Future<bool> loadData() async {
    try {
      final PublicDataManager prefs = PublicDataManager();

      final String? storedName = await prefs.getDataFromPrefs(key: "userName");
      log(storedName.toString());
      if (storedName != null) {
        setState(() {
          _nameController.text = storedName;
        });
      }

      // Retrieve the app's documents directory.
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String moonImagesPath = path.join(appDocDir.path, "moon", "images");

      // Define file paths for the profile and background images.
      final String profileFilePath =
          path.join(moonImagesPath, "profileName.png");
      final String backgroundFilePath =
          path.join(moonImagesPath, "backgroundName.png");

      // Check if the profile image exists and update the state.
      final File profileImageFile = File(profileFilePath);
      if (await profileImageFile.exists()) {
        setState(() {
          _profileImage = profileImageFile;
        });
      }

      // Check if the background image exists and update the state.
      final File backgroundImageFile = File(backgroundFilePath);
      if (await backgroundImageFile.exists()) {
        setState(() {
          _backgroundImage = backgroundImageFile;
        });
      }

      return true;
    } catch (e) {
      log("Error loading data: $e");
      return false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadData();
    getThemeMode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        surfaceTintColor: primaryColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: textColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("Settings"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 20,
          children: [
            Stack(
              children: [
                InkWell(
                  onTap: _pickBackgroundImage,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      image: DecorationImage(
                        image: _backgroundImage != null
                            ? FileImage(_backgroundImage!)
                            : const AssetImage("assets/bg/i2.png")
                                as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: _pickBackgroundImage,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Positioned(
                    top: 70,
                    right: MediaQuery.of(context).size.width * 0.05,
                    left: MediaQuery.of(context).size.width * 0.05,
                    child: Align(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: _pickProfileImage,
                            borderRadius: BorderRadius.circular(50),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundImage: _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : const AssetImage("assets/pro/image.png")
                                      as ImageProvider,
                            ),
                          ),
                          const SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: _pickProfileImage,
                            child: const Text("Change Image"),
                          ),
                        ],
                      ),
                    ))
              ],
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),
            // Save Settings Button
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 1, color: textColor),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () async {
                  try {
                    final res = await saveData();
                    if (!res) {
                      showCustomSnackBar(
                          context: context,
                          message: "An error has occurred",
                          iconColor: Colors.pinkAccent);
                    } else {
                      showCustomSnackBar(
                          context: context,
                          message: "Settings saved successfully",
                          iconColor: Colors.greenAccent);
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    showCustomSnackBar(
                        context: context,
                        message: "An error has occurred",
                        iconColor: Colors.pinkAccent);
                    log("Error saving data: $e");
                  }
                },
                child: Text(
                  "Save Settings",
                  style: GoogleFonts.roboto(
                    color: textColor,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
