import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../pages/name_page.dart';
import '../themes/colors.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.primaryDark, // make sure to define MyColors class with secondary color
      body: SafeArea(
        child: Stack(
          children: [
            Opacity(
              opacity: 1,
              child: Container(
              decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/welcome_background.webp"), // Add your image to the assets folder and reference it here
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                    child: Container(
                      color: MyColors.primaryDark.withOpacity(0.8), // This container holds the blur effect
                    ),
                  ),
            )),
            Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 60.0), // added some padding around the content
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
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ),
                Expanded(
                  child: AutoSizeText(
                    "Sub titlte!!!!!!",
                    maxLines: 3,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.getFont(
                      "Nunito Sans",
                      color: Colors.white,
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
                  width: double.infinity, // makes the button expand to full width
                  height: 50.0,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const NamePage(),
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
                      'Get Started',
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