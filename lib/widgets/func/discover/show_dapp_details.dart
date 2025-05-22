import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:moonwallet/types/browser.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/widgets/buttons/elevated.dart';
import 'package:moonwallet/widgets/dialogs/show_standard_sheet.dart';
import 'package:moonwallet/widgets/dialogs/standard_container.dart';
import 'package:moonwallet/widgets/func/discover/column_details.dart';
import 'package:moonwallet/widgets/func/discover/labeled_check_box.dart';
import 'package:moonwallet/widgets/func/discover/network_image.dart';
import 'package:moonwallet/widgets/screen_widgets/crypto_picture.dart';

Future<bool> showDappDetails({
  required DApp app,
  required BuildContext context,
  required AppColors colors,
  required DoubleFactor imageSizeOf,
  required DoubleFactor fontSizeOf,
}) async {
  final networks = app.ecosystems.where((e) => e.isNative).toList();
  final categories = app.categories;
  bool doNotShow = false;
  return await showStandardModalBottomSheet<bool?>(
          context: context,
          builder: (context) {
            final textTheme = TextTheme.of(context);
            return StatefulBuilder(builder: (ctx, st) {
              return Material(
                child: StandardContainer(
                  backgroundColor: colors.primaryColor,
                  padding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.only(
                            left: 10, right: 0, top: 0, bottom: 0),
                        visualDensity: VisualDensity.compact,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: CustomNetworkImage(
                            url: app.imageUrl,
                            size: 30,
                            imageSizeOf: imageSizeOf,
                            colors: colors,
                            cover: true,
                          ),
                        ),
                        title: Text(
                          app.name,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.textColor,
                            fontSize: fontSizeOf(15),
                          ),
                        ),
                        subtitle: Text(
                          "Provided by ${app.websiteUrl}",
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                              color: colors.textColor.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: fontSizeOf(12)),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            FeatherIcons.x,
                            color: colors.textColor,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        app.description,
                        style: textTheme.bodyMedium?.copyWith(
                            fontSize: fontSizeOf(12),
                            fontWeight: FontWeight.w400),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      ColumnDetails(
                          title: "Networks",
                          colors: colors,
                          fontSizeOf: fontSizeOf,
                          value: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children:
                                    List.generate(networks.length, (index) {
                                  if (index == 4) {
                                    return Icon(
                                      Icons.more_horiz,
                                      color: colors.textColor,
                                    );
                                  }
                                  if (index > 4) {
                                    return SizedBox();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    child: CryptoPicture(
                                        crypto: networks[index],
                                        size: 25,
                                        colors: colors),
                                  );
                                }),
                              ))),
                      SizedBox(
                        height: 15,
                      ),
                      ColumnDetails(
                        title: "Categories",
                        colors: colors,
                        fontSizeOf: fontSizeOf,
                        value: Wrap(
                          spacing: 5,
                          children: List.generate(categories.length, (index) {
                            final cat = categories[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 15),
                              decoration: BoxDecoration(
                                  color: colors.secondaryColor,
                                  borderRadius: BorderRadius.circular(5)),
                              child: Text(
                                cat.name,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontSize: fontSizeOf(12),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      LabeledCheckbox(
                        label: RichText(
                          text: TextSpan(
                            style: textTheme.bodyMedium?.copyWith(
                                color: colors.textColor,
                                fontSize: fontSizeOf(12)),
                            children: [
                              TextSpan(
                                text: "Read and agree with ",
                              ),
                              TextSpan(
                                text: "Risk Statement",
                                style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w400,
                                    color: colors.themeColor,
                                    fontSize: fontSizeOf(12)),
                              ),
                            ],
                          ),
                        ),
                        onChanged: (v) => (),
                        value: true,
                      ),
                      LabeledCheckbox(
                        value: doNotShow,
                        onChanged: (v) {
                          doNotShow = v;
                          st(() {});
                        },
                        label: Text(
                          "Do not show again ",
                          style: textTheme.bodyMedium?.copyWith(
                              color: colors.textColor,
                              fontSize: fontSizeOf(12)),
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: CustomElevatedButton(
                          text: "Enter ${app.name}",
                          onPressed: () async {
                            await PublicDataManager().saveDataInPrefs(
                                data: doNotShow ? "true" : "false",
                                key:
                                    "Do-not-show-again-dapp-modal-for/${app.websiteUrl}");
                            Navigator.pop(context, true);
                          },
                          colors: colors,
                          rounded: 3,
                          padding: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 10),
                          textStyle: textTheme.bodyMedium?.copyWith(
                              color: colors.primaryColor,
                              fontWeight: FontWeight.w400),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              );
            });
          }) ??
      false;
}
