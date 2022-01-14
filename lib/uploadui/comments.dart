import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Widgets/header.dart';
import '../Widgets/post.dart';
import '../Widgets/progress.dart';

import 'package:timeago/timeago.dart' as timeago;
import 'home.dart';

class Comments extends StatefulWidget {
  final String? postId;
  final String? postOwnerId;
  final String? postMediaUrl;

  Comments({
    required this.postId,
    required this.postOwnerId,
    required this.postMediaUrl,
  });

  @override
  CommentsState createState() => CommentsState(
        postId: this.postId!,
        postOwnerId: this.postOwnerId!,
        postMediaUrl: this.postMediaUrl!,
      );
}

class CommentsState extends State<Comments> {
  TextEditingController commentController = TextEditingController();
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  CommentsState({
    required this.postId,
    required this.postOwnerId,
    required this.postMediaUrl,
  });

  buildComments() {
    return StreamBuilder(
        stream: commentsRef
            .doc(postId)
            .collection('comments')
            .orderBy("timestamp", descending: false)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return circularProgress(context);
          }
          List<Comment> comments = [];
          snapshot.data?.docs.forEach((element) {
            comments.add(Comment.fromDocument(element));
          });
          // if(snapshot.hasData) snapshot.data?.forEach((doc) {
          //   comments.add(Comment.fromDocument(doc));
          // });
          return ListView(
            children: comments,
          );
        });
  }

  addComment() {
    commentsRef.doc(postId).collection("comments").add({
      "name": FirebaseAuth.instance.currentUser?.displayName,
      "comment": commentController.text,
      "timestamp": timestamp,
      // "avatarUrl": currentUser?.photoUrl,
      "userId": currentUser?.uid,
    });
    bool isNotPostOwner = postOwnerId != currentUser?.uid;
    if (isNotPostOwner) {
      // activityFeedRef.doc(postOwnerId).collection('feedItems').add({
      //   "type": "comment",
      //   "commentData": commentController.text,
      //   "timestamp": timestamp,
      //   "postId": postId,
      //   "userId": currentUser.id,
      //   "username": currentUser.username,
      //   "userProfileImg": currentUser.photoUrl,
      //   "mediaUrl": postMediaUrl,
      // });
    }
    commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Comments"),
      body: Column(
        children: <Widget>[
          Expanded(child: buildComments()),
          Divider(),
          ListTile(
            title: TextFormField(
              controller: commentController,
              decoration: InputDecoration(labelText: "Write a comment..."),
            ),
            trailing: OutlinedButton(
              onPressed: addComment,
              style: ButtonStyle(
                  // ,
                  ),
              // borderSide: BorderSide.none,
              child: Text("Post"),
            ),
          ),
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String? userId;
  // final String? avatarUrl;
  final String? comment;
  final Timestamp? timestamp;
  final String? name;

  Comment({
    this.userId,
    // this.avatarUrl,
    this.comment,
    this.timestamp,
    this.name,
  });

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      userId: doc['userId'],
      name: doc['name'],
      comment: doc['comment'],
      timestamp: doc['timestamp'],
      // avatarUrl: doc['avatarUrl'],
    );
  }

  // var isMe = FirebaseAuth.instance.currentUser?.uid == userId;
  // FirebaseFirestore commentUser =
  @override
  Widget build(BuildContext context) {
    var isMe = FirebaseAuth.instance.currentUser?.uid == userId;
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            name!,
            style: TextStyle(
                fontSize: MediaQuery.of(context).size.width*0.025
            ),
          ),
          Material(
            elevation: 5.0,
            borderRadius: isMe
                ? BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                  )
                : BorderRadius.only(
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
            color: isMe
                ? Theme.of(context).brightness == Brightness.dark
                    ? Colors.blue.shade900
                    : Colors.lightBlue
                : Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                comment!,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black54,
                  fontSize: 15.0,
                ),
              ),
            ),
          ),
          Text(
            timeago.format(timestamp!.toDate()),
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width*0.02
            ),
          ),
        ],
      ),
    );
  }
}
