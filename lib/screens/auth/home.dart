import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moonwallet/main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0D0D0D),
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          height: height,
          decoration: const BoxDecoration(
              color: Color(0XFF0D0D0D),
              image: DecorationImage(
                  image: AssetImage(
                    "assets/blur/blur.png",
                  ),
                  fit: BoxFit.cover)),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 50),
                    Image.asset(
                      "assets/icon/icon4.png",
                      width: height < 550 ? 210 : 280,
                      height: height < 550 ? 210 : 280,
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
                                      color: Colors.white,
                                      fontWeight: FontWeight.w100),
                                ),
                                TextSpan(
                                  text: "moon crypto wallet".toUpperCase(),
                                  style: GoogleFonts.audiowide(
                                    fontSize: 25,
                                    color: Colors.greenAccent,
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
                            color: Colors.white70,
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
                          Navigator.pushNamed(
                              context, Routes.privateKeyCreator);
                        },
                        icon: const Icon(Icons.add, color: Colors.black),
                        label: Text(
                          "Create a new wallet",
                          style: GoogleFonts.exo2(
                              fontSize: 16, color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
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
                          Navigator.pushNamed(context, Routes.addPrivateKey);
                        },
                        icon:
                            const Icon(Icons.input, color: Colors.greenAccent),
                        label: Text(
                          "Import your wallet",
                          style: GoogleFonts.exo2(
                            fontSize: 16,
                            color: Colors.greenAccent,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.greenAccent),
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
                          color: Colors.white70,
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
      ),
    );
  }
}
