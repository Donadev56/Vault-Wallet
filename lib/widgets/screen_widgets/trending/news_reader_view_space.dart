import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:moonwallet/types/news_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/dialogs/standard_container.dart';
import 'package:moonwallet/widgets/screen_widgets/standard_app_bar.dart';
import 'package:moonwallet/widgets/screen_widgets/trending/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsReaderSpace extends HookConsumerWidget {
  final Article article;
  final AppColors colors;
  final DoubleFactor fontSizeOf;
  const NewsReaderSpace(
      {super.key,
      required this.article,
      required this.colors,
      required this.fontSizeOf});

  @override
  Widget build(BuildContext context, ref) {
    final currentLangue = useState<String>("en");
    final selectedIndex = useState<int>(0);

    MultilanguageContent getContent() {
      return article.multilanguageContent
          .where((e) => e.language == currentLangue.value)
          .first;
    }

    final languages =
        article.multilanguageContent.map((e) => e.language).toList();
    final content = getContent();
    final sourceLink = article.sourceLink;
    final tags = article.tags;

    final textTheme = TextTheme.of(context);

    return SelectableRegion(
        selectionControls: materialTextSelectionControls,
        child: Scaffold(
          backgroundColor: colors.primaryColor,
          appBar: StandardAppBar(
            title: "Back",
            colors: colors,
            fontSizeOf: fontSizeOf,
            centerTitle: false,
          ),
          body: StandardContainer(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TrendingWidgets.buildListTags(
                    languages,
                    context: context,
                    colors: colors,
                    color: colors.secondaryColor,
                    selectedIndex: selectedIndex.value,
                    onTap: (langIndex) {
                      currentLangue.value = languages[langIndex];
                      selectedIndex.value = langIndex;
                    },
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TrendingWidgets.buildTitle(context,
                        colors: colors,
                        title: content.title,
                        fontSizeOf: fontSizeOf),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Html(data: content.content),
                  SizedBox(
                    height: 20,
                  ),
                  TrendingWidgets.buildListTags(tags,
                      context: context,
                      colors: colors,
                      color: colors.secondaryColor),
                  SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () {
                            launchUrl(Uri.parse(sourceLink));
                          },
                          child: Text("By ${article.author}",
                              style: textTheme.bodyMedium?.copyWith(
                                  color: colors.textColor,
                                  fontSize: fontSizeOf(15),
                                  decoration: TextDecoration.underline,
                                  decorationColor: colors.textColor)),
                        )),
                  ),
                  SizedBox(
                    height: 40,
                  )
                ],
              ),
            ),
          ),
        ));
  }
}
