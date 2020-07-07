import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taalk/views/room/DiscussHomeScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taalk/helpers/GlobalVariable.dart' as globals;
import 'dart:convert' show Encoding, json;
import 'package:http/http.dart' as http;

class LoginDiscuss extends StatefulWidget {
  @override
  _LoginDiscussState createState() => _LoginDiscussState();
}

class _LoginDiscussState extends State<LoginDiscuss> with WidgetsBindingObserver {
  String TAG = "LoginDiscuss ";

  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences prefs;

  bool isLoading = false;
  bool isLoggedIn = false;
  FirebaseUser currentUser;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    print("$TAG initState Running");
    isSignedIn();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    print("$TAG dispose Running");
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      print('$TAG - Background AppLifecycleState paused');
      WidgetsBinding.instance.removeObserver(this);
    }
    if (state == AppLifecycleState.resumed) {
      print('$TAG - Foreground AppLifecycleState resumed');
    }
    if (state == AppLifecycleState.inactive) {
      print('$TAG - Background AppLifecycleState inactive');
      WidgetsBinding.instance.removeObserver(this);
    }
  }

  void isSignedIn() async {
    this.setState(() {
      isLoading = true;
    });
    prefs = await SharedPreferences.getInstance();

    isLoggedIn = await googleSignIn.isSignedIn();
    print('$TAG isLoggedIn: ${isLoading}');
    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, "/logout");
      print('$TAG auto login');
    }else{
      this.setState(() {
        isLoading = false;
      });
    }
  }

  Future<Null> handleSignIn2() async {
    prefs = await SharedPreferences.getInstance();
    print("$TAG get token pref to upload: ${prefs.get(globals.keyPrefTokenFirebase)}");
    this.setState(() {
      isLoading = true;
    });
    try{
      GoogleSignInAccount googleUser = await googleSignIn.signIn();
      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.getCredential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final AuthResult authResult = await firebaseAuth.signInWithCredential(credential);
      final FirebaseUser firebaseUser = authResult.user;
      if (firebaseUser != null) {
        // Check is already sign up
        final QuerySnapshot result = await Firestore.instance.collection('users_')
            .where('id', isEqualTo: firebaseUser.uid)
            .getDocuments();

        final List<DocumentSnapshot> documents = result.documents;
        if (documents.length == 0) {
          // Update data to server if new user
          Firestore.instance.collection('users_')
              .document(firebaseUser.uid)
              .setData({
            'nickname': firebaseUser.displayName,
            'photoUrl': firebaseUser.photoUrl,
            'contentTime': DateTime.now().toString(),
            'inRoom': "online",
            'isNewContent': false,
            'isTyping': false,
            'photoUrl': firebaseUser.photoUrl,
            'aboutMe': "-",
            'id': firebaseUser.uid,
            'createdAt': DateTime.now(),
            'tokenUser':prefs.get(globals.keyPrefTokenFirebase),
            'chattingWith': null
          });

          print('X=================new Collection===================');
          Firestore.instance.collection('users_').document(firebaseUser.uid).collection('my_friends').document(firebaseUser.uid).setData({});

          _sendNotificationToAll(firebaseUser.uid,firebaseUser.displayName);

          // Write data to local
          currentUser = firebaseUser;
          await prefs.setString(globals.keyPrefFirebaseUserId, currentUser.uid);
          await prefs.setString(globals.keyPrefFirebaseName, currentUser.displayName);
          await prefs.setString(globals.keyPrefFirebasePhotoUrl, currentUser.photoUrl);
        }
        else {
          // Write data to local
          await prefs.setString(globals.keyPrefFirebaseUserId, documents[0]['id']);
          await prefs.setString(globals.keyPrefFirebaseName, documents[0]['nickname']);
          await prefs.setString(globals.keyPrefFirebasePhotoUrl, documents[0]['photoUrl']);
          await prefs.setString(globals.keyPrefFirebaseAboutMe, documents[0]['aboutMe']);
        }
        Fluttertoast.showToast(msg: "Sign in success");
        this.setState(() {
          isLoading = false;
        });
        Navigator.of(context).pushReplacement(new MaterialPageRoute(
            settings: const RouteSettings(name: '/discusshome'),
            builder: (context) => new DiscussHomeScreen()));
      }
      else {
        Fluttertoast.showToast(msg: "Sign in fail");
        this.setState(() {
          isLoading = false;
        });
      }
    }catch(e){
      this.setState(() {
        isLoading = false;
      });
      print('$TAG catch: ${e.toString()}');
      Fluttertoast.showToast(msg: 'info: ${e.toString()}');
    }
  }

  _sendNotificationToAll(String id, String username)async{
    QuerySnapshot querySnapshot = await Firestore.instance.collection("users_").getDocuments();
    var list = querySnapshot.documents;
    print('$TAG Get count Token user registered:  ${list.length}');
    for(var i = 0; i < list.length; i++){
      print('$TAG pushToken -> ${list[i]['tokenUser']}');
      final postUrl = 'https://fcm.googleapis.com/fcm/send';
      var data = {
        "notification": {"body": "${username} joined Discuss!", "title": "Discuss"},
        "priority": "high",
        "data": {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "id": "1",
          "status": "done"
        },
        "to": "${list[i]['tokenUser']}"
      };
      final headers = {
        'content-type': 'application/json',
        'Authorization': 'key=${globals.serverKeyFirebaseStatic}'
      };
      final response = await http.post(postUrl,
          body: json.encode(data),
          encoding: Encoding.getByName('utf-8'),
          headers: headers);
      if (response.statusCode == 200) {
        // on success do sth
        print('FCM Success sent');
      } else {
        // on failure do sth
        print('FCM Failure sent');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: (){
        exit(0);
      },
      child: Scaffold(
        body: Container(
          color: Colors.white,
          child: Stack(
            children: <Widget>[
              Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(top: 0.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          FlatButton(
                              onPressed: handleSignIn2,
                              child: Text(
                                'Sign in with Google',
                                style: TextStyle(fontSize: 16.0),
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                              color: Color(0xffdd4b39),
                              highlightColor: Color(0xffff7f7f),
                              splashColor: Colors.transparent,
                              textColor: Colors.white,
                              padding: EdgeInsets.fromLTRB(30.0, 15.0, 30.0, 15.0)),
                        ],
                      ),
                    ),
                    Image.asset('assets/images/img_ilustration_discuss.jpg'),
                  ],
                )
              ),
              // Loading
              Positioned(
                child: isLoading ?
                Container(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  ),
                  color: Colors.white.withOpacity(0.90),
                ) : Container(),
              ),
            ],
          ),
        ),
      ),
    );
  }// End Widget build


}// End HomeScreen
