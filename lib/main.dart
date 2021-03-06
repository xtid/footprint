import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:footprint/pages/home.dart';

import 'package:footprint/api/http.dart';

void main() {
  dio.options.connectTimeout = 12000000;
  dio.options.receiveTimeout = 12000000;
  dio.options.baseUrl = '';
  runApp(FootprintApp());
}

class FootprintApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: Colors.white,
        ),
        home: Home(id: '', name: '生活'),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          const Locale('zh', ''),
        ],
      )
    );
  }
}