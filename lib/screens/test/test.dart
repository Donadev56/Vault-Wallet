import 'package:flutter/material.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/types.dart';

class TestWidget extends StatefulWidget {
  final AppColors colors;
  const TestWidget({super.key, required this.colors});

  @override
  State<TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.colors.primaryColor,
      body: Center(
        child: ElevatedButton(
            onPressed: () => log("clicked"), child: const Text("click")),
      ),
    );
  }
}
