import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';

class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  AppColors colors = AppColors.defaultTheme;

  @override
  void initState() {
    super.initState();
    getSavedTheme();
  }

  Future<void> getSavedTheme() async {
    final manager = ColorsManager();
    final savedTheme = await manager.getDefaultTheme();
    setState(() {
      colors = savedTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors.primaryColor,
      body: Center(
        child: Text("Swap"),
      ),
    );
  }
}
