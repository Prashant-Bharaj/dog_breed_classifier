import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as Im;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'Widgets/post.dart';
import 'application_state.dart';
import 'left_drawer.dart';
import 'models/user.dart';
import 'video_page/live_detection.dart';

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
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: buildDrawer(),
      appBar: AppBar(
        title: Text("Dog breed classifier"),
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
          )
        ],
      ),

      // floatingActionButton: buildFloatingBar(context),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (value) {
          switch (value) {
            case 0:
              Navigator.pushNamed(context, '/ImageDetectionPage');
              break;
            case 1:
              Navigator.push(context,
                  MaterialPageRoute(builder: (BuildContext context) {
                return FaceDetectionFromLiveCamera();
              }));
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.image), label: "Select image"),
          BottomNavigationBarItem(
              icon: Icon(Icons.camera), label: "Select camera"),
        ],
      ),
      body: TimeLine(),
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
    setState(() {
      this.file = File(file!.path);
    });
  }

  handleChooseFromGallery() async {
    Navigator.pop(context);
    var file = (await ImagePicker().pickImage(source: ImageSource.gallery));
    setState(() {
      this.file = File(file!.path);
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

  Container buildSplashScreen() {
    return Container(
      // color: Theme.of(context).accentColor.withOpacity(0.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: ElevatedButton(
                style: ButtonStyle(
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                    ),
                  ),
                ),
                child: Text(
                  "Upload Image",
                  style: TextStyle(
                    fontSize: 22.0,
                  ),
                ),
                onPressed: () => selectImage(context)),
          ),
        ],
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

  createPostInFirestore(
      {required String mediaUrl,
      required String location,
      required String description}) {
    postsRef
        .doc(widget.currentUser?.uid)
        // .currentUser.id)
        .collection("userPosts")
        .doc(postId)
        .set({
      "postId": postId,
      "ownerId": widget.currentUser?.uid,
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
                // color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
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
            // leading: CircleAvatar(
            //   backgroundImage:
            //   CachedNetworkImageProvider(widget.currentUser?.photoUrl??""),
            // ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                  hintText: "Write a caption...",
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
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    // List<Placemark> placemarks = await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);
    // await Geolocator.;
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark = placemarks[0];
    String completeAddress =
        '${placemark.subThoroughfare} ${placemark.thoroughfare}, ${placemark.subLocality} ${placemark.locality}, ${placemark.subAdministrativeArea}, ${placemark.administrativeArea} ${placemark.postalCode}, ${placemark.country}';
    print(completeAddress);
    String formattedAddress = "${placemark.locality}, ${placemark.country}";
    setState(() {
      locationController.text = formattedAddress;
    });
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
    getAllPosts();
  }

  getAllPosts() async {
    print("get all posts called");

    // QuerySnapshot snapshot = await FirebaseFirestore.instance.collection(
    //     "posts")
    //     .doc(currentUser?.uid)
    //     .collection('userPosts')
    //     .orderBy('timestamp', descending: true)
    //     .get();
    List listOfKeys = [];
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection("posts").get();
    snapshot.docs.forEach((element) {
      listOfKeys.add(element.toString());
    });

    // print(snapshot.docs.);
    setState(() {
      print("****************************************\n\n\n");
      for (var i in listOfKeys) print(i);
      print("****************************************\n\n\n");
      List<Post> posts = snapshot.docs
          .map((doc) => Post.fromDocument(doc))
          .toList(growable: true);
      this.posts = posts;
    });
  }

  // getTimeline() async {
  //   QuerySnapshot snapshot = await timelineRef
  //       .doc(user?.uid)
  //       .collection('timelinePosts')
  //       .orderBy('timestamp', descending: true)
  //       .get();
  //   List<Post> posts =
  //   snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
  //   setState(() {
  //     this.posts = posts;
  //   });
  // }
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
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => getAllPosts(),
        child: buildTimeLine(),
      ),
    );
  }
}
