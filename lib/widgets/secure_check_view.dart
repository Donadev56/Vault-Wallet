import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/func/security/ask_derivate_key.dart';

class SecureCheckView extends HookConsumerWidget {
  final void Function()? onPressed;
  final AppColors colors;

  const SecureCheckView({super.key, required this.colors, this.onPressed});

  @override
  Widget build(BuildContext context, ref) {
    final textTheme = TextTheme.of(context);
    final hasRunCheck = useState(false);

    Future<void> askCred() async {
      try {
        final key = await askDerivateKey(context: context, colors: colors);
        if (key != null) {
          Navigator.pop(context, key);
        }
      } catch (e) {
        logError(e.toString());
      }
    }

    useEffect(() {
      if (!hasRunCheck.value) {
        askCred();
        hasRunCheck.value = true;
      }
      return null;
    }, []);

    return Scaffold(
        backgroundColor: colors.primaryColor,
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 10,
              children: [
                Text(
                  "Enter Passcode",
                  style: textTheme.headlineMedium
                      ?.copyWith(color: colors.textColor, fontSize: 20),
                ),
                IconButton(
                    onPressed: onPressed ?? askCred,
                    icon: Icon(
                      Icons.fingerprint,
                      color: colors.textColor,
                    ))
              ],
            ),
          ),
        ));
  }
}
