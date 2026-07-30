import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

import '../models/quote_model.dart';
import '../views/widgets/quot_widget_share.dart';

const _nativeShareChannel = MethodChannel('com.mars6.noexcuse/share');

Future<void> shareNativeQuote(String text, String filePath) =>
    _nativeShareChannel.invokeMethod('share', {
      'text': text,
      'filePath': filePath,
    });

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

  if (kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.iOS &&
          defaultTargetPlatform != TargetPlatform.android)) {
    throw UnsupportedError('Native sharing is available on iOS and Android.');
  }
  await shareNativeQuote(quote.content, file.path);
}
