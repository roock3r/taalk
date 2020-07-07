import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taalk/views/LoginDiscuss.dart';
import 'package:taalk/views/room/AddFriendsScreen.dart';
import 'package:taalk/views/room/ContactFirebaseScreen.dart';
import 'package:taalk/views/room/CreateGroupScreen.dart';
import 'package:taalk/views/room/CreateStoryScreen.dart';
import 'package:taalk/views/room/GroupFirebaseScreen.dart';
import 'package:taalk/views/room/NotificationRoomScreen.dart';
import 'package:taalk/views/room/RequestFriendsListScreen.dart';
import 'package:taalk/views/room/SettingProfileFirebaseScreen.dart';
import 'package:taalk/views/room/StoriesFirebaseScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:imei_plugin/imei_plugin.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taalk/helpers/GlobalVariable.dart' as globals;

class DiscussHomeScreen extends StatefulWidget {
  @override
  _DiscussHomeScreenState createState() => _DiscussHomeScreenState();
}

class _DiscussHomeScreenState extends State<DiscussHomeScreen> with WidgetsBindingObserver,
    SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin{
  String TAG = "DiscussHomeScreen ";


  GlobalKey<ScaffoldState> _drawerKey = GlobalKey();
  bool enabled = true; // tracks if drawer should be opened or not

  // Create a tab controller
  TabController tabController;
  TextEditingController _textFieldController = TextEditingController();
  TextEditingController _textActiveController = TextEditingController();

  FocusNode myFocusNode;

  String icDiscuss = "assets/images/ic_discuss_chat.png";
  String titleDiscuss = "Messages";

  var top = 0.0;
  double heightDrawer = 0.0;
  double widthTitleDiscuss = 280.0;
  bool _isDrawerOpen = false;
  bool isStory = false;

  Color _colorPrimary = Color(0xFF4aacf2);

  String photoUrl;
  String fullNameGmail = "";
  String id = "";
  String IMEI = "";

  int countAllNotification = 0;

  List<String> listRequest = new List<String>();
  int countRequestFriend = 0;
  SharedPreferences prefs;

  final GoogleSignIn googleSignIn = GoogleSignIn();
  FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();

  int countMsg = 0;
  String myFriends = "my_friends";
  int countGroupMsg = 0;

  String code = "";

  @override
  void initState() {
    // TODO: implement initState
    WidgetsBinding.instance.addObserver(this);
    _checkIMEI();
    print("$TAG initState Running");
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(handleTabSelection);
    getPref();
    saveTokenToLocal();
    _checkRequestFriends();
    _checkNotifications();
    _tabCurrentSelected();
    _checkNewMsg();
    _checkNewGroupMsg();
//    _expiredApp();
  }

  _checkIMEI()async {
    String imei_ = await ImeiPlugin.getImei();
    setState(() {
      IMEI = imei_;
      print('$TAG YOUR IMEI DEVICE: $IMEI');
    });
  }

  _expiredApp() async {
    prefs = await SharedPreferences.getInstance();
    QuerySnapshot querySnapshot = await Firestore.instance
        .collection("App")
        .getDocuments();
    var list = querySnapshot.documents;
    for(var i = 0; i < list.length; i++){
      print("$TAG code activation: ${list[i]['code'].toString()}");
      showAlert(list[i]['code'].toString());
//      if(list[i]['IMEI'].toString().contains(IMEI)){
//        print("$TAG App status on");
//      }
//      else{
//        print("$TAG App status off");
//        showAlert();
//      }
    }
  }

  showAlert(String code){
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          WillPopScope(
            onWillPop: (){},
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0.0,
              backgroundColor: Colors.transparent,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Container(
                  padding: EdgeInsets.only(
                    top: 10.0,
                    bottom: 10.0,
                    left: 10.0,
                    right: 10.0,
                  ),
                  margin: EdgeInsets.only(top: 0.0),
                  decoration: new BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 1.0,
                        offset: const Offset(0.4, 1.0),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // To make the card compact
                    children: <Widget>[
                      SizedBox(
                        height: 10.0,
                      ),
                      //   title
                      Padding(
                        padding: EdgeInsets.only(left: 5.0,right: 5.0),
                        child: Text("Your device no have access!",
                            style:
                            TextStyle(fontSize: 18, color: Colors.black,fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(
                        height: 7.0,
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 5.0,right: 5.0),
                        child: Text("Please contact owner for more information",
                            style:
                            TextStyle(fontSize: 16, color: Colors.black)),
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Container(
                            child: Expanded(
                              child:TextField(
                                controller: _textActiveController,
                                decoration: InputDecoration(labelText: 'fill code'),
                              ),
                            )
                          ),
                          FlatButton(
                            color: Colors.green,
                            child: new Text('Submit code'),
                            onPressed: () {
                              if(code.toLowerCase()==_textActiveController.text.toLowerCase().toString()){
                                Navigator.of(context).pop();
                              }else{
                                Fluttertoast.showToast(msg: "Wrong code!",backgroundColor: Colors.red, textColor: Colors.white,
                                    toastLength: Toast.LENGTH_SHORT);
                              }
                            },
                          )
                        ],
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      //close
                      InkWell(
                        onTap: () {
                          exit(0);
                        },
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              Icon(
                                Icons.cancel,
                                size: 32.0,
                                color: Colors.red,
                              ),
                              Padding(
                                  padding: EdgeInsets.fromLTRB(17, 0, 0, 0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text("Exit",
                                          style:
                                          TextStyle(fontSize: 16, color: Colors.red)),
                                    ],
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  getPref() async {
    prefs = await SharedPreferences.getInstance();
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
    setState(() {
      photoUrl = prefs.getString(globals.keyPrefFirebasePhotoUrl);
      fullNameGmail = prefs.getString(globals.keyPrefFirebaseName);
      id = prefs.getString(globals.keyPrefFirebaseUserId) ?? '';
    });
  }

  _checkNewMsg() async {
    prefs = await SharedPreferences.getInstance();
    print("$TAG _checkNewMsg");
    Firestore.instance
        .collection('users_')
        .document(prefs.getString(globals.keyPrefFirebaseUserId))
        .collection(myFriends)
        .where('isNewContent', isEqualTo: '1')
        .snapshots().forEach((value) {
      countMsg = 0;
      for(int i=0; i<value.documents.length;i++){
        if(value.documents[i]['isNewContent']=='1'){
          setState(() {
            countMsg = countMsg + 1;
          });
        }
      }
    });

  }

  _checkNewGroupMsg(){
    print("$TAG _checkNewGroupMsg");
    countGroupMsg = 0;
    Firestore.instance.collection('groups')
        .snapshots().forEach((value) {
      countGroupMsg = 0;
      for(int i=0; i<value.documents.length;i++){
        if(!value.documents[i]['memberRead'].toString().contains(id) && value.documents[i]['member'].contains(id)){
          if(mounted){
            setState(() {
              countGroupMsg = countGroupMsg + 1;
            });
          }
        }
      }
    });

  }

  saveTokenToLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _firebaseMessaging.getToken().then((token) async {
      print('token: $token');
      prefs.setString(globals.keyPrefTokenFirebase, token);
    }).catchError((err) {
      print('$TAG getToken() ${err}');
    });
  }

  _checkRequestFriends() async {
    Firestore.instance.collection("request_friends").where('userIdTo',isEqualTo: id).snapshots().forEach((value) async {
      var data = value.documents;
      QuerySnapshot querySnapshot = await Firestore.instance.collection("request_friends")
          .where('userIdTo',isEqualTo: id)
          .getDocuments();
      var list = querySnapshot.documents;
      for(var i = 0; i < list.length; i++){
        listRequest.add(list[i]['userIdFrom']);
      }
      setState(() {
        countRequestFriend = list.length;
      });
    });
  }

  _tabCurrentSelected() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if(prefs.getInt(globals.keyTabIndex) == null){
      tabController.animateTo(0);
    }else{
      tabController.animateTo(prefs.getInt(globals.keyTabIndex));
    }
  }

  _checkNotifications() async {
    countAllNotification = 0;
    QuerySnapshot querySnapshot = await Firestore.instance.collection("notifications")
        .where('idTo',isEqualTo: "$id")
        .getDocuments();
    var list = querySnapshot.documents;
    print("${fullNameGmail}-${id}");
    print('$TAG length Notif: ${list.length}');
    int x = 0;
    list.forEach((element) {
      print("$TAG isRead? ${element['isRead']}");
      if(element['isRead']==false){
        setState(() {
          countAllNotification = countAllNotification + 1;
        });
      }
    });
  }

  inRoom(String status, int type) async {
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
      if(type==0){
        Firestore.instance.collection('users_')
            .document(id)
            .updateData({'inRoom': status});
      }else{
        Firestore.instance.collection('users_')
            .document(id)
            .updateData({'inRoom': status}).whenComplete(() {
          Timer(const Duration(milliseconds: 1000), () {
            exit(0);
          });
        });
      }
    }
    print("$TAG CLOSED INROOM");
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
      inRoom("offline",0);
    }
    if (state == AppLifecycleState.resumed) {
      print('$TAG - Foreground AppLifecycleState resumed');
      inRoom("online",0);
    }
    if (state == AppLifecycleState.inactive) {
      print('$TAG - Background AppLifecycleState inactive');
      inRoom("offline",0);
    }
  }

  tabCurrentSelected() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    if(prefs.getInt(globals.keyTabIndex) == null){
      tabController.animateTo(0);
    }else{
      tabController.animateTo(prefs.getInt(globals.keyTabIndex));
    }
  }

  Future<void> handleTabSelection() async {
    _checkRequestFriends();
    setState(() {
      heightDrawer = 0.0;
      print('$TAG index tap: ${tabController.index}');
      if(tabController.index==0){
        titleDiscuss = "Messages";
        icDiscuss = "assets/images/ic_discuss_chat.png";
        isStory = false;
      }
      if(tabController.index==1){
        titleDiscuss = "Groups";
        icDiscuss = "assets/images/ic_discuss_group.png";
        isStory = false;
      }
      if(tabController.index==2){
        titleDiscuss = "Stories";
        icDiscuss = "assets/images/ic_discuss_story.png";
        isStory = true;
      }
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(globals.keyTabIndex, tabController.index);
  }

  Future<bool> _onWillPop() {
    return showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        title: new Text('Information'),
        content: new Text('Back to home?'),
        actions: <Widget>[
//          Logout
          new FlatButton(
            onPressed: () {
              inRoom("offline",0);
              handleSignOut();
            },
            child: new Text('Logout acount', style: TextStyle(color: Colors.red),),
          ),
//          Exit/no
          new FlatButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: new Text('No'),
          ),
//          Back to home/yes
          new FlatButton(
            onPressed: () {
              inRoom("offline",1);
              Navigator.of(context).pop(true);
              },
            child: new Text('Yes'),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<bool> onWillPop() {
    return showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        title: new Text('Information'),
        content: new Text('Close application?'),
        actions: <Widget>[
//          Logout
          new FlatButton(
            onPressed: () {
              inRoom("offline",0);
              handleSignOut();
            },
            child: new Text('Logout acount', style: TextStyle(color: Colors.red),),
          ),
//          Exit/no
          new FlatButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: new Text('No'),
          ),
//          Back to home/yes
          new FlatButton(
            onPressed: () {
              inRoom("offline",1);
              Fluttertoast.showToast(msg: "please wait...",backgroundColor: Colors.red, textColor: Colors.white);
              Navigator.of(context).pop(true);
            },
            child: new Text('Yes'),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<Null> handleSignOut() async {
    prefs = await SharedPreferences.getInstance();
    prefs.setString("admin", "123");
    inRoom("offline",0);
    Fluttertoast.showToast(msg: 'Please wait ...',
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
        textColor: Colors.white
    );
    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginDiscuss()),
        ModalRoute.withName("/loginDiscuss"));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ()async {
//          onWillPop();
        Fluttertoast.showToast(msg: "Press home button to close...",backgroundColor: Colors.blue, textColor: Colors.white,toastLength: Toast.LENGTH_LONG);
      },
      child: Scaffold(
        key: _drawerKey,
        backgroundColor: Colors.white,
        body: Stack(
            children: <Widget>[
//          Main
              DefaultTabController(
                length: 3,
                child: Container(
                  child: CustomScrollView(
                    slivers: <Widget>[
                      SliverAppBar(
                        leading: Container(),
                        floating: true,
                        elevation: 4.0,
                        backgroundColor: _colorPrimary,
                        flexibleSpace: LayoutBuilder(builder: (BuildContext context,BoxConstraints constraints) {
                            top = constraints.biggest.height;
                            return FlexibleSpaceBar(
                              centerTitle: true,
                              collapseMode: CollapseMode.parallax,
                              title: AnimatedOpacity(
                                duration: Duration(milliseconds: 300),
                                //opacity: top == 80.0 ? 1.0 : 0.0,
                                opacity: 1.0,
                              ),
                              background: Stack(
                                children: <Widget>[
                                  Align(
                                    alignment: Alignment.center,
                                    child: AnimatedContainer(
                                      duration: Duration(seconds: 1),
                                      curve: Curves.fastOutSlowIn,
                                      width: double.infinity,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget>[
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Image.asset(
                                                "${icDiscuss}", height: 30.0,),
                                              SizedBox(
                                                width: 7.0,
                                              ),
                                              Text("${titleDiscuss}",
                                                style: TextStyle(fontSize: 25.0,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        forceElevated: true,
                        actionsIconTheme: IconThemeData(color: Colors.transparent,size: 0.0),
                        expandedHeight: 140,
                        pinned: true,
                        bottom: getTabBar(),
                      ),
                      /*TAB MENU*/
                      new SliverFillRemaining(
                        child: TabBarView(
                          dragStartBehavior: DragStartBehavior.down,
                          controller: tabController,
                          children: <Widget>[
                            ContactFirebaseScreen(),
                            GroupFirebaseScreen(),
                            StoriesFirebaseScreen()
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        endDrawer: Drawer(
          child: Container(
            padding: EdgeInsets.only(top: 10.0),
            color: Colors.white,
            child: Column(
              children: <Widget>[
//                Header image
                AnimatedContainer(
                  height: heightDrawer,
                  duration: Duration(seconds: 1),
                  curve: Curves.fastOutSlowIn,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                          "assets/images/ic_header_drawer.png"),
                      fit: BoxFit.contain,
                    ),
                  ),
                  child: null /* add child content here */,
                ),
//                User Account
                ListTile(
                  leading: Material(
                    child: CachedNetworkImage(
                        imageUrl: '${photoUrl}',
                        width: 50.0,
                        height: 50.0,
                        fit: BoxFit.fill
                    ),
                    borderRadius: BorderRadius
                        .all(
                        Radius.circular(25.0)),
                    clipBehavior: Clip.hardEdge,
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text("Account name:",style: TextStyle(color: Colors.grey,fontSize: 12.0),),
                      Container(
                        height: 20.0,
                        child: Text("$fullNameGmail",style: TextStyle(fontSize: 16.0),),
                      )
                    ],
                  ),
                ),
                SizedBox(
                  height: 10.0,
                ),
//                Line grey
                Container(
                  padding: EdgeInsets.only(left: 10.0,right: 10.0),
                  height: 0.9,
                  color: Colors.grey[400],
                ),
                SizedBox(
                  height: 10.0,
                ),
//                ScrollH Menu
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    /*Add friends icon*/
                    Container(
                      decoration: new BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: new BorderRadius.circular(30.0),
                      ),
                      child: Card(
                        elevation: 3.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        child: InkWell(
                          onTap: (){
                            Navigator.pop(context, true);
                            Navigator.push(context,MaterialPageRoute(builder: (context) => AddFriendsScreen()),
                            );
                          },
                          child: Container(
                            height: 45.0,
                            padding: EdgeInsets.only(left: 15.0,right: 15.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text("Add friends  "),
                                Icon(
                                    Icons.person_add,
                                    color: Colors.blue
                                )
                              ],
                            ),
                          ),
                        )
                      ),
                    ),
                    /*Group icon*/
                    Container(
                      color: Colors.transparent,
                      child: Card(
                        elevation: 3.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        child: InkWell(
                          onTap: (){
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => CreateGroupScreen()
                                )
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.only(left: 15.0,right: 15.0),
                            height: 45.0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text("Create group  "),
                                Icon(Icons.group_add,
                                    color:Colors.green
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10.0,
                ),
                SingleChildScrollView(
                  child: Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        //                Notifications
                        Card(
                            elevation: 0.0,
                            child: InkWell(
                              onTap: (){
                                Navigator.of(context).pop(false);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => NotificationRoomScreen()
                                    )
                                );
                              },
                              child:ListTile(
                                leading: buildIconBadge(/*Icons.notifications,countAllNotification.toString(),Colors.red[300]*/),
                                title: Text("Notifications"),
                                trailing: Text("${countAllNotification}",style: TextStyle(color: Colors.amber[900]),),
                              ),
                            )
                        ),
                        countRequestFriend > 0 ?
                        Card(
                            elevation: 0.0,
                            child: InkWell(
                              onTap: (){
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            RequestFriendsListScreen(
                                              id: id,
                                              listRequest: listRequest,
                                            )));
                              },
                              child: ListTile(
                                leading: Icon(Icons.person_add,color: Colors.green,size: 27.0,),
                                title: Text('Request friends',),
                                trailing: Text("${countRequestFriend}",style: TextStyle(color: Colors.green),),
                              ),
                            )
                        )
                            : Container(),
//                Setting account
                        Card(
                            elevation: 0.0,
                            child: InkWell(
                              onTap:(){
                                Navigator.of(context).pop(false);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (
                                          context) =>
                                          SettingProfileFirebaseScreen(
                                            type: 1,
                                            id: id,
//                                    titleName: yourName,
                                          )
                                  ),
                                );
                              },
                              child: ListTile(
                                leading: Icon(Icons.settings,size: 30.0,color: Colors.blue,),
                                title: Text('Profile account'),
                              ),
                            )
                        ),
//                Close Drawer
                        Card(
                          elevation: 0.0,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context, true);
                              setState(() {
                                _isDrawerOpen = false;
                                heightDrawer = 0.0;
                              });
                            },
                            child: ListTile(
                              leading: Icon(Icons.arrow_forward, color: Colors.red,size: 30.0,),
                              title: Text("Close menu",
                                style: TextStyle(
                                    color: Colors.red
                                ),
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
        ),
        drawerEdgeDragWidth: 0.0,
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            floatingBtnTimeLine(),
            SizedBox(
              width: 10.0,
            ),
            FloatingActionButton(
              heroTag: "btn2",
              elevation: 4.0,
              onPressed: () {
                _checkNotifications();
                Timer(const Duration(milliseconds: 200), () {
                  print("$TAG show header drawer");
                  setState(() {
                    heightDrawer = 200.0;
                    _isDrawerOpen = true;
                  });
                });
                _drawerKey.currentState.openEndDrawer();
                Timer(const Duration(milliseconds: 1000), () {
                  if(countAllNotification > 0){
                    Fluttertoast.showToast(
                        msg: "You have ${countAllNotification} notifications unread",
                        backgroundColor: Colors.green, textColor: Colors.white);
                  }
                });
              },
              child: Icon(Icons.menu,color: Colors.white,),
              backgroundColor: _colorPrimary,
              foregroundColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }// End Widget build

  Widget floatingBtnTimeLine(){
    if(isStory==true){
      return FloatingActionButton(
        heroTag: "btn1",
        elevation: 4.0,
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => CreateStoryScreen()
              )
          );
        },
        child: Icon(Icons.add,color: Colors.white,),
        backgroundColor: Colors.green,
        foregroundColor: Colors.blue,
      );
    }else{return Container();}
  }

  TabBar getTabBar() {
    return TabBar(
      indicatorColor: Colors.white,
      tabs: <Tab>[
        Tab(
          icon: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(countMsg > 0 ? "$countMsg":"",style: TextStyle(fontSize: 17.0,
                color: tabController.index == 0 ? Colors.white :Colors.grey[400],),),
              SizedBox(width: 4.0,),
              Icon(Icons.chat_bubble,color: tabController.index == 0 ? Colors.white :Colors.grey[400],),
            ],
          ),
//          text: "Chats",
        ),
        Tab(
          icon: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(countGroupMsg > 0 ? "$countGroupMsg":"",style: TextStyle(fontSize: 17.0,
                color: tabController.index == 1 ? Colors.white :Colors.grey[400],),),
              SizedBox(width: 4.0,),
              Icon(Icons.group,color: tabController.index == 1 ? Colors.white :Colors.grey[400],),
            ],
          ),
        ),
        Tab(
          // set icon to the tab
          icon: Icon(Icons.history,color: tabController.index == 2 ? Colors.white :Colors.grey[400],),
//          text: "Stories",
        ),
      ],
      // setup the controller
      controller: tabController,
    );
  }

  Widget buildIconBadge(){
    return Stack(
      children: <Widget>[
        Stack(
          children: <Widget>[
            Icon(
                Icons.notifications,
                size: 30.0,
                color: Colors.yellow[800]
            ),
          ],
        )
      ],
    );
  }

  @override
  // TODO: implement wantKeepAlive
//  bool get wantKeepAlive => throw UnimplementedError();
  bool get wantKeepAlive => true;

}//End Discu