import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:pinput/pinput.dart';

class PinManagerScreen extends StatefulWidget {
  const PinManagerScreen({super.key});

  @override
  State<PinManagerScreen> createState() => _PinManagerScreenState();
}

final defaultPinTheme = PinTheme(
  width: 56,
  height: 56,
  textStyle: TextStyle(
      fontSize: 20, color: Colors.greenAccent, fontWeight: FontWeight.w600),
  decoration: BoxDecoration(
    border: Border.all(color: Color.fromRGBO(234, 239, 243, 1)),
    borderRadius: BorderRadius.circular(15),
  ),
);

final focusedPinTheme = defaultPinTheme.copyDecorationWith(
  border: Border.all(color: Colors.greenAccent),
  borderRadius: BorderRadius.circular(8),
);

final submittedPinTheme = defaultPinTheme.copyWith(
  decoration: defaultPinTheme.decoration?.copyWith(
      color: Colors.transparent,
      border: Border.all(width: 3, color: Colors.greenAccent)),
);

class _PinManagerScreenState extends State<PinManagerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0XFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Color(0XFF0D0D0D),
        automaticallyImplyLeading: false,
        title: Text(
          'Create a password',
          style: GoogleFonts.exo(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(),
              Pinput(
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: submittedPinTheme,
                validator: (s) {
                  return s == '2222' ? null : 'Pin is incorrect';
                },
                pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                showCursor: true,
                onCompleted: (pin) => log(pin),
              )
            ],
          ),
        ),
      ),
    );
  }
}
