import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../themes/colors.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 60.0,
              ), // added some padding around the content
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Spacer(), // pushes content to center
                  Expanded(
                    child: AutoSizeText(
                      "Welcome to Snarky Motivation!",
                      maxFontSize: 48,
                      minFontSize: 18,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.getFont(
                        "Nunito Sans",
                        color: MyColors.ink,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ),
                  Expanded(
                    child: AutoSizeText(
                      "A quick daily nudge when motivation needs teeth.",
                      maxLines: 3,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.getFont(
                        "Nunito Sans",
                        color: MyColors.ink,
                        fontSize: 24,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const Spacer(), // pushes content to center
                ],
              ),
            ),
            Positioned(
              left: 30,
              right: 30,
              bottom: 30,
              child: Center(
                child: SizedBox(
                  width:
                      double.infinity, // makes the button expand to full width
                  height: 50.0,
                  child: TextButton(
                    onPressed: () {
                      context.push('/name');
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: MyColors.primary,
                      padding: const EdgeInsets.all(16.0),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(32.0)),
                      ),
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w900,
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
