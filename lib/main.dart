import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:url_launcher/url_launcher.dart';

import 'face_detection_camera.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.blue,
        dividerTheme: DividerThemeData(color: Colors.black54),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueGrey.shade900,
        dividerTheme: DividerThemeData(color: Colors.white),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _loading;
  List _outputs;
  File _image;
  void initState() {
    super.initState();
    _loading = true;
    loadModel().then((value) {
      setState(() {
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
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

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
    );
  }

  Future pickImage() async {
    var image = await ImagePicker().getImage(source: ImageSource.gallery);
    if (image == null) return null;
    setState(() {
      _loading = true;
      //Declare File _image in the class which is used to display the image on the screen.
      _image = File(image.path);
    });
    classifyImage(File(image.path));
  }

  classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 1,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _loading = false;
      //Declare List _outputs in the class which will be used to show the classified classs name and confidence
      _outputs = output;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
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
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
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
      ),
      appBar: AppBar(
        title: Text("Dog breed classifier"),
        centerTitle: true,
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          FloatingActionButton(
            heroTag: null,
            onPressed: () => pickImage(),
            child: Icon(Icons.image),
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            heroTag: null,
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (BuildContext context) {
                return FaceDetectionFromLiveCamera();
              }));
            },
            child: Icon(Icons.camera),
          ),
        ],
      ),
      body: _loading
          ? Container(
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            )
          : Container(
              width: MediaQuery.of(context).size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _image == null
                      ? Container()
                      : Image.file(_image,
                          fit: BoxFit.contain,
                          height: MediaQuery.of(context).size.height * 0.6),
                  SizedBox(
                    height: 10,
                  ),
                  _outputs != null
                      ? Column(
                          children: <Widget>[
                            Text(
                              "${_outputs[0]["label"]}",
                              style: TextStyle(
                                fontSize: 25.0,
                              ),
                            ),
                            Text(
                              "${(_outputs[0]["confidence"] * 100).toStringAsFixed(0)}%",
                              style: TextStyle(fontSize: 20),
                            )
                          ],
                        )
                      : Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  "Choose a photo from gallery or use the live camera feed to detect breed",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Container(),
                              SizedBox(height: 20),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Text(
                                  "Note:the model is not 100% correct",
                                  style: TextStyle(fontSize: 20),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            ],
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}