import 'package:dog_breed_classifier/utility/model_loading.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import 'dart:async';
import 'dart:io';

import '../utility/first_page.dart';

class ImageDetectionPage extends StatefulWidget {
  const ImageDetectionPage({Key? key}) : super(key: key);

  @override
  _ImageDetectionPageState createState() => _ImageDetectionPageState();
}

class _ImageDetectionPageState extends State<ImageDetectionPage> {
  late bool _loading;
  List? _outputs;
  File? _image;


  GlobalKey key = GlobalKey();

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

  

  selectImage(parentContext) {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Text("Create Post"),
          children: <Widget>[
            SimpleDialogOption(
                child: Text("Photo with Camera"), onPressed: handleTakePhoto),
            SimpleDialogOption(
                child: Text("Image from Gallery"),
                onPressed: handleChooseFromGallery),
            SimpleDialogOption(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }
  handleChooseFromGallery() async {
    Navigator.pop(context);
    var image = await ImagePicker().pickImage(source: ImageSource.gallery);
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
  handleTakePhoto() async {
    Navigator.pop(context);
    var image = await ImagePicker().pickImage(
        source: ImageSource.camera,
    maxHeight: 675,
    maxWidth: 960,);
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // drawer: buildDrawer(),
      appBar: AppBar(
        title: Text("Dog Hub"),
        centerTitle: true,
      ),
      floatingActionButton:  FloatingActionButton.extended(

        // isExtended: true,

              heroTag: null,
              // onPressed: () => pickImage(),
        onPressed: () => selectImage(context),                       
              label: Text("Pick image"),
              icon: Icon(Icons.image),
            ),
      body: Container(
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
                                            content: SizedBox(
                                              height: MediaQuery.of(context).size.height*0.7,
                                              width: MediaQuery.of(context).size.width*0.8,
                                              child: WebView(
                                                  backgroundColor: Colors.white,
                                                  initialUrl: 'https://en.wikipedia.org/wiki/${_outputs![i]["label"]}'),
                                            ),
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
}
