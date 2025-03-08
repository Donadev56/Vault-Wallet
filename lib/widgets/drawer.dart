import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/main.dart';

class MainDrawer extends StatelessWidget {
  final Color primaryColor;
  final Color textColor;
  final Color surfaceTintColor;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final File? profileImage;
  final File? backgroundImage;
  final String userName;
  final VoidCallback showReceiveModal;
  final VoidCallback showSendModal;
  final bool isDarkMode;
  final VoidCallback toggleMode;

  const MainDrawer({
    super.key,
    required this.primaryColor,
    required this.textColor,
    required this.surfaceTintColor,
    required this.scaffoldKey,
    this.profileImage,
    this.backgroundImage,
    required this.userName,
    required this.showReceiveModal,
    required this.showSendModal,
    required this.isDarkMode,
    required this.toggleMode,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Drawer(
      backgroundColor: primaryColor,
      child: Column(
        children: [
          DrawerHeader(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: surfaceTintColor,
              image: DecorationImage(
                image: backgroundImage != null
                    ? FileImage(backgroundImage!)
                    : AssetImage("assets/bg/i2.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: SizedBox(
                width: width,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Column(
                    spacing: 10,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: profileImage != null
                            ? Image.file(
                                profileImage!,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                "assets/pro/image.png",
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                      ),
                      Text(
                        userName,
                        style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor),
                      ),
                    ],
                  ),
                )),
          ),
          SwitchListTile(
            title: Text(
              isDarkMode ? "Dark Mode" : "Light Mode",
              style: GoogleFonts.roboto(color: textColor),
            ),
            secondary: Icon(
              isDarkMode ? Icons.nights_stay : Icons.wb_sunny,
              color: isDarkMode ? Colors.yellow : Colors.orange,
            ),
            value: isDarkMode,
            onChanged: (bool value) {
              toggleMode();
            },
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: Icon(Icons.explore, color: textColor),
                  title: Text('Discover', style: TextStyle(color: textColor)),
                  onTap: () {
                    Navigator.pushNamed(context, Routes.pageManager,
                        arguments: ({"pageIndex": 1}));
                  },
                ),
                ListTile(
                  leading: Icon(LucideIcons.send, color: textColor),
                  title:
                      Text('Send Crypto', style: TextStyle(color: textColor)),
                  onTap: showSendModal,
                ),
                ListTile(
                  leading: Icon(Icons.call_received, color: textColor),
                  title: Text('Receive Crypto',
                      style: TextStyle(color: textColor)),
                  onTap: showReceiveModal,
                ),
                ListTile(
                  leading: Icon(Icons.settings, color: textColor),
                  title: Text('Settings', style: TextStyle(color: textColor)),
                  onTap: () {
                    Navigator.pushNamed(context, Routes.settings);
                  },
                ),
                const Divider(color: Color.fromARGB(29, 255, 255, 255)),
                ListTile(
                  leading: Icon(Icons.help_outline, color: textColor),
                  title: Text('Help & Support',
                      style: TextStyle(color: textColor)),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: textColor),
                  title: Text('Logout', style: TextStyle(color: textColor)),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
