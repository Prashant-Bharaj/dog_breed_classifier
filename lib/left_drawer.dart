import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_share/flutter_share.dart';

Drawer buildDrawer() {
  return Drawer(
    child: Container(
      child: ListView(
        padding: EdgeInsets.only(top: 20),
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("assets/dog.jpg"), fit: BoxFit.cover),
            ),
            child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Dog breed classifier',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                )),
          ),
          ListTile(
            title: Text(
              'Share with your friends',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            leading: Icon(
              Icons.share,
            ),
            onTap: () {
              share();
            },
          ),
          Divider(
            height: 3,
          ),
          ListTile(
            title: Text(
              'Rate the app',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            leading: Icon(
              Icons.star,
            ),
            onTap: () {
              launch(
                  'https://play.google.com/store/apps/details?id=com.psb.dogbreedclassifier');
            },
          ),
          Divider(
            height: 3,
          ),
          ListTile(
            title: Text(
              'About the developer',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            leading: Icon(
              Icons.developer_mode,
            ),
            onTap: () {
              launch('https://github.com/prashant-bharaj');
            },
          ),
          Divider(
            height: 3,
          ),
        ],
      ),
    ),
  );
}

Future<void> share() async {
  await FlutterShare.share(
      title: 'Hey,I found out a great app!',
      text:
          'Use this app to detect the breed of dog in photos. This app is really awesome.',
      linkUrl:
          'https://play.google.com/store/apps/details?id=com.psb.dogbreedclassifier',
      chooserTitle: 'Hey,I found out a great app!');
}
