import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import 'dart:async';
import 'dart:io';
import 'package:dog_breed_classifier/utility/model_loading.dart';
import 'first_page.dart';
import 'left_drawer.dart';
import 'video_page/live_detection.dart';

import 'package:flutter/cupertino.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late bool _loading;
  List? _outputs;
  File? _image;

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

  Future pickImage() async {
    var image = await ImagePicker().getImage(source: ImageSource.gallery);
    setState(() {
      _loading = true;
      //Declare File _image in the class which is used to display the image on the screen.
      _image = File(image!.path);
    });
    var output = await Tflite.runModelOnImage(
      path: File(image!.path).path,
      numResults: 1,
      threshold: 0.0,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _loading = false;
      //Declare List _outputs in the class which will be used to show the classified classs name and confidence
      _outputs = output!;
    });
  }
  GlobalKey key = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: buildDrawer(),
      appBar: AppBar(
        title: Text("Dog breed classifier"),
        centerTitle: true,
      ),
      floatingActionButton: buildFloatingButton(context),
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
                      : Image.file(_image!,
                          fit: BoxFit.contain,
                          height: MediaQuery.of(context).size.height * 0.6),
                  SizedBox(
                    height: 10,
                  ),
                  (_outputs != null && _outputs!.length > 0)
                      ? Column(
                          children: <Widget>[
                            Text(
                              "${_outputs![0]["label"]}",
                              style: TextStyle(
                                fontSize: 25.0,
                              ),
                            ),
                            Text(
                              "${(_outputs![0]["confidence"] * 100).toStringAsFixed(0)}%",
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
                        )
                      : FirstPage(key: key,),
                ],
              ),
            ),
    );
  }

  Row buildFloatingButton(BuildContext context) {
    return Row(
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
    );
  }
}
