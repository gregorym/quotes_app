import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quotes_app/controllers/user_controller.dart';
import 'package:quotes_app/views/themes/colors.dart';

class NamePage extends ConsumerStatefulWidget {
  const NamePage({super.key});

  @override
  ConsumerState<NamePage> createState() => _NamePageState();
}

class _NamePageState extends ConsumerState<NamePage> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your name to continue.')),
      );
      return;
    }

    await UserController().updateUserName(name);
    ref.invalidate(userProvider);

    if (!mounted) return;
    context.push('/welcome-reminder');
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: MyColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AutoSizeText(
                    "Let's take it one step at a time. How do you want to be called?",
                    maxFontSize: 48,
                    minFontSize: 30,
                    maxLines: 3,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.getFont(
                      "Nunito Sans",
                      color: MyColors.ink,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  AutoSizeText(
                    'Your name will be displayed in your motivational quotes.',
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.getFont(
                      "Nunito Sans",
                      color: MyColors.ink,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _continue(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: MyColors.surface,
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
                  width: double.infinity,
                  height: 50.0,
                  child: TextButton(
                    onPressed: userState.isLoading ? null : _continue,
                    style: TextButton.styleFrom(
                      backgroundColor: MyColors.primary,
                      padding: const EdgeInsets.all(16.0),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(32.0)),
                      ),
                    ),
                    child: const Text(
                      'Continue',
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
