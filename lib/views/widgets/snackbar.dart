import 'package:flutter/material.dart';
import 'package:quotes_app/views/themes/colors.dart';

void showSnackbar(BuildContext context, String message, {bool isError = true}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: isError ? MyColors.pink : MyColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(20),
      behavior: SnackBarBehavior.floating,
      content: Text(message),
    ),
  );
}
