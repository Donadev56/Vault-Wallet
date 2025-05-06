
import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';

class StandardNetworkImage extends StatelessWidget {
  final AppColors colors ;
  final String imageUrl ;
  final double size ;
  const StandardNetworkImage({super.key  , required this.colors, required this.imageUrl, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Image.network(
                                imageUrl,
                                width: size,
                                height: size,
                                fit: BoxFit.cover,
                              ),
                            );
  }
}