import 'package:flutter/material.dart';

AppBar header(context,
    {bool isAppTitle = false, required String titleText, removeBackButton = false}) {
  return AppBar(
    automaticallyImplyLeading: removeBackButton ? false : true,
    title: Text(
      isAppTitle ? 'Indian Social Media' : titleText,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: isAppTitle ? 'Signatra' : '',
        fontSize: isAppTitle ? 50 : 22,
      ),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
  );
}
