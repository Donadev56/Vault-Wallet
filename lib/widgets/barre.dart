import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class DraggableBar extends StatelessWidget {
  final AppColors colors ;
  const DraggableBar({super.key , 
      required this.colors});

  @override
  Widget build(BuildContext context) {
    return     Align(alignment: Alignment.center,
                            child: Container(
                              margin: const EdgeInsets.all(10),
                              height: 7,
                              width: 80,
                              decoration: BoxDecoration(
                                color: colors.secondaryColor,
                                borderRadius: BorderRadius.circular(50)
                              ),

                            ),);

  }
}