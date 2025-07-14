import 'package:flutter/material.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/screen_widgets/cached_picture.dart';

class CustomNetworkImage extends StatelessWidget {
  final String url;
  final double size;
  final double placeholderSize;
  final bool cover;
  final DoubleFactor imageSizeOf;
  final AppColors colors;
  const CustomNetworkImage(
      {super.key,
      required this.url,
      this.placeholderSize = 30,
      required this.size,
      this.cover = false,
      required this.imageSizeOf,
      required this.colors});

  @override
  Widget build(BuildContext context) {
    return CachedPicture(
      url,
      placeHolderString: "",
      size: size,
      colors: colors,
      addSecondaryImage: false,
    );
  }
}

class UnCachedNetworkImage extends StatelessWidget {
  final AppColors colors;
  final double size;
  final String url;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final BoxFit? fit;

  const UnCachedNetworkImage(
      {super.key,
      required this.size,
      required this.url,
      this.fit,
      this.loadingBuilder,
      this.errorBuilder,
      required this.colors});
  /*Widget buildLoaderBuilder (context, widget, chunk) {
    return  SizedBox(width: size, height: size, child: CircularProgressIndicator(color: colors.textColor,),) ;

  }*/
  Widget buildErrorBuilder(context, obj, trace) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.grayColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Icon(
        Icons.language,
        size: size,
        color: colors.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Image.network(url,
        width: size,
        height: size,
        fit: fit,
        loadingBuilder: loadingBuilder,
        errorBuilder: errorBuilder ?? buildErrorBuilder);
  }
}
