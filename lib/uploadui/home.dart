import 'dart:collection';

import 'package:dog_breed_classifier/image_page/image_detection.dart';
import 'package:dog_breed_classifier/storageManager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as Im;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite/tflite.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../Widgets/post.dart';
import '../authentication/application_state.dart';
import '../models/user.dart';
import '../themeManager.dart';
import '../video_page/live_detection.dart';
import 'package:permission_handler/permission_handler.dart';

bool isDark= StorageManager.readData.toString() == "dark";
bool triggerRefresh = false;
final DateTime timestamp = DateTime.now();
final postsRef = FirebaseFirestore.instance.collection('posts');
final commentsRef = FirebaseFirestore.instance.collection('comments');
FirestoreUser? currentUser;
void getCurrentUser() {
  var cred = FirebaseAuth.instance.currentUser;
  currentUser = FirestoreUser(
      name: cred?.displayName, uid: cred?.uid, email: cred?.email);
}

class MyHomePage extends StatefulWidget {
  ThemeNotifier? theme;
  MyHomePage(ThemeNotifier theme) {
    this.theme = theme;
  }

  @override
  _MyHomePageState createState() => _MyHomePageState(theme);
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

class _MyHomePageState extends State<MyHomePage> {
  ThemeNotifier? theme;
  _MyHomePageState(ThemeNotifier? theme) {
    this.theme = theme;
  }

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: buildDrawer(theme!),
      appBar: AppBar(
        title: Text("Dog Hub"),
        centerTitle: true,
        actions: [
          Container(
              child: InkWell(
            child: Icon(Icons.upload),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Upload(
                            currentUser: currentUserLogin,
                          )));
            },
          )),
          SizedBox(
            width: 12,
          ),
        ],
      ),

      // floatingActionButton: buildFloatingBar(context),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (value) {
          switch (value) {
            case 0:
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ImageDetectionPage()));
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) {
                    return FaceDetectionFromLiveCamera();
                  },
                ),
              );
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.image), label: "Scan dog breed with image"),
          BottomNavigationBarItem(
              icon: Icon(Icons.camera), label: "Scan dog breed with video"),
        ],
      ),

      body: TimeLine(),
    );
  }

  Drawer buildDrawer(ThemeNotifier theme) {
    return Drawer(
      child: Container(
        child: ListView(
          padding: EdgeInsets.only(top: 20),
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black,
              ),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'Dog Hub',
                  style: GoogleFonts.lato(
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            ListTile(
              title: Text(isDark ? "Dark Mode" : "Light Mode",
                  style: TextStyle(fontSize: 20)),
              leading: isDark ? Icon(Icons.dark_mode) : Icon(Icons.light_mode),
              trailing: Switch(
                value: isDark,
                onChanged: (bool value) {
                  setState(
                    () {
                      isDark = value;
                      isDark ? theme.setDarkMode() : theme.setLightMode();
                    },
                  );
                },
              ),
            ),

            Divider(
              height: 3,
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
            ListTile(
              title: Text(
                'LOGOUT',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
              leading: Icon(
                Icons.logout,
              ),
              onTap: () {
                FirebaseAuth.instance.signOut();
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
}

class Upload extends StatefulWidget {
  final FirestoreUser? currentUser;
  const Upload({Key? key, required this.currentUser}) : super(key: key);

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  TextEditingController captionController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  File? file;
  bool isUploading = false;
  String postId = Uuid().v4();

  handleTakePhoto() async {
    Navigator.pop(context);
    var file = (await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    ));
    var output = await Tflite.runModelOnImage(
      path: File(file!.path).path,
      numResults: 1,
      threshold: 0.0,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      this.file = File(file.path);
      this.captionController.text = output![0];
    });
  }

  handleChooseFromGallery() async {
    Navigator.pop(context);
    var file = (await ImagePicker().pickImage(source: ImageSource.gallery));
    var output = await Tflite.runModelOnImage(
      path: File(file!.path).path,
      numResults: 1,
      threshold: 0.0,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      this.file = File(file.path);
      this.captionController.text = output![0]["label"].toString();
    });
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

  buildSplashScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dog Hub"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Material(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.blue
                  : Colors.black45,
              elevation: 18.0,
              borderRadius: BorderRadius.circular(18.0),
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: TextButton(
                  onPressed: () => selectImage(context),
                  child: Text(
                    "Upload Image",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  clearImage() {
    setState(() {
      file = null;
    });
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image? imageFile = Im.decodeImage(file!.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile!, quality: 85));
    setState(() {
      file = compressedImageFile;
    });
  }

  Future<String> uploadImage(imageFile) async {
    var uploadTask = FirebaseStorage.instance
        .ref()
        .child("post_$postId.jpg")
        .putFile(imageFile);
    var storageSnap = await uploadTask.whenComplete(() => null);
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  Map<String, int> mapoflike = new HashMap();

  createPostInFirestore(
      {required String mediaUrl,
      required String location,
      required String description}) {
    postsRef.doc(currentUser?.uid).collection("userPosts").doc(postId).set({
      "name": FirebaseAuth.instance.currentUser?.displayName,
      "postId": postId,
      "ownerId": currentUser?.uid,
      "mediaUrl": mediaUrl,
      "description": description,
      "location": location,
      "timestamp": timestamp,
      "likes": {},
    });
  }

  handleSubmit() async {
    setState(() {
      isUploading = true;
    });
    await compressImage();
    String mediaUrl = await uploadImage(file);
    createPostInFirestore(
      mediaUrl: mediaUrl,
      location: locationController.text,
      description: captionController.text,
    );
    captionController.clear();
    locationController.clear();
    setState(() {
      file = null;
      isUploading = false;
      postId = Uuid().v4();
    });
  }

  Scaffold buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        // backgroundColor: Colors.white70,
        leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
            ),
            onPressed: clearImage),
        title: Text(
          "Caption Post",
        ),
        actions: [
          TextButton(
            onPressed: isUploading ? null : () => handleSubmit(),
            child: Text(
              "Post",
              style: TextStyle(
                color: Theme.of(context).brightness != Brightness.dark
                    ? Colors.white
                    : Colors.blue,
                // fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          isUploading
              ? Container(
                  padding: EdgeInsets.only(bottom: 10.0),
                  child: LinearProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(
                        Theme.of(context).colorScheme.secondary),
                  ),
                )
              : Text(""),
          Container(
            height: 220.0,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: FileImage(file!),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 10.0),
          ),
          ListTile(
            title: Container(
              width: 250.0,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                  hintText: "Enter breed name",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.pin_drop,
              // color: Colors.orange,
              size: 35.0,
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(
                  hintText: "Where was this photo taken?",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            width: 200.0,
            height: 100.0,
            alignment: Alignment.center,
            child: ElevatedButton.icon(
              label: Text(
                "Use Current Location",
                // style: TextStyle(color: Colors.white),
              ),
              style: ButtonStyle(
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                ),
              ),
              // color: Colors.blue,
              onPressed: getUserLocation,
              icon: Icon(
                Icons.my_location,
                // color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  getUserLocation() async {
    await Permission.location.request();
    if (await Permission.location.isDenied) {
      openAppSettings();
    }

    if (await Permission.location.request().isGranted) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark placemark = placemarks[0];
      String completeAddress =
          '${placemark.subThoroughfare} ${placemark.thoroughfare}, ${placemark.subLocality} ${placemark.locality}, ${placemark.subAdministrativeArea}, ${placemark.administrativeArea} ${placemark.postalCode}, ${placemark.country}';
      // print(completeAddress);
      String formattedAddress = "${placemark.locality}, ${placemark.country}";
      setState(() {
        print(formattedAddress);
        locationController.text = formattedAddress;
      });
    } else {
      print(await Permission.location.request().isGranted);
    }
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    return file == null ? buildSplashScreen() : buildUploadForm();
  }
}

class TimeLine extends StatefulWidget {
  const TimeLine({Key? key}) : super(key: key);

  @override
  _TimeLineState createState() => _TimeLineState();
}

class _TimeLineState extends State<TimeLine> {
  List<Post>? posts;
  List<String> followingList = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getTimeline();
  }

  getTimeline() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("timeline")
        .orderBy('timestamp', descending: true)
        .get();
    List<Post> posts =
        snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    setState(() {
      this.posts = posts;
    });
  }

  //TODO: implement if user don't have anything in the timeline
  buildTimeLine() {
    if (posts == null) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.only(top: 10.0),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Theme.of(context).backgroundColor),
        ),
      );
    } else if (posts?.isEmpty == true) {
      return Center(child: Text("empty"));
    } else {
      return ListView(
        children: posts ?? [],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (triggerRefresh) {
      triggerRefresh = false;
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => getTimeline(),
        child: buildTimeLine(),
      ),
    );
  }
}

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
