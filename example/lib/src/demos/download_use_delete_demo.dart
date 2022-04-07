import 'dart:async';

import 'package:dynamic_cached_fonts/dynamic_cached_fonts.dart';
import 'package:dynamic_cached_fonts_example/constants.dart';
import 'package:dynamic_cached_fonts_example/src/demos/multi_font_loading_demo.dart';
import 'package:flutter/material.dart';

import '../components.dart';

class DynamicCachedFontsDemo3 extends StatefulWidget {
  const DynamicCachedFontsDemo3({Key? key}) : super(key: key);

  @override
  _DynamicCachedFontsDemo3State createState() =>
      _DynamicCachedFontsDemo3State();
}

class _DynamicCachedFontsDemo3State extends State<DynamicCachedFontsDemo3> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$demoTitle - Custom Controls'),
      ),
      body: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <CustomButton>[
              CustomButton(
                onPressed: handleDownloadButtonPress,
              ),
              CustomButton(
                icon: Icons.font_download,
                title: 'Use Font',
                onPressed: handleUseFontPress,
              ),
              CustomButton(
                icon: Icons.remove_circle,
                title: 'Delete font',
                onPressed: handleDeleteFontPress,
              )
            ],
          ),
          DisplayText(
            'The text is being displayed in the default flutter font which is ${DefaultTextStyle.of(context).style.fontFamily}. '
            'To download $hurricane, click the download button above ☝️.',
            fontFamily: hurricane,
          ),
        ],
      ),
      floatingActionButton: ExtendedButton(
        icon: Icons.navigate_next,
        label: 'Next Example',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<DynamicCachedFontsDemo5>(
            builder: (_) => const DynamicCachedFontsDemo5(),
          ),
        ),
      ),
    );
  }

  Future<void> handleDownloadButtonPress() =>
      DynamicCachedFonts.cacheFont(hurricaneUrl);

  Future<void> handleUseFontPress() async {
    if (await DynamicCachedFonts.canLoadFont(hurricaneUrl)) {
      await DynamicCachedFonts.loadCachedFont(hurricaneUrl,
          fontFamily: hurricane);
      setState(() {});
    } else {
      print('Font not found in cache :(');
      // Font is not in cache...download font or do something else.

      // Uncomment the below line to download font is it is not present in cache.
      // return await DynamicCachedFonts.cacheFont(url);
    }
  }

  //ignore: avoid_void_async
  void handleDeleteFontPress() async {
    await DynamicCachedFonts.removeCachedFont(hurricaneUrl);
  }
}
