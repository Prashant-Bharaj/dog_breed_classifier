import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import 'dart:async';
import 'dart:io';
import 'package:dog_breed_classifier/utility/model_loading.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'first_page.dart';
import 'left_drawer.dart';
import 'video_page/live_detection.dart';
// import 'string_extension.dart';


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
    if(Platform.isAndroid) WebView.platform = AndroidWebView();
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
      numResults: 7,
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
      // floatingActionButton: buildFloatingBar(context),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (value){
          switch(value){
            case 0: pickImage();
            break;
            case 1: Navigator.push(context,
                        MaterialPageRoute(builder: (BuildContext context) {
                          return FaceDetectionFromLiveCamera();
                        }));
            break;
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.image), label: "Select image"),
          BottomNavigationBarItem(icon: Icon(Icons.camera), label: "Select camera"),
        ],
      ),
      body:  Container(
        // height: MediaQuery.of(context).size.height * 0.9,
        child: _loading
            ? Container(
          alignment: Alignment.center,
          child: CircularProgressIndicator(),
        )
            :Column(
          children: [
            _image == null
                ? Container()
                : Container(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Image.file(_image!,
                      fit: BoxFit.contain,
                      height: MediaQuery.of(context).size.height * 0.6),
                ),
            SizedBox(
              height: 10,
            ),
            (_outputs != null && _outputs!.length > 0)
                ? Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for(var i=0; i < 7; i ++)
                        Padding(
                          padding: const EdgeInsets.only(left: 24,right: 24,top: 4,bottom: 4),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: MediaQuery.of(context).size.width * 0.3,
                                      maxWidth: MediaQuery.of(context).size.width * 0.6,
                                    ),
                                    child: TextButton(
                                      onPressed: (){
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                          return AlertDialog(

                                            content: WebView(initialUrl: 'https://en.wikipedia.org/wiki/${_outputs![i]["label"]}'),
                                          );
                                        },

                                        );
                                      },
                                      child: Text(
                                        "${_outputs![i]["label"]}".replaceAll("_", " ").replaceRange(0, 1, _outputs![i]["label"].toString()[0].toUpperCase()),
                                        style: TextStyle(
                                          fontSize: 25.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "${(_outputs![i]["confidence"] * 100).toStringAsFixed(0)}%",
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ],
                              ),
                              Divider(
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                : FirstPage(key: key,),
          ],
        ),
      ),
    );
  }

  Widget buildFloatingBar(BuildContext context) {
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
