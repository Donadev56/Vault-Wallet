import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/add_mnemonic.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/create_mnemonic_key.dart';
import 'package:moonwallet/types/types.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final colors = AppColors.defaultTheme;
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: colors.primaryColor,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors.primaryColor,
      body: SingleChildScrollView(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const SizedBox(height: 50),
                  Image.asset(
                    "assets/logo/png/v_png.png",
                    width: 300,
                    height: 300,
                  ),
                  const SizedBox(height: 20),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Welcome to the \n",
                                style: GoogleFonts.exo2(
                                    fontSize: 23,
                                    color: colors.textColor,
                                    fontWeight: FontWeight.w100),
                              ),
                              TextSpan(
                                text: "Vault crypto wallet".toUpperCase(),
                                style: GoogleFonts.audiowide(
                                  fontSize: 25,
                                  color: colors.textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Create or import your account to start using the wallet securely.",
                      style: GoogleFonts.exo2(
                          fontSize: 16,
                          color: colors.textColor.withValues(alpha: 0.7),
                          decoration: TextDecoration.none),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 17,
              ),
              // Bottom part with buttons and link
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (ctx) => CreateMnemonicMain()));
                      },
                      icon: Icon(Icons.add, color: colors.primaryColor),
                      label: Text(
                        "Create a new wallet",
                        style: GoogleFonts.exo2(
                            fontSize: 16, color: colors.primaryColor),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.themeColor,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (ctx) => AddMnemonicScreen()));
                      },
                      icon: Icon(Icons.input, color: colors.themeColor),
                      label: Text(
                        "Import your wallet",
                        style: GoogleFonts.exo2(
                          fontSize: 16,
                          color: colors.themeColor,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.themeColor),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      "Read terms and conditions",
                      style: GoogleFonts.exo2(
                        fontSize: 14,
                        color: colors.textColor.withValues(alpha: 0.7),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
