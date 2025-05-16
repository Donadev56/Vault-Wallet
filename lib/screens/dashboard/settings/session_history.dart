import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/types/types.dart' as types;
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/widgets/dialogs/row_details.dart';
import 'package:moonwallet/widgets/screen_widgets/standard_app_bar.dart';

class SessionHistoryView extends StatefulHookConsumerWidget {
  final AppColors colors;

  const SessionHistoryView({super.key, required this.colors});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SessionHistoryViewState();
}

class _SessionHistoryViewState extends ConsumerState<SessionHistoryView> {
  AppColors colors = AppColors.defaultTheme;
  @override
  void initState() {
    super.initState();
    colors = widget.colors;
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionProviderNotifier);
    final sessionNotifier = ref.watch(sessionProviderNotifier.notifier);
    final sessionsState = useState<List<LocalSession>>([]);
    final uiConfig =
        useState<types.AppUIConfig>(types.AppUIConfig.defaultConfig);

    useEffect(() {
      Future<void> getSavedSessions() async {
        try {
          sessionsState.value = await sessionNotifier.getListSessions();
        } catch (e) {
          logError(e.toString());
        }
      }

      getSavedSessions();
      return null;
    }, [sessionAsync]);

    double fontSizeOf(double size) {
      return size * uiConfig.value.styles.fontSizeScaleFactor;
    }

    final textTheme = TextTheme.of(context);
    return Scaffold(
      backgroundColor: colors.primaryColor,
      appBar: StandardAppBar(
          title: "Session history", colors: colors, fontSizeOf: fontSizeOf),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView(
          children: [
            Text(
              "Secure Session History",
              textAlign: TextAlign.start,
              style: textTheme.bodyMedium?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colors.textColor),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              "When the password is enabled at startup, we activate a system that monitors your session and records a trace of that session so you can check your activity later.",
              textAlign: TextAlign.start,
              style: textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: colors.textColor.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(
              height: 15,
            ),
            Column(
              children: List.generate(sessionsState.value.length, (index) {
                final sortedSessions  = sessionsState.value..sort((a , b)=> b.startTime.compareTo(a.startTime));
                final session = sortedSessions[index];
                final sessionDate = DateTime.fromMillisecondsSinceEpoch(
                    session.startTime * 1000);
                String nowDate =
                    DateFormat("dd-MM-yyyy").format(DateTime.now());
                String formattedDate =
                    DateFormat('dd-MM-yyyy').format(sessionDate);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        tileColor: colors.secondaryColor.withValues(alpha: 0.9),
                        onTap: () {
                          showDialog(
                            
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  backgroundColor: colors.primaryColor,
                                  title: Column(
                                    spacing: 10,
                                    children: [
                                      Row(
                                        spacing: 10,
                                        children: [
                                          Icon(
                                            Icons.schedule,
                                            color: colors.textColor,
                                          ),
                                          Text(
                                            "${formatTimeElapsed(session.startTime)} ago",
                                            style: textTheme.bodyMedium
                                                ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 15,
                                                    color: colors.textColor),
                                          ),
                                        ],
                                      ),
                                      Divider(
                                        color: colors.secondaryColor,
                                      ),
                                    ],
                                  ),
                                  content: ListView(
                                    shrinkWrap: true,
                                    children: [
                                      RowDetailsContent(
                                          copyOnClick: true,
                                          colors: colors,
                                          name: "Id",
                                          value: session.sessionId),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      RowDetailsContent(
                                          copyOnClick: true,
                                          colors: colors,
                                          name: "Authentication",
                                          value: session.isAuthenticated
                                              .toString()),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      RowDetailsContent(
                                          copyOnClick: true,
                                          colors: colors,
                                          name: "Session Key",
                                          value: session.sessionKey.derivateKey
                                              .toString()),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      RowDetailsContent(
                                          copyOnClick: true,
                                          colors: colors,
                                          name: "Session Salt",
                                          value: base64Encode(
                                              session.sessionKey.salt)),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      RowDetailsContent(
                                          copyOnClick: true,
                                          colors: colors,
                                          name: "Start timestamp",
                                          value: session.startTime.toString()),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      RowDetailsContent(
                                          copyOnClick: true,
                                          colors: colors,
                                          name: "End timestamp",
                                          value: session.endTime.toString()),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      RowDetailsContent(
                                          copyOnClick: true,
                                          colors: colors,
                                          name: "Has expired",
                                          value: session.hasExpired.toString()),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                        style: TextButton.styleFrom(
                                            backgroundColor: colors.textColor,
                                            foregroundColor:
                                                colors.primaryColor),
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(
                                          "Ok",
                                          style: textTheme.bodyMedium?.copyWith(
                                              color: colors.primaryColor,
                                              fontSize: fontSizeOf(15),
                                              fontWeight: FontWeight.w400),
                                        ))
                                  ],
                                );
                              });
                        },
                        visualDensity: VisualDensity.compact,
                        title: Text(
                          "${formattedDate.toLowerCase().trim() == nowDate.toLowerCase().trim() ? "Today" : formattedDate}'s session",
                          style: textTheme.bodyMedium?.copyWith(
                              fontSize: fontSizeOf(15),
                              color: colors.textColor),
                        ),
                        subtitle: Text(
                          "Duration ${session.endTime - session.startTime} seconds",
                          style: textTheme.bodySmall?.copyWith(
                              fontSize: fontSizeOf(13),
                              color: colors.textColor.withValues(alpha: 0.7)),
                        ),
                      )),
                );
              }),
            )
          ],
        ),
      ),
    );
  }
}
