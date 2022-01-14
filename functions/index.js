const functions = require("firebase-functions");
const admin =  require('firebase-admin');
admin.initializeApp();
// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

exports.onCreatePost = functions.firestore
.document("/posts/{userId}/userPosts/{postId}")
.onCreate(async (snapshot, context)=> {
    const postCreated = snapshot.data();
    const userId = context.params.userId;
    const postId = context.params.userId;

    //1) create user post ref
    const userPostsRef = admin
    .firestore()
    .collection('posts')
    .doc(userId)
    .collection('userPosts');

    //2)get all posts
    const querySnapshot = await userPostsRef.get();

    //3) add each user's post to timeline
    querySnapshot.forEach(doc => {
    const docId = doc.id;
    const docData = doc.data();
        admin
        .firestore()
        .collection("timeline")
        .doc(docId)
        .set(docData);
    })
});

//exports.onDeletePost = functions.firestore
//  .document("/posts/{userId}/userPosts/{postId}")
//  .onDelete(async (snapshot, context) => {
//    const userId = context.params.userId;
//    const postId = context.params.postId;
//
//
//
//
//    // 2) Delete each post in each follower's timeline
//    querySnapshot.forEach(doc => {
//      const followerId = doc.id;
//
//      admin
//        .firestore()
//        .collection("timeline")
//        .doc(postId)
//        .get()
//        .then(doc => {
//          if (doc.exists) {
//            doc.ref.delete();
//          }
//        });
//    });
//  });