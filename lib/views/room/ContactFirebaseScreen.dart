import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taalk/views/room/ChatScreen.dart';
import 'package:taalk/views/room/RequestFriendsListScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taalk/helpers/GlobalVariable.dart' as globals;
import 'package:unicorndial/unicorndial.dart';

class ContactFirebaseScreen extends StatefulWidget {
  @override
  _ContactFirebaseScreenState createState() => _ContactFirebaseScreenState();
}

class _ContactFirebaseScreenState extends State<ContactFirebaseScreen>with/* with WidgetsBindingObserver,*/
    SingleTickerProviderStateMixin {
  String TAG = "ContactFirebaseScreen ";

  TextEditingController _textFieldRoomName = TextEditingController();
  TextEditingController _textFieldController = TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  final FirebaseMessaging firebaseMessaging = new FirebaseMessaging();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
  final GoogleSignIn googleSignIn = GoogleSignIn();

  bool isLoading = false;
  List<Choice> choices = const <Choice>[
    const Choice(title: 'Settings', icon: Icons.settings),
    const Choice(title: 'Log out', icon: Icons.exit_to_app),
  ];

  int search = 0;
  String filter = "";

  int countRequestFriend = 0;
  int countMsg = 0;
  int countAllNotification = 0;

  // Create a tab controller
  TabController controller;

  Color _colorPrimary = Color(0xFF4aacf2);

  SharedPreferences prefs;

  String id = '';
  String pushToken = '';
  String yourName = '';
  String photoUrl = '';

  List<String> listRequest = new List<String>();

  String groupChatId;

  final startAtTimestamp = Timestamp.fromMillisecondsSinceEpoch(DateTime.parse('2019-01-01 16:49:42.044').millisecondsSinceEpoch);

  Map<String, dynamic> get map => null;

  bool hasData = true;
  bool show = false;

  @override
  void initState() {
//    WidgetsBinding.instance.addObserver(this);
    controller = TabController(length: 3, vsync: this);
    readLocal();
    inRoom("online");
    super.initState();
    print("$TAG initState Running");
    getPref();
    registerNotification();
    configLocalNotification();
  }

  @override
  void dispose() {
    super.dispose();
//    WidgetsBinding.instance.removeObserver(this);
  }

  _checkRequestFriends() async {
    Firestore.instance.collection("request_friends").where('userIdTo',isEqualTo: id).snapshots().forEach((value) async {
      var data = value.documents;
      QuerySnapshot querySnapshot = await Firestore.instance.collection("request_friends")
          .where('userIdTo',isEqualTo: id)
          .getDocuments();
      var list = querySnapshot.documents;
      print('$TAG length request friends  ${list.length}');
      for(var i = 0; i < list.length; i++){
        listRequest.add(list[i]['userIdFrom']);
      }
      if(mounted){
        setState(() {
          countRequestFriend = list.length;
        });
      }
    });
  }

  inRoom(String status) async {
    QuerySnapshot querySnapshot = await Firestore.instance.collection("users_")
        .getDocuments();
    var list = querySnapshot.documents;
    for(var i = 0; i < list.length; i++){
      final QuerySnapshot result =
      await Firestore.instance.collection('users_').document(list[i]['id'])
          .collection('my_friends').where('id', isEqualTo: id)
          .getDocuments();
      final List<DocumentSnapshot> documents = result.documents;
      if(documents.length > 0){
        Firestore.instance.collection('users_')
            .document(list[i]['id'])
            .collection('my_friends')
            .document(id)
            .updateData({'inRoom': status});
      }
      Firestore.instance.collection('users_')
          .document(id)
          .updateData({'inRoom': status});
    }
  }

  void readLocal() async {
    prefs = await SharedPreferences.getInstance();
    // Force refresh input
    setState(() {
      id = prefs.getString(globals.keyPrefFirebaseUserId) ?? '';
      yourName = prefs.getString(globals.keyPrefFirebaseName) ?? '';
      photoUrl = prefs.getString(globals.keyPrefFirebasePhotoUrl) ?? '';
    });
    Timer(const Duration(milliseconds: 100), () {
      if(mounted){
        setState(() {
          show = true;
        });
      }
    });
    _checkRequestFriends();
  }

  getPref() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString(globals.keyPrefColorPrimaryAttendance) != null ||
        prefs.getString(globals.keyPrefColorPrimaryAttendance) == "") {
      setState(() {
        String colorPrimary =
        prefs.getString(globals.keyPrefColorPrimaryAttendance);
        print("$TAG pref string color: $colorPrimary");
        String valueString = colorPrimary.split('(0x')[1].split(')')[0];
        int value = int.parse(valueString, radix: 16);
        _colorPrimary = new Color(value);
      });
    }
  }

  void registerNotification() {
    firebaseMessaging.requestNotificationPermissions();
    firebaseMessaging.configure(onMessage: (Map<String, dynamic> message) {
      print('onMessage: $message');
      showNotification(message['notification']);
      return;
    }, onResume: (Map<String, dynamic> message) {
      print('onResume: $message');
      return;
    }, onLaunch: (Map<String, dynamic> message) {
      print('onLaunch: $message');
      return;
    });

    firebaseMessaging.getToken().then((token) async {
      Firestore.instance.collection('users_').document(id).updateData({'pushToken': token});
      _updateTokenInFriends(token);
      await prefs.setString('pushToken', token);
    }).catchError((err) {
      Fluttertoast.showToast(msg: "Info: ${err.message.toString()}",toastLength: Toast.LENGTH_LONG, gravity: ToastGravity.CENTER);
      print('$TAG getToken() ${err.message.toString()}');
    });
  }

  _updateTokenInFriends(String token) async{
    QuerySnapshot querySnapshot = await Firestore.instance.collection("users_")
        .getDocuments();
    var list = querySnapshot.documents;
    for(var i = 0; i < list.length; i++){
      final QuerySnapshot result =
      await Firestore.instance.collection('users_').document(list[i]['id']).collection('my_friends').where('id', isEqualTo: id)
          .getDocuments();
      final List<DocumentSnapshot> documents = result.documents;
      if(documents.length > 0){
        Firestore.instance.collection('users_').document(list[i]['id']).collection('my_friends').document(id)
            .updateData({'pushToken': token});
      }
    }

  }

  void configLocalNotification() {
    var initializationSettingsAndroid = new AndroidInitializationSettings('ic_launcher_notitle');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }


  Future<Null> handleSignOut() async {
    this.setState(() {
      isLoading = true;
    });

    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();

    this.setState(() {
      isLoading = false;
    });

    inRoom("offline");

  }

  Future<bool> onBackPress() {
    openDialog();
    return Future.value(false);
  }

  Future<Null> openDialog() async {
    switch (
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding: EdgeInsets.only(
                left: 0.0, right: 0.0, top: 0.0, bottom: 0.0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0)),
            children: <Widget>[
              Container(
                color: _colorPrimary,
                margin: EdgeInsets.all(0.0),
                padding: EdgeInsets.only(bottom: 10.0, top: 10.0),
                height: 100.0,
                child: Column(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.exit_to_app,
                        size: 30.0,
                        color: Colors.white,
                      ),
                      margin: EdgeInsets.only(bottom: 10.0),
                    ),
                    Text(
                      'Log out account?',
                      style: TextStyle(color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Log out or minimize?',
                      style: TextStyle(color: Colors.white70, fontSize: 14.0),
                    ),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  //                  Firestore.instance.collection('users').document(id).updateData({'inRoom': "offline"});
                  inRoom("offline");
//                    Navigator.pushReplacementNamed(context, '/discussroom');
                },
                child: Padding(
                  padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Row(
                    children: <Widget>[
                      Container(
                        child: Icon(
                          Icons.minimize,
                          color: _colorPrimary,
                        ),
                        margin: EdgeInsets.only(right: 10.0),
                      ),
                      Text(
                        'Minimize',
                        style: TextStyle(
                            color: _colorPrimary, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 0);
                },
                child: Padding(
                  padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Row(
                    children: <Widget>[
                      Container(
                        child: Icon(
                          Icons.cancel,
                          color: _colorPrimary,
                        ),
                        margin: EdgeInsets.only(right: 10.0),
                      ),
                      Text(
                        'Cancel',
                        style: TextStyle(
                            color: _colorPrimary, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  handleSignOut();
                  Navigator.pop(context, 0);
                  //                  exit(0);
                },
                child: Padding(
                  padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Row(
                    children: <Widget>[
                      Container(
                        child: Icon(
                          Icons.check_circle,
                          color: _colorPrimary,
                        ),
                        margin: EdgeInsets.only(right: 10.0),
                      ),
                      Text(
                        'Yes',
                        style: TextStyle(
                            color: _colorPrimary, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ),
              ),
            ],
          );
        }
    )
    )
    {
      case 0:
        break;
      case 1:
        break;
      case 2:
        exit(0);
        break;
    }
  }

  void showNotification(message) async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
      Platform.isAndroid ? 'com.dfa.flutterchatdemo': 'com.duytq.flutterchatdemo',
      'FlutterDiscuss',
      'DiscussDscription',
      playSound: true,
      enableVibration: true,
      importance: Importance.Max,
      priority: Priority.High,
    );
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics =
    new NotificationDetails(androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, message['title'].toString(), message['body'].toString(), platformChannelSpecifics,
        payload: json.encode(message));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Stack(
          children: <Widget>[
            // List
            Container(
              color: Colors.grey[50],
              child: Padding(
                padding: EdgeInsets.only(top: 68.0),
                child:Column(
                  children: <Widget>[
                    countRequestFriend > 0 ?
                    Container(
                      height: 50.0,
                      child: Padding(
                        padding: EdgeInsets.only(left: 40.0,top: 8.0,right: 40.0,bottom: 8.0),
                        child: ButtonTheme(
                          minWidth: 30.0,
                          height: 12.0,
                          child: FlatButton(
                              shape: new RoundedRectangleBorder(
                                  borderRadius: new BorderRadius.circular(10.0),
                                  side: BorderSide(color: Colors.green)
                              ),
                              color: Colors.white,
                              textColor: Colors.green,
                              padding: EdgeInsets.all(8.0),
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            RequestFriendsListScreen(
                                              id: id,
                                              listRequest: listRequest,
                                            )));
                              },
                              child: Center(
                                child: Text(
                                  'Request friends (${countRequestFriend})',
                                  style: TextStyle(
                                      fontSize: 12.0, color: Colors.green),),
                              )
                          ),
                        ),
                      ),
                    )
                        : Container(),
                    show == true ? Expanded(
                      child: StreamBuilder(
                        stream: Firestore.instance.collection('users_')
                            .document(id)
//                            .document(id)
                            .collection('my_friends')
                            .orderBy('contentTime', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(
                              child: Text("Connecting..."),
                            );
                          }
                          else {
                            return ListView.builder(
                              padding: EdgeInsets.only(top: 0.0),
                              itemBuilder:(context, index) => buildItem(context, snapshot.data.documents[index]),
                              itemCount: snapshot.data.documents.length,
                              controller: listScrollController,
                            );
                          }
                        },
                      ),
                    ):
                    Container(child: Center(child:CircularProgressIndicator(
                      backgroundColor: Colors.red,
                    ))),
                  ],
                ),
              ),
            ),
            // Loading
            Positioned(
              child: isLoading
                  ? Container(
                child: Center(
                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_colorPrimary)),
                ),
                color: Colors.white.withOpacity(0.8),
              )
                  : Container(),
            ),
            // Search
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: 70.0,
                padding: EdgeInsets.only(top: 10.0,left: 8.0,right: 8.0,bottom: 5.0),
                color: Colors.transparent,
                child: Stack(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topCenter,
                      child: Card(
                        elevation: 3.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        child: Container(
                          height: 50.0,
                          padding: EdgeInsets.only(left: 10.0,right: 5.0),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                  color: Colors.transparent,
                                  child: TextField(
                                    controller: _textFieldController,
                                    onChanged: (text){
                                      print("SEARCH ${text}");
                                      setState(() {
                                        filter = text;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText: "Search friends by nickname",
                                      border: InputBorder.none,
                                      icon: Icon(Icons.search,color:Colors.grey),
                                      contentPadding: EdgeInsets.all(5.0),
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.clear,color:Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    _textFieldController.clear();
                                    filter = "";
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }// End Widget build

  TabBar getTabBar() {
    return TabBar(
      labelColor: Colors.white,
      tabs: <Tab>[
        Tab(
          icon: Icon(Icons.chat_bubble,color: controller.index == 0 ? _colorPrimary :Colors.grey[400],),
//          text: "Monitoring",
        ),
        Tab(
          icon: Icon(Icons.group,color: controller.index == 1 ? _colorPrimary :Colors.grey[400],),
//          text: "Theme",
        ),
        Tab(
          // set icon to the tab
          icon: Icon(Icons.history,color: controller.index == 2 ? _colorPrimary :Colors.grey[400],),
//          text: "Stories",
        ),
      ],
      // setup the controller
      controller: controller,
    );
  }

  Widget widgetNoData(bool data){
    if(!data){
      setState(() {
        hasData = false;
      });
    }
    Center(
      child: hasData == false ? CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(_colorPrimary),
      ): Text("No Chats")
    );
  }

  Widget buildItem(BuildContext context, DocumentSnapshot document) {
    if(document.data['nickname'].toString().contains(filter)){
      if (document['id'] == id) {
        return Container();
      }
      else {
        return Container(
          child: Column(
            children: <Widget>[
              FlatButton(
                child: Row(
                  children: <Widget>[
                    Material(
                      child: document['photoUrl'] != null ?
                      Stack(
                        children: <Widget>[
                          Material(
                            child: CachedNetworkImage(
                              placeholder: (context, url) => Container(
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.0,
                                  valueColor: AlwaysStoppedAnimation<Color>(_colorPrimary),
                                ),
                                width: 50.0,
                                height: 50.0,
                                padding: EdgeInsets.all(15.0),
                              ),
                              imageUrl: document['photoUrl'],
                              width: 50.0,
                              height: 50.0,
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(26.0)),
                            clipBehavior: Clip.hardEdge,
                          ),
                          Positioned(
                            bottom: 1.0,
                            right: 0.4,
                            child: Container(
                              padding: EdgeInsets.all(1.0),
                              decoration: BoxDecoration(
                                color: document['inRoom']=="offline" ? Colors.red
                                    :Colors.green,
                                border: Border.all(width: 1.0,color: Colors.white),
                                shape: BoxShape.circle,
                              ),
                              constraints: BoxConstraints(
                                minWidth: 10.0,
                                minHeight: 10.0,
                              ),
                            ),
                          ),
                        ],
                      ) : Icon(
                        Icons.account_circle,
                        size: 50.0,
                        color: Colors.black54,
                      ),
                    ),
                    Flexible(
                      child: Container(
                        child: Column(
                          children: <Widget>[
                            Container(
                              child: Text('${document['nickname']}',
                                style: document['isNewContent'] == '1' ? TextStyle(color: Colors.black,fontSize: 15.0)
                                    : TextStyle(color: Colors.black38,fontSize: 15.0),
                              ),
                              alignment: Alignment.centerLeft,
                              margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 3.0),
                            ),
                            /*LAST MSG*/
                            Container(
                              height: 35.0,
                              child: lastMsg(document['id']),
                              alignment: Alignment.centerLeft,
                              margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                            )
                          ],
                        ),
                        margin: EdgeInsets.only(left: 6.0),
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  print('$TAG users_/doc:${id}/col:my_friends/doc:${document['id']} to false');
                  Firestore.instance.collection('users_').document(id).collection('my_friends').document(document['id'])
                      .updateData({'isNewContent': '0'});
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            peerId: document.documentID,
                            peerAvatar: document['photoUrl'],
                            peerName: document['nickname'],
                            peerToken: document['pushToken'],
//                            groupChatId: groupChatId,
                          ))
                  );
                  print("$TAG go to chat");
                },
                onLongPress: (){
                  print("$TAG Show pop up profile and options");
//                          showOptionProfile(document['id'],document['photoUrl']);
                },
                color: Colors.grey[50],
                padding: EdgeInsets.fromLTRB(8.0, 10.0, 8.0, 10.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0.0)),
              ),
              Container(
                width: double.infinity,
                height: 0.3,
                color: Colors.grey,
                margin: const EdgeInsets.only(top: 2.0, bottom: 2.0),
              ),
            ],
          ),
          margin: EdgeInsets.only(bottom: 0.9, left: 0.0, right: 0.0),
        );
      }
    }
    if(filter == ""){
      if (document['id'] == id) {
        return Container();
      }
      else {
        return Container(
          child: Column(
            children: <Widget>[
              FlatButton(
                child: Row(
                  children: <Widget>[
                    Material(
                      child: document['photoUrl'] != null ?
                      Stack(
                        children: <Widget>[
                          Material(
                            child: CachedNetworkImage(
                              placeholder: (context, url) => Container(
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.0,
                                  valueColor: AlwaysStoppedAnimation<Color>(_colorPrimary),
                                ),
                                width: 50.0,
                                height: 50.0,
                                padding: EdgeInsets.all(15.0),
                              ),
                              imageUrl: document['photoUrl'],
                              width: 50.0,
                              height: 50.0,
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(26.0)),
                            clipBehavior: Clip.hardEdge,
                          ),
                          Positioned(
                            bottom: 1.0,
                            right: 0.4,
                            child: Container(
                              padding: EdgeInsets.all(1.0),
                              decoration: BoxDecoration(
                                color: document['inRoom']=="offline" ? Colors.red
                                    :Colors.green,
                                border: Border.all(width: 1.0,color: Colors.white),
                                shape: BoxShape.circle,
                              ),
                              constraints: BoxConstraints(
                                minWidth: 10.0,
                                minHeight: 10.0,
                              ),
                            ),
                          ),
                        ],
                      ) : Icon(
                        Icons.account_circle,
                        size: 50.0,
                        color: Colors.black54,
                      ),
                    ),
                    Flexible(
                      child: Container(
                        child: Column(
                          children: <Widget>[
                            Container(
                              child: Text('${document['nickname']}',
                                style: document['isNewContent'] == '1' ? TextStyle(color: Colors.black,fontSize: 15.0)
                                    : TextStyle(color: Colors.black38,fontSize: 15.0),
                              ),
                              alignment: Alignment.centerLeft,
                              margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 3.0),
                            ),
                            /*LAST MSG*/
                            Container(
                              height: 35.0,
                              child: lastMsg(document['id']),
                              alignment: Alignment.centerLeft,
                              margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                            )
                          ],
                        ),
                        margin: EdgeInsets.only(left: 20.0),
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  print('$TAG users_/doc:${id}/col:my_friends/doc:${document['id']} to false');
                  Firestore.instance.collection('users_').document(id).collection('my_friends').document(document['id'])
                      .updateData({'isNewContent': '0'});
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            peerId: document.documentID,
                            peerAvatar: document['photoUrl'],
                            peerName: document['nickname'],
                            peerToken: document['pushToken'],
                          ))
                  );
                  print("$TAG go to chat");
                },
                onLongPress: (){
                  print("$TAG Show pop up profile and options");
                },
                color: Colors.grey[50],
                padding: EdgeInsets.fromLTRB(25.0, 10.0, 25.0, 10.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0.0)),
              ),
              Container(
                width: double.infinity,
                height: 0.3,
                color: Colors.grey,
                margin: const EdgeInsets.only(top: 2.0, bottom: 2.0),
              ),
            ],
          ),
          margin: EdgeInsets.only(bottom: 0.9, left: 0.0, right: 0.0),
        );
      }
    }
  }

  showOptionProfile(String idProfile, String photoURL){
    showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) -   1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: Stack(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.only(
                      top: 40.0 + 16,
                      bottom: 16,
                      left: 16,
                      right: 16,
                    ),
                    margin: EdgeInsets.only(top: 300.0),
                    decoration: new BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: const Offset(0.0, 10.0),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // To make the card compact
                      children: <Widget>[
                        Text(
                          "Title",
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          "Desc",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.0,
                          ),
                        ),
                        SizedBox(height: 15.0),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Align(
                                alignment: Alignment.bottomLeft,
                                child: FlatButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(); // To close the dialog
                                  },
                                  child: Text("Cancel"),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: FlatButton(
                                  onPressed: () {

                                  },
                                  child: Text("Ok"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 16.0,
                    right: 16.0,
                    top: 250.0,
                    child: CircleAvatar(
                      radius: 40.0,
                      child: Material(
                        child: CachedNetworkImage(
                            imageUrl: '${photoURL}',
                            width: 80.0,
                            height: 80.0,
                            fit: BoxFit.fill
                        ),
                        borderRadius: BorderRadius
                            .all(
                            Radius.circular(40.0)),
                        clipBehavior: Clip.antiAlias,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: true,
        barrierLabel: '',
        context: context,
        pageBuilder: (context, animation1, animation2) {});
  }

  Widget lastMsg(String peerId) {
    if(peerId != null){
      if (id.hashCode <= peerId.hashCode) {
        groupChatId = '$id-$peerId';
      } else {
        groupChatId = '$peerId-$id';
      }
      return new StreamBuilder(
        stream: Firestore.instance
            .collection('messages')
            .document(groupChatId)
            .collection(groupChatId)
            .orderBy('timestamp', descending: true)
//              .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return new Text('');
          }
          return ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.all(0.0),
              reverse: true,
              itemCount: snapshot.data.documents.length,
              itemBuilder: (_, int index) {
                return Column(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          snapshot.data.documents[index]["idFrom"] == id
                              ? Icon(
                              Icons.check_circle,
                              color: snapshot.data.documents[index]["isRead"] == true
                                  ? Colors.blue
                                  : Colors.grey,
                              size: 16.0
                          )
                              : Icon(
                            Icons.check_circle,
                            color: snapshot.data.documents[index]["isRead"] == true
                                ? Colors.green
                                : Colors.grey,
                            size: 16.0,
                          ),
                          SizedBox(
                            width: 3.0,
                          ),
                          Flexible(
                            child: Text('${snapshot.data.documents[index]["content"]}',
                              style: TextStyle(color: Colors.black38),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.all(3.0),
                        child: Text(
                          DateFormat('kk:mm - dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(int.parse(snapshot.data.documents[index]['timestamp']))),
                          style: TextStyle(color: Colors.black38, fontSize: 12.0, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                  ],
                );
              }
          );
        },
      );
    }
  }

}// End Class

class Choice {
  const Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}

class ContactFireBaseModel {
//  int id;
  String createdAt;
  String photoUrl;
  String nickname;
  String id;
  String pushToken;

  ContactFireBaseModel._({
    this.createdAt,
    this.photoUrl,
    this.nickname,
    this.id,
    this.pushToken,
  });

  factory ContactFireBaseModel.fromJson(Map<String, dynamic> json) {
    return new ContactFireBaseModel._(
      createdAt: json['createdAt'],
      photoUrl: json['photoUrl'],
      nickname: json['nickname'],
      id: json['id'],
      pushToken: json['pushToken'],
    );
  }

}
