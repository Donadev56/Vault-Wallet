import 'package:flutter/material.dart';
import 'package:moonwallet/custom/cached_image/cached_image.dart';
import 'package:moonwallet/types/types.dart';

class CachedPicture extends StatelessWidget {
  final double size;
  final String placeHolderString;
  final AppColors colors;
  final Color? primaryColor;
  final double radius;
  final double networkRadius;
  final String mainImageUrl;
  final String? secondaryImageUrl;
  final bool addSecondaryImage;

  const CachedPicture(this.mainImageUrl,
      {super.key,
      required this.placeHolderString,
      this.secondaryImageUrl,
      this.primaryColor,
      required this.size,
      this.radius = 50,
      this.networkRadius = 5,
      this.addSecondaryImage = true,
      required this.colors});

  @override
  Widget build(BuildContext context) {
    errorBuilder(double targetSize) {
      return ((context, obj, trace) {
        return buildPlaceHolder(
            placeHolderString.length > 2
                ? placeHolderString.substring(0, 2)
                : placeHolderString,
            size,
            radius,
            colors,
            context);
      });
    }

    /* Widget buildSkeleton(size) {
      return Skeletonizer(
        enabled: true,
        containersColor: colors.grayColor,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(),
        ),
      );
    }*/

    bool isSvg(String path) {
      return path.toLowerCase().endsWith('.svg');
    }

    return Stack(
      children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: SizedBox(
                    width: size,
                    height: size,
                    child: CustomNetworkCachedImage(
                      isSvgImage: isSvg(mainImageUrl),
                      errorWidget: buildPlaceHolder(
                          placeHolderString.length > 2
                              ? placeHolderString.substring(0, 2)
                              : placeHolderString,
                          size,
                          radius,
                          colors,
                          context),
                      mainImageUrl,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                    )))),
        if (addSecondaryImage)
          Positioned(
              top: size / 1.8,
              left: size / 1.8,
              child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(networkRadius),
                    color: primaryColor ?? colors.primaryColor,
                  ),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(networkRadius),
                      child: CustomNetworkCachedImage(
                        errorWidget: buildPlaceHolder(
                            '', size / 2.75, radius, colors, context),
                        isSvgImage: isSvg(secondaryImageUrl ?? ""),
                        secondaryImageUrl ?? "",
                        width: size / 2.75,
                        height: size / 2.75,
                        errorBuilder: errorBuilder(size / 2.75),
                        fit: BoxFit.cover,
                      ))))
      ],
    );
  }
}

Widget buildPlaceHolder(
  String symbol,
  double size,
  double radius,
  AppColors colors,
  BuildContext context,
) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
        color: colors.textColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(radius)),
    child: Center(
      child: Text(
        symbol,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18),
      ),
    ),
  );
}
