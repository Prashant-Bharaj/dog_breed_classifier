import 'package:dog_breed_classifier/themeManager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'application_state.dart';
import 'authentication.dart';
import '../uploadui/home.dart';

class HomePage extends StatelessWidget {
  final ThemeNotifier theme;
  const HomePage({Key? key, required this.theme}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Consumer<ApplicationState>(
        //Navigator.pushReplacementNamed(context, '/HomeScreen')
        builder: (context, appState, _) => (
            appState.loginState == ApplicationLoginState.loggedIn) ? MyHomePage(theme) : Authentication(
          email: appState.email,
          loginState: appState.loginState,
          startLoginFlow: appState.startLoginFlow,
          verifyEmail: appState.verifyEmail,
          signInWithEmailAndPassword: appState.signInWithEmailAndPassword,
          cancelRegistration: appState.cancelRegistration,
          registerAccount: appState.registerAccount,
          signOut: appState.signOut,
        ),
      ),
    );
  }
}