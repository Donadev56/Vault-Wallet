import 'package:flutter/material.dart';
import 'package:moonwallet/types/browser.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/func/discover/listeTitle_description.dart';
import 'package:moonwallet/widgets/func/discover/network_image.dart';

class DappsViewList extends StatelessWidget {
  final Category category;
  final AppColors colors;
  final DoubleFactor fontSizeOf;
  final DoubleFactor imageSizeOf;
  final List<DApp> primaryDapps;
  final List<DApp> nonPrimaryDapps;
  final void Function(DApp)? onSelect;

  const DappsViewList({
    super.key,
    required this.category,
    required this.colors,
    required this.fontSizeOf,
    required this.imageSizeOf,
    required this.nonPrimaryDapps,
    required this.primaryDapps,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
      child: Column(
        spacing: 10,
        children: [
          Column(
            spacing: 10,
            children: [
              Row(
                spacing: 10,
                children: [
                  CustomNetworkImage(
                    url: category.iconUrl,
                    size: 30,
                    imageSizeOf: imageSizeOf,
                    colors: colors,
                  ),
                  Text(
                    category.name,
                    style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textColor,
                        fontSize: fontSizeOf(18)),
                  )
                ],
              ),
              Text(
                category.description,
                style: textTheme.bodyMedium?.copyWith(
                    fontSize: fontSizeOf(14),
                    color: colors.textColor.withValues(alpha: 0.7)),
              )
            ],
          ),
          Column(
            children: List.generate(primaryDapps.length, (primaryIndex) {
              final currentDapp = primaryDapps[primaryIndex];
              return ListTitleDescription(
                imageSizeOf: imageSizeOf,
                description: currentDapp.description,
                imageUrl: currentDapp.imageUrl,
                title: currentDapp.name,
                fontSizeOf: fontSizeOf,
                colors: colors,
                onTap: () => onSelect != null ? onSelect!(currentDapp) : null,
              );
            }),
          ),
          SizedBox(
            height: 10,
          ),
          SizedBox(
            height: 100,
            child: ListView.separated(
              separatorBuilder: (context, index) {
                return Padding(padding: const EdgeInsets.all(5));
              },
              scrollDirection: Axis.horizontal,
              itemCount: nonPrimaryDapps.length,
              itemBuilder: (context, nonPrimaryIndex) {
                final currentNonPrimary = nonPrimaryDapps[nonPrimaryIndex];

                return Material(
                    color: colors.secondaryColor,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onSelect != null
                          ? onSelect!(currentNonPrimary)
                          : null,
                      child: Container(
                        width: 100,
                        height: 100,
                        padding: const EdgeInsets.all(10),
                        child: Align(
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 5,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: CustomNetworkImage(
                                  url: currentNonPrimary.imageUrl,
                                  size: 50,
                                  cover: true,
                                  imageSizeOf: imageSizeOf,
                                  colors: colors,
                                ),
                              ),
                              Text(
                                currentNonPrimary.name,
                                style: textTheme.bodyMedium?.copyWith(
                                    fontSize: fontSizeOf(12),
                                    overflow: TextOverflow.ellipsis,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ));
              },
            ),
          )
        ],
      ),
    );
  }
}
