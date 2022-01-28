import 'package:dog_breed_classifier/image_page/image_detection.dart';
import 'package:dog_breed_classifier/Widgets/widgets.dart';
import 'package:dog_breed_classifier/themeManager.dart';
import 'package:flutter/material.dart';
import 'authentication/application_state.dart';
import 'authentication/authentication.dart';
import 'uploadui/home.dart';
import 'package:firebase_auth/firebase_auth.dart'; // new
import 'package:firebase_core/firebase_core.dart'; // new
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // new

import 'firebase_options.dart';
import 'authentication/home_page.dart'; // new

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ApplicationState(),
      builder: (context, _) => ChangeNotifierProvider<ThemeNotifier>(
          create: (_) => new ThemeNotifier(),
          child: App()),
  ));
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return  Consumer<ThemeNotifier>(
      builder: (context, theme, child) {
        return MaterialApp(
            theme:  theme.getTheme(),
            debugShowCheckedModeBanner: false,
            // theme: ThemeData.light().copyWith(
            //   primaryColor: Colors.blue,
            //   dividerTheme: DividerThemeData(color: Colors.black54),
            //   iconTheme: IconThemeData(color: Colors.black),
            // ),
            // darkTheme: ThemeData.dark().copyWith(
            //   primaryColor: Colors.blueGrey.shade900,
            //   dividerTheme: DividerThemeData(color: Colors.white),
            //   iconTheme: IconThemeData(color: Colors.white),
            //
            //   buttonTheme: Theme.of(context).buttonTheme.copyWith(
            //     highlightColor: Colors.deepPurple,
            //   ),
            //   visualDensity: VisualDensity.adaptivePlatformDensity,
            // ),
            // theme: theme.getTheme(),


            home: HomePage(theme: theme),
        );
      }
    );
  }
}










