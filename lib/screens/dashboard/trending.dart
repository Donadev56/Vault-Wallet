import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/custom/scale_tape/scale.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/screens/dashboard/trending/crypto_trend_view.dart';
import 'package:moonwallet/service/crypto_manager.dart';
import 'package:moonwallet/service/external_data/price_manager.dart';
import 'package:moonwallet/types/news_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/utils/number_formatter.dart';
import 'package:moonwallet/widgets/dialogs/show_standard_sheet.dart';
import 'package:moonwallet/widgets/dialogs/standard_container.dart';
import 'package:moonwallet/widgets/screen_widgets/cached_picture.dart';
import 'package:moonwallet/widgets/screen_widgets/search_text_field.dart';
import 'package:moonwallet/widgets/screen_widgets/standard_app_bar.dart';
import 'package:moonwallet/widgets/screen_widgets/trending_list_title.dart';
import 'package:numeral/numeral.dart';
import 'package:page_transition/page_transition.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:url_launcher/url_launcher.dart';

class TrendingScreen extends StatefulHookConsumerWidget {
  final AppColors colors;
  const TrendingScreen({super.key, required this.colors});

  @override
  ConsumerState<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends ConsumerState<TrendingScreen> {
  AppColors colors = AppColors.defaultTheme;
  final formatter = NumberFormatter();

  @override
  void initState() {
    super.initState();
    colors = widget.colors;
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
    final textTheme = TextTheme.of(context);
    final appUIConfigAsync = ref.watch(appUIConfigProvider);
    final uiConfig = useState<AppUIConfig>(AppUIConfig.defaultConfig);
    final query = useState<String>("");
    final listMarketData = useState<List<CryptoMarketData>>([]);
    final cryptoManager = CryptoManager();
    final news = useState<NewsData?>(null);

    useEffect(() {
      appUIConfigAsync.whenData((data) {
        uiConfig.value = data;
      });
      return null;
    }, [appUIConfigAsync]);

    useEffect(() {
      Future<void> getListMarketData() async {
        try {
          final data = await PriceManager().getListTokensMarketData();
          if (data.isNotEmpty) {
            listMarketData.value = data;
          }
        } catch (e) {
          logError(e.toString());
        }
      }

      getListMarketData();
      return null;
    }, []);
    useEffect(() {
      Future<void> getNewsData() async {
        try {
          final data = await PriceManager().fetchNewsData();
          if (data != null) {
            news.value = data;
          }
        } catch (e) {
          logError(e.toString());
        }
      }

      getNewsData();
      return null;
    }, []);

    double fontSizeOf(double size) {
      return size * uiConfig.value.styles.fontSizeScaleFactor;
    }

    double iconSizeOf(double size) {
      return size * uiConfig.value.styles.iconSizeScaleFactor;
    }

    double roundedOf(double size) {
      return size * uiConfig.value.styles.radiusScaleFactor;
    }

    double imageSizeOf(double size) {
      return size * uiConfig.value.styles.imageSizeScaleFactor;
    }

    List<CryptoMarketData> filteredCryptos() {
      final searchingCryptos = listMarketData.value
          .where((c) =>
              c.name.toLowerCase().contains(query.value.toLowerCase()) ||
              c.symbol.toLowerCase().contains(query.value.toLowerCase()))
          .toList();
      searchingCryptos.sort((a, b) => cryptoManager
          .cleanName(a.symbol)
          .compareTo(cryptoManager.cleanName(b.symbol)));
      return searchingCryptos;
    }

    List<Article> article() {
      final articles = news.value?.data?.list;
      if (articles == null) {
        return [];
      }
      return articles
          .where((e) =>
              e.matchedCurrencies.any((c) =>
                  c.fullName
                      .toLowerCase()
                      .contains(query.value.toLowerCase()) ||
                  c.name.toLowerCase().contains(query.value.toLowerCase())) ||
              e.tags.any(
                  (t) => t.toLowerCase().contains(query.value.toLowerCase())) ||
              e.multilanguageContent
                  .firstWhere((e) => e.language == "en")
                  .title
                  .toLowerCase()
                  .contains(query.toString()) ||
              e.multilanguageContent
                  .firstWhere((e) => e.language == "en")
                  .content
                  .toLowerCase()
                  .contains(query.toString()))
          .toList();
    }

    return DefaultTabController(
        initialIndex: 0,
        length: 2,
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
          child: ColoredBox(
              color: colors.primaryColor,
              child: SafeArea(
                  child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    SizedBox(
                      height: 18,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Column(
                        spacing: 10,
                        children: [
                          SizedBox(
                            height: 40,
                            child: SearchTextField(
                                onSearch: (v) => query.value = v,
                                radius: 8,
                                fontSizeOf: fontSizeOf,
                                colors: colors,
                                roundedOf: roundedOf),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: TabBar(
                                dividerColor: Colors.transparent,
                                unselectedLabelColor: colors.textColor,
                                labelColor: colors.themeColor,
                                indicatorColor: colors.themeColor,
                                tabs: <Widget>[
                                  Tab(
                                    text: "Coins",
                                  ),
                                  Tab(text: "News"),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                        child: TabBarView(children: [
                      Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 15,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Volume",
                                      style: textTheme.bodyMedium?.copyWith(
                                          color: colors.textColor,
                                          fontSize: fontSizeOf(14)),
                                    ),
                                    Text(
                                      "Price",
                                      style: textTheme.bodyMedium?.copyWith(
                                          color: colors.textColor,
                                          fontSize: fontSizeOf(14)),
                                    )
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Expanded(
                                  child: ListView(
                                physics: BouncingScrollPhysics(),
                                children: List.generate(
                                    filteredCryptos().length, (i) {
                                  final marketData = filteredCryptos()[i];

                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: TrendingListTitle(
                                      fontSizeOf: fontSizeOf,
                                      roundedOf: roundedOf,
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            PageTransition(
                                                alignment: Alignment.center,
                                                type: PageTransitionType.theme,
                                                child: CryptoTrendView(
                                                    marketData: marketData,
                                                    colors: colors,
                                                    roundedOf: roundedOf,
                                                    fontSizeOf: fontSizeOf,
                                                    iconSizeOf: iconSizeOf,
                                                    imageSizeOf: imageSizeOf)));
                                      },
                                      icon: CachedPicture(
                                          marketData.image ?? "",
                                          placeHolderString: marketData.symbol,
                                          addSecondaryImage: false,
                                          size: 30,
                                          colors: colors),
                                      name: marketData.symbol.toUpperCase(),
                                      percent:
                                          marketData.priceChangePercentage24h,
                                      price:
                                          "\$${(formatter.formatDecimal((marketData.currentPrice).toString()))}",
                                      volume:
                                          "\$${(marketData.totalVolume ?? 0).numeral()}",
                                      colors: colors,
                                    ),
                                  );
                                }),
                              ))
                            ],
                          )),
                      SingleChildScrollView(
                        physics: BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 10),
                          child: Column(
                            children: List.generate(article().length, (index) {
                              final art = article()[index];
                              final content = art.multilanguageContent
                                  .where((e) => e.language == "en")
                                  .first;
                              final timestamp = art.releaseTime;
                              final tags = art.tags;
                              final author = art.author;
                              final authorAvatar = art.authorAvatarUrl;

                              return ScaleTap(
                                  onPressed: () => showMaterialModalBottomSheet(
                                      isDismissible: false,
                                      enableDrag: false,
                                      context: context,
                                      builder: (context) {
                                        return NewsReaderSpace(
                                            article: art,
                                            colors: colors,
                                            fontSizeOf: fontSizeOf);
                                      }),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(),
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                          color: colors.secondaryColor,
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Column(
                                        children: [
                                          if (authorAvatar != null)
                                            ListTile(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 5,
                                                      horizontal: 2),
                                              visualDensity: VisualDensity(
                                                  vertical: -2, horizontal: -3),
                                              leading: CachedPicture(
                                                authorAvatar,
                                                placeHolderString: author,
                                                size: 40,
                                                colors: colors,
                                                addSecondaryImage: false,
                                              ),
                                              title: buildTitle(context,
                                                  colors: colors,
                                                  title: author,
                                                  fontSizeOf: fontSizeOf,
                                                  fontSize: 12),
                                            ),
                                          SizedBox(
                                            height: 5,
                                          ),
                                          buildTitle(context,
                                              colors: colors,
                                              title: content.title,
                                              fontSizeOf: fontSizeOf,
                                              fontSize: 15),
                                          SizedBox(
                                            height: 15,
                                          ),
                                          ConstrainedBox(
                                              constraints: BoxConstraints(
                                                  maxHeight: 130),
                                              child: Text(
                                                '${html_parser.parse(content.content).body?.text}',
                                                overflow: TextOverflow.ellipsis,
                                              )),
                                          SizedBox(
                                            height: 15,
                                          ),
                                          buildListTags(tags,
                                              context: context, colors: colors),
                                          SizedBox(
                                            height: 5,
                                          ),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              formatTimeElapsed(
                                                  (timestamp / 1000).toInt()),
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                      fontSize: fontSizeOf(10)),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ));
                            }),
                          ),
                        ),
                      )
                    ]))
                  ],
                ),
              ))),
        ));
  }
}

