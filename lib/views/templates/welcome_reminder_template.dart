import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quotes_app/views/templates/subscription_page_template.dart';
import 'package:quotes_app/widgets/reminder.dart';

import '../themes/colors.dart';

class WelcomeReminderTemplate extends StatelessWidget {
  const WelcomeReminderTemplate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.primaryDark, // make sure to define MyColors class with secondary color
      body: SafeArea(
        child: Stack(
          children: [
            Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 60.0), // added some padding around the content
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
AutoSizeText(
                    "Welcome to !",
                    maxFontSize: 48,
                    minFontSize: 18,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.getFont(
                      "Nunito Sans",
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 50),
  ReminderWidget()
              ],
            ),
          ),
          Positioned(
              left: 30,
              right: 30,
              bottom: 30,
              child: Center(
                child: SizedBox(
                  width: double.infinity, // makes the button expand to full width
                  height: 50.0,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SubscriptionPage(),
                          ),
                        );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(16.0),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(32.0)),
                      )
                      ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          
          ],
        ),
      ),
    );
  }
}