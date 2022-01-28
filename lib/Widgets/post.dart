import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dog_breed_classifier/Widgets/progress.dart';
import 'package:dog_breed_classifier/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../authentication/application_state.dart';
import '../authentication/authentication.dart';
import '../uploadui/comments.dart';
import 'custom_image.dart';
import '../uploadui/home.dart';
import 'heart_animation.dart';

final storageRef = FirebaseStorage.instance.ref();

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String location;
  final String description;
  final String mediaUrl;
  final String name;
  final dynamic likes;

  const Post(
      {Key? key,
        required this.name,
      required this.postId,
      required this.ownerId,
      required this.location,
      required this.description,
      required this.mediaUrl,
      this.likes})
      : super(key: key);

  // factory constructor fromDocument
  // factory constructor support the return

  // Accessing the post details from `DocumentSnapshot`
  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      name: doc['name'],
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      location: doc['location'],
      description: doc['description'],
      mediaUrl: doc['mediaUrl'],
      likes: doc['likes'],
    );
  }



  @override
  _PostState createState() => _PostState(
    postId: this.postId,
    ownerId: this.ownerId,
    location: this.location,
    description: this.description,
    mediaUrl: this.mediaUrl,
    likes: this.likes,

  );
}

class _PostState extends State<Post> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final String postId;
  final String ownerId;
  final String location;
  final String description;
  final String mediaUrl;
  bool? showHeart=false;
  late bool isLiked;
  Map likes;

  _PostState({required this.postId,required this.ownerId,required this.location,
    required this.description, required this.mediaUrl,required this.likes});
  int? likeCount;



  buildPostHeader() {
    return FutureBuilder(
      future: usersRef.doc(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress(context);
        }
        FirestoreUser user = FirestoreUser.fromDocument(snapshot.data as DocumentSnapshot);
        bool isPostOwner = currentUserId == ownerId;
        return ListTile(
          title: GestureDetector(
            child: Text(
              user.name??"",
              style: TextStyle(
                // color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Text(location),
          trailing: isPostOwner
              ? IconButton(
            onPressed: () => handleDeletePost(context),
            icon: Icon(Icons.more_vert),
          )
              : Text(''),
        );
      },
    );
  }

  handleDeletePost(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text("Remove this post?"),
            children: <Widget>[
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context);
                    deletePost();
                  },
                  child: Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  )),
              SimpleDialogOption(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel')),
            ],
          );
        });
  }

  // Note: To delete post, ownerId and currentUserId must be equal, so they can be used interchangeably
  deletePost() async {
    // delete post itself
    postsRef
        .doc(ownerId)
        .collection('userPosts')
        .doc(postId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // delete uploaded image for thep ost
    storageRef.child("post_$postId.jpg").delete();
    // then delete all activity feed notifications
    QuerySnapshot timelineSnapshot = await FirebaseFirestore.instance
        .collection("timeline")
        .where('postId', isEqualTo: postId)
        .get();
    timelineSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();

        setState(() {
          triggerRefresh = true;
        });
      }
    });
    // then delete all comments
    QuerySnapshot commentsSnapshot = await commentsRef
        .doc(postId)
        .collection('comments')
        .get();
    commentsSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // buildTimeline();
  }


  buildPostImage() {
    return GestureDetector(
      onDoubleTap: ()=>handleLikePost(),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(mediaUrl),
          HeartAnimation(showHeart),
        ],
      ),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      likeCount = getLikeCount(likes);
    });
  }

  // Like count Method
  int getLikeCount(Map likes) {
    // if no likes, return 0
    if (likes.isEmpty) {
      return 0;
    }
    int count = 0;
    // if the key is explicitly set to true, add a like
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }


  handleLikePost() {

    print("function called");
    bool _isLiked;
    if(likes.containsKey(currentUserId))
      _isLiked = likes[currentUserId] == true;
    else{
      _isLiked=false;
      likes.putIfAbsent(currentUserId, ()=> false);
    }


    if (_isLiked) {
      FirebaseFirestore.instance.collection("timeline")
          .doc(postId)
          .update({'likes.$currentUserId': false});
      // removeLikeFromActivityFeed();
      setState(() {
        likeCount = (likeCount! - 1);
        isLiked = false;
        likes[currentUserId] = false;
      });
    } else {
      FirebaseFirestore.instance.collection("timeline")
          .doc(postId)
          .update({'likes.$currentUserId': true});
      // addLikeToActivityFeed();
      setState(() {
        likeCount = likeCount! + 1;
        isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  showComments(BuildContext context,
      {required String? postId, required String? ownerId,
        required String? mediaUrl}) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Comments(

        postId: postId,
        postOwnerId: ownerId,
        postMediaUrl: mediaUrl,
      );
    }));
  }

  buildPostFooter() {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 40.0, left: 20.0)),
            GestureDetector(
              onTap: handleLikePost,
              child: Icon(
                isLiked == true ? Icons.favorite : Icons.favorite_border,
                size: 28.0,
                color: Colors.pink,
              ),
            ),
            Padding(padding: EdgeInsets.only(right: 20.0)),
            GestureDetector(
              onTap: () => showComments(
                context,

                postId: postId,
                ownerId: ownerId,
                mediaUrl: mediaUrl,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 28.0,
                // color: Colors.blue,
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "$likeCount likes",
                style: TextStyle(
                  // color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child:
              Text(
                " ",
                style: TextStyle(
                  // color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(child: Text(description))
          ],
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
  isLiked = (likes[currentUserId] == true);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(),
        Divider(),
      ],
    );
  }
}