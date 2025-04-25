import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/types/types.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

class InterfaceSizeView extends StatefulHookConsumerWidget {
  final AppColors colors ;

  const InterfaceSizeView({super.key , required this.colors});

  @override
  ConsumerState<InterfaceSizeView> createState() => _InterfaceSizeViewState();
}


class _InterfaceSizeViewState extends ConsumerState<InterfaceSizeView> {
 AppColors colors  = AppColors.defaultTheme;
  @override
void initState() {
  super.initState();
  colors = widget.colors ;
  
}
  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    final uiConfig = useState<AppUIConfig>(AppUIConfig.defaultConfig);
    final appUIConfigAsync = ref.watch(appUIConfigProvider);
    final appUIConfigNotifier = ref.watch(appUIConfigProvider.notifier);

    final fontSizeFactor = uiConfig.value.styles.fontSizeScaleFactor;


     useEffect(() {
      appUIConfigAsync.whenData((data) {
        uiConfig.value = data;
      });
      return null;
    }, [appUIConfigAsync]);
    Future<void> updateUI ({double ? fontSize}) async {
      try {
        final res = await appUIConfigNotifier.updateAppUIConfig(styles: uiConfig.value.styles.copyWith(fontSizeScaleFactor: fontSize, ));
        if (res) {
          log("Edited ");
        }
        
      } catch (e) {
        logError(e.toString());
        
      }

    }
         double iconSizeOf(double size) {
      return size * uiConfig.value.styles.iconSizeScaleFactor;
    }

    double imageSizeOf(double size) {
      return size * uiConfig.value.styles.imageSizeScaleFactor;
    }

    double borderOpOf(double border) {
      return border * uiConfig.value.styles.borderOpacity;
    }

    double roundedOf(double size) {
      return size * uiConfig.value.styles.radiusScaleFactor;
    }


     double fontSizeOf(double size) {
      return size * uiConfig.value.styles.fontSizeScaleFactor;
    }



    return Scaffold(
      backgroundColor: colors.primaryColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: colors.primaryColor,
        leading: IconButton(onPressed: ()=> Navigator.pop(context), icon: Icon(Icons.arrow_back, color: colors.textColor,)) ,
        title: Text("Interface", style: textTheme.bodyMedium?.copyWith(
          fontSize: fontSizeOf(20),
          color: colors.textColor
        ),),


      ),

      body: Padding(padding: const EdgeInsets.all(20),
      child: ListView(
        children: [

              Text(
              "Interface",
              style: textTheme.headlineMedium?.copyWith(
                  color: colors.textColor,
                  fontSize: fontSizeOf(20),
                  fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 15,),

            Text("Edit Font Size", style: textTheme.bodyMedium?.copyWith(
              color: colors.textColor.withValues(alpha: 0.8),
              fontSize: fontSizeOf(15)
              
            ),),
            SizedBox(height: 10,),

            SfSlider(
              shouldAlwaysShowTooltip: true,
              showLabels: true,
              value: fontSizeFactor , onChanged: (v) async{
              await updateUI(fontSize: v);

            }, min: 0.7, max: 1.4,)


        ],
      ) ,),

    );
  }
}