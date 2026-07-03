import 'dart:io';

import 'package:appinio_social_share/appinio_social_share.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

import '../models/quote_model.dart';
import '../views/widgets/quot_widget_share.dart';

Future<void> shareQuoteImage(BuildContext context, Quote quote) async {
  final imageBytes = await ScreenshotController().captureFromWidget(
    QuotWidgetShare(
      quote: quote,
      height: 512,
      width: 512,
    ),
    context: context,
    targetSize: const Size(512, 512),
    pixelRatio: 3,
  );
  final directory = await getTemporaryDirectory();
  final file = File(
    '${directory.path}/quote_${DateTime.now().microsecondsSinceEpoch}.png',
  );

  await file.writeAsBytes(imageBytes, flush: true);

  final share = AppinioSocialShare();
  if (Platform.isIOS) {
    await share.iOS.shareToSystem(quote.content, filePaths: [file.path]);
    return;
  }
  if (Platform.isAndroid) {
    await share.android.shareToSystem('Quote', quote.content, file.path);
    return;
  }

  throw UnsupportedError('Native sharing is available on iOS and Android.');
}