Widget buildTag(BuildContext context, AppColors colors, String tag,
    {Color? bgColor, bool? selected}) {
  final textTheme = TextTheme.of(context);
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: bgColor ?? colors.primaryColor,
    ),
    child: Text(
      tag,
      style: textTheme.bodySmall?.copyWith(
          color: selected == true ? colors.primaryColor : colors.textColor),
    ),
  );
}

Widget buildTitle(BuildContext context,
    {required AppColors colors,
    required String title,
    double fontSize = 18,
    FontWeight? weight,
    required DoubleFactor fontSizeOf}) {
  final textTheme = TextTheme.of(context);
  return Text(
    title,
    style: textTheme.bodyMedium?.copyWith(
        fontWeight: weight ?? FontWeight.w700, fontSize: fontSizeOf(fontSize)),
  );
}

Widget buildListTags(List<String> tags,
    {required BuildContext context,
    required AppColors colors,
    double height = 25,
    Color? color,
    int? selectedIndex,
    void Function(int)? onTap}) {
  return SizedBox(
      height: height,
      child: ListView.separated(
          scrollDirection: Axis.horizontal,
          separatorBuilder: (context, targetIndex) {
            return Padding(padding: const EdgeInsets.symmetric(horizontal: 5));
          },
          itemCount: tags.length,
          itemBuilder: (context, tagsIndex) {
            final tag = tags[tagsIndex];
            return ScaleTap(
                onPressed: () => onTap != null ? onTap(tagsIndex) : null,
                child: buildTag(context, colors, tag,
                    bgColor: selectedIndex != null
                        ? selectedIndex == tagsIndex
                            ? colors.themeColor
                            : color
                        : color,
                    selected: selectedIndex == tagsIndex));
          }));
}

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
                  buildListTags(
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
                    child: buildTitle(context,
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
                  buildListTags(tags,
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
