import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quotes_app/controllers/user_controller.dart';
import 'package:quotes_app/views/themes/colors.dart';

import '../templates/welcome_reminder_template.dart';

class NamePage extends ConsumerWidget {
  const NamePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final TextEditingController _nameController = TextEditingController();

    return Scaffold(
      backgroundColor: MyColors.primaryDark,
      body: SafeArea(
        child: Stack(children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AutoSizeText(
                  "Let's take it one step at a time. How do you want to be called?",
                  maxFontSize: 48,
                  minFontSize: 48,
                  maxLines: 3,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.getFont(
                    "Nunito Sans",
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 20.0,
                ),
                AutoSizeText(
                  'Your name will be displayed in your motivational quotes.',
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.getFont(
                    "Nunito Sans",
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(
                  height: 20.0,
                ),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: userState.value?.name ?? 'Your name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32.0),
                    ),
                  ),
                ),
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
                    String nameInput = _nameController.text;
                    if (userState != null) {
                      // TODO: SAVE the name
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const WelcomeReminderTemplate(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(16.0),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(32.0)),
                      )),
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
        ]),
      ),
    );
  }
}
