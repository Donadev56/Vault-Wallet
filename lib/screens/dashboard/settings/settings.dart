import 'package:flutter/material.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/custom_options.dart';

class SettingsPage extends StatefulWidget {
  final AppColors colors ;
  const SettingsPage({super.key , required this.colors});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AppColors  colors = AppColors.defaultTheme;

  @override 
  void initState() {
    super.initState();
    colors = widget.colors ;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
      final options = [
    {
     "title" : "Appearance",
     "description" : "Change the appearance of the application according to your preferences.",
     "elements" : [
      {
        "name" : "Change App Theme",
        "icon" : Icon(Icons.palette, color: colors.textColor,),
        "onPressed" : ()=> log("Hello world")
      },
       {
        "name" : "Interface size",
        "icon" : Icon(Icons.format_size, color: colors.textColor,),
        "onPressed" : ()=> log("Hello world")
      }, 
     ]
    },

    {
     "title" : "Security",
     "elements" : [
      {
        "name" : "Enable biometric",
        "icon" : Icon(Icons.fingerprint, color: colors.textColor,),
        "onPressed" : ()=> log("Hello world"),
        "trailing" : Switch(value: false, onChanged: (v){
          log("New value");
        }, )
      },
       {
        "name" : "Lock app on launch",
        "icon" : Icon(Icons.lock, color: colors.textColor,),
        "onPressed" : ()=> log("Hello world"),
        "trailing" : Switch(value: false, onChanged: (v){
          log("New value $v");
        }, )
      }, 
     ]
    }
  ];
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading:IconButton(icon: Icon(Icons.arrow_back , color : colors.textColor) , onPressed: () => Navigator.pop(context),) ,
        title: Text("Settings", style: textTheme.bodyMedium?.copyWith(
          color: colors.textColor,
          fontSize: 20
          
        ),
        ),
      ),
      body:Padding(padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text("Settings", style: textTheme.headlineMedium?.copyWith(
              color: colors.textColor,
              fontSize: 20,fontWeight: FontWeight.bold
            ),),

            SizedBox(height: 15,),

            Column(
              children: List.generate(options.length, (i) {
                final option = options[i];
                final title = option["title"] as String;
                final desc = option["description"] as String?;
                final elements = option["elements"] as List<dynamic>;

                return Padding(padding: const EdgeInsets.symmetric(vertical:10),
                child : CustomOptionWidget(
                  description: desc,
                  
                  shapeBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)
                  ),
                  colors: colors, spaceName:title , spaceNameStyle: textTheme.bodyMedium?.copyWith(
                  color: colors.textColor,
                  fontWeight: FontWeight.bold,


                ) ?? TextStyle(), options: List.generate(elements.length, (i) {
                  final element = elements[i];
                  final name = element["name"];
                  final icon = element["icon"];
                  final trailing = element["trailing"];


                  return Option(title: name, icon: icon, trailing: trailing ?? Icon(
                                    Icons.chevron_right,
                                    color: colors.textColor.withOpacity(0.5),
                                  ) , color: colors.secondaryColor);

                }), onTap: (_) {})) ;

              }),
              )

          
          ],
        ),),
        
    );
  }
}