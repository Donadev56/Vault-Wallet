import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
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
        child: Text("Trending"),
      ),
    );
  }
}
