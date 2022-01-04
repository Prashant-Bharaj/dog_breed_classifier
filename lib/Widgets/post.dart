import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dog_breed_classifier/Widgets/progress.dart';
import 'package:dog_breed_classifier/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../application_state.dart';
import '../authentication.dart';
import '../comments.dart';
import '../custom_image.dart';
import '../home.dart';
import 'heart_animation.dart';
class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;

  const Post(
      {Key? key,
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
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      location: doc['location'],
      description: doc['description'],
      mediaUrl: doc['mediaUrl'],
      likes: doc['likes'],
    );
  }


  // Like count Method
  int getLikeCount(likes) {
    // if no likes, return 0
    if (likes == null) {
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


  @override
  _PostState createState() => _PostState(
    postId: this.postId,
    ownerId: this.ownerId,
    location: this.location,
    description: this.description,
    mediaUrl: this.mediaUrl,
    likes: this.likes,
    likeCount: getLikeCount(this.likes),
  );
}

class _PostState extends State<Post> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final String? postId;
  final String? ownerId;
  final String? location;
  final String? description;
  final String? mediaUrl;
  bool? showHeart = false;
  bool? isLiked = false;
  int? likeCount=0;
  Map? likes;

  _PostState({ this.postId, this.ownerId, this.location, this.description, this.mediaUrl, likes, int likeCount=0});

  buildPostHeader() {
    return FutureBuilder(
      future: usersRef.doc(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress(context);
        }
        // FirestoreUser user = FirestoreUser.fromDocument(snapshot.data as DocumentSnapshot);
        bool isPostOwner = currentUserId == ownerId;
        return ListTile(
          leading: CircleAvatar(
            //TODO: add photo url of user
            backgroundImage: CachedNetworkImageProvider("https://placedog.net/50"),
            // backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            // onTap: () => showProfile(context, profileId: user.uid),
            child: Text(
              currentUser?.name??"",
              style: TextStyle(
                // color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Text(location??""),
          trailing: isPostOwner
              ? IconButton(
            // onPressed: () => handleDeletePost(context),
            icon: Icon(Icons.more_vert), onPressed: () {  },
          )
              : Text(''),
        );
      },
    );
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(mediaUrl!),
          HeartAnimation(showHeart),
        ],
      ),
    );
  }

  handleLikePost() {
    bool? _isLiked;
    if(likes != null)
    _isLiked = likes![currentUserId] == true;

    if (_isLiked == true) {
      postsRef
          .doc(ownerId)
          .collection('userPosts')
          .doc(postId)
          .update({'likes.$currentUserId': false});
      // removeLikeFromActivityFeed();
      setState(() {
        likeCount = (likeCount! - 1);
        isLiked = false;
        likes![currentUserId] = false;
      });
    } else if (_isLiked == false) {
      postsRef
          .doc(ownerId)
          .collection('userPosts')
          .doc(postId)
          .update({'likes.$currentUserId': true});
      // addLikeToActivityFeed();
      setState(() {
        likeCount = likeCount! + 1;
        isLiked = true;
        likes![currentUserId] = true;
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
            Expanded(child: Text(description??""))
          ],
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    if(likes != null)
    isLiked = (likes![currentUserId] == true);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter()
      ],
    );

  }
}


// showProfile(BuildContext context, {String? profileId}) {
//   Navigator.push(
//     context,
//     MaterialPageRoute(
//       builder: (context) => Profile(
//         profileId: profileId,
//       ),
//     ),
//   );
// }
