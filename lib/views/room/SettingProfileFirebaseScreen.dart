import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taalk/models/ContactFirebaseModel.dart';
import 'package:taalk/views/LoginDiscuss.dart';
import 'package:taalk/views/room/AddMemberGroupScreen.dart';
import 'package:taalk/views/room/DetailStoriesFirebaseScreen.dart';
import 'package:taalk/views/room/DiscussHomeScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:taalk/helpers/GlobalVariable.dart' as globals;
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert' show Encoding, json;
import 'package:http/http.dart' as http;

class SettingProfileFirebaseScreen extends StatefulWidget {
  int type;
  String id;
  String groupChatId;

  SettingProfileFirebaseScreen({
    this.type,
    this.id,
    this.groupChatId
  });

  @override
  _SettingProfileFirebaseScreenState createState() => _SettingProfileFirebaseScreenState();
}

class _SettingProfileFirebaseScreenState extends State<SettingProfileFirebaseScreen> /*with WidgetsBindingObserver*/{
  String TAG = "SettingProfileFirebaseScreen ";

  SharedPreferences prefs;
  String tokenPeer;
  String photoUrl;
  String myBio = "-";
  String groupDesc = "-";

  int members = 0;
  int liker = 0;
  int disLiker = 0;
  int viewers = 0;
  List<String> listImageStory;
  List<String> listViewers;

  String id;
  String yourName;
  String titleName;

  String timeId = DateTime.now().millisecondsSinceEpoch.toString();

  bool isAdmin = false;
  bool showBottom = false;
  bool isLoading = true;

  List<String> listIdMember = new List<String>();
  List<String> listIdAdmin = new List<String>();
  List<ContactFirebaseModel> listContactFirebaseModel = new List<ContactFirebaseModel>();
  final GoogleSignIn googleSignIn = GoogleSignIn();

  TextEditingController _textFieldController = TextEditingController();

  Color _colorPrimary = Color(0xFF4aacf2);

  File imageFile;
  File imageFileCamera;
  String imageUrl;

  @override
  void initState() {
    // TODO: implement initState
//    WidgetsBinding.instance.addObserver(this);
    super.initState();
    print('$TAG initState Running...');
    print('$TAG type is = ${widget.type}');
    readLocal();
  }

  readLocal() async {
      listIdAdmin.clear();
      listIdMember.clear();
      listContactFirebaseModel.clear();
    prefs = await SharedPreferences.getInstance();
    id = prefs.getString(globals.keyPrefFirebaseUserId) ?? '';
    yourName = prefs.getString(globals.keyPrefFirebaseName) ?? '';
    print('$TAG Your Id: ${id}');

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

    if(widget.type==1){
      print('$TAG show profile = ${widget.type}');
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
        photoUrl = prefs.get(globals.keyPrefFirebasePhotoUrl);
      });

      Firestore.instance.collection('users_').document(id).snapshots().forEach((value){
        print('$TAG Name: ${value.data['nickname']}');
        print('$TAG Biodata: ${value.data['bio']}');
        setState(() {
          titleName = value.data['nickname'];
          myBio = value.data['bio'];
        });
      });
    }

    if(widget.type==2){
      print('$TAG show profile = ${widget.type}');
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
        photoUrl = prefs.get(globals.keyPrefFirebasePhotoUrl);
      });

      Firestore.instance.collection('users_').document(widget.id).snapshots().forEach((value){
        print('$TAG Name: ${value.data['nickname']}');
        print('$TAG Biodata: ${value.data['bio']}');
        setState(() {
          titleName = value.data['nickname'];
          myBio = value.data['bio'];
          photoUrl = value.data['photoUrl'];
          tokenPeer = value.data['pushToken'];
        });
      });
    }

    if(widget.type==3){
      print('$TAG show group = ${widget.type}');
      listIdMember.clear();
      listIdAdmin.clear();

      Firestore.instance.collection('groups').document(widget.id).snapshots().forEach((value){
        print('$TAG LENGTH: ${value.data.length}');
        print('$TAG Name: ${value.data['groupName']}');
        print('$TAG Desc: ${value.data['groupDesc']}');
        print('$TAG member: ${value.data['member']}');
        print('$TAG List.from: ${List.from(value.data['member'])}');
        if(mounted){
          setState(() {
            titleName = value.data['groupName'];
            groupDesc = value.data['groupDesc'];
            photoUrl = value.data['photoGroup'];
            listIdMember = List.from(value.data['member']);
            listIdAdmin = List.from(value.data['admin']);
            print('$TAG listIdMember: ${listIdMember.length}');
          });
        }
        _getContact();
      });
    }
  }

  _getContact() async {
    listContactFirebaseModel.clear();
    for(int i=0; i<listIdMember.length;i++){
      print('$TAG get id: ${listIdMember[i]}');

      QuerySnapshot querySnapshot = await Firestore.instance.collection("users_").where('id',isEqualTo: listIdMember[i])
          .getDocuments();
      var list = querySnapshot.documents;
      print("$TAG OO: ${list.length}");
      for(var i = 0; i < list.length; i++){
        print('$TAG id: ${list[i]['id']}');
        ContactFirebaseModel _contactFirebaseModel = new ContactFirebaseModel();
        _contactFirebaseModel.setContactId = list[i]['id'];
        _contactFirebaseModel.setContactName = list[i]['nickname'];
        _contactFirebaseModel.setContactPhoto = list[i]['photoUrl'];
        _contactFirebaseModel.setContactToken = list[i]['pushToken'];
        if(mounted){
          setState(() {
            listContactFirebaseModel.add(_contactFirebaseModel);
          });
        }
        print("$TAG PP: ${listContactFirebaseModel.length}");
        if(i==list.length-1 && listIdMember.length==listContactFirebaseModel.length){
          setState(() {
            isLoading = false;
          });
        }
      }
    }
    if(listIdAdmin.toString().contains(id)){
      setState(() {
        isAdmin = true;
      });
    }
  }

  _showRename(){
    _textFieldController.text = titleName;
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Rename Account'),
            content: TextField(
              controller: _textFieldController,
              decoration: InputDecoration(labelText: 'rename'),
            ),
            actions: <Widget>[
              new FlatButton(
                child: new Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              new FlatButton(
                child: new Text('Save'),
                onPressed: () {
                  _renameAccount(context,_textFieldController.text.toString());
                  prefs.setString(globals.keyPrefFirebaseName, _textFieldController.text.toString());
                },
              )
            ],
          );
        });
  }

  _showRenameGroup(){
    _textFieldController.text = titleName;
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Rename Group'),
            content: TextField(
              controller: _textFieldController,
              decoration: InputDecoration(labelText: 'rename'),
            ),
            actions: <Widget>[
              new FlatButton(
                child: new Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              new FlatButton(
                child: new Text('Save'),
                onPressed: () {
                  _renameGroup(context,_textFieldController.text.toString());
                },
              )
            ],
          );
        });
  }

  _showReBio(){
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('change biodata'),
            content: TextField(
              controller: _textFieldController,
              decoration: InputDecoration(labelText: '${myBio}'),
            ),
            actions: <Widget>[
              new FlatButton(
                child: new Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              new FlatButton(
                child: new Text('Save'),
                onPressed: () {
                  _renameBiodata(context,_textFieldController.text.toString());
                },
              )
            ],
          );
        });
  }

  _showReBioGroup(){
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('change biodata'),
            content: TextField(
              controller: _textFieldController,
              decoration: InputDecoration(labelText: '${groupDesc}'),
            ),
            actions: <Widget>[
              new FlatButton(
                child: new Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              new FlatButton(
                child: new Text('Save'),
                onPressed: () {
                  _renameBiodataGroup(context,_textFieldController.text.toString());
                },
              )
            ],
          );
        });
  }

  _deleteStory(String id){
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Delete this story?'),
            actions: <Widget>[
              new FlatButton(
                child: new Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              new FlatButton(
                child: new Text('Save'),
                onPressed: () {
                  _deleting(context,id);
                },
              )
            ],
          );
        });
  }

  _deleting(BuildContext context, id){
    Firestore.instance.collection('stories').document(id).delete();
    Fluttertoast.showToast(msg: "You just deleted story",backgroundColor: Colors.green, textColor: Colors.white);
    Navigator.pop(context);
  }

  _renameAccount(BuildContext context ,String name){
    print('$TAG your id: ${id}');

    Firestore.instance.collection('users_').document(id).updateData({'nickname': name});
    Firestore.instance.collection('users_').document(id).snapshots().forEach((value){
      print('$TAG Name: ${value.data['nickname']}');
      setState(() {
        titleName = value.data['nickname'];
      });
    });
    Navigator.pop(context);
    Fluttertoast.showToast(msg: "You just renamed",backgroundColor: Colors.green, textColor: Colors.white);
    _updateNameInFriends(name);
  }

  _renameGroup(BuildContext context ,String name){
    print('$TAG group id: ${widget.id}');

    Firestore.instance.collection('groups').document(widget.id).updateData({'groupName': name});
    Firestore.instance.collection('groups').document(widget.id).snapshots().forEach((value){
      print('$TAG groupName: ${value.data['groupName']}');
      setState(() {
        titleName = value.data['groupName'];
      });
    });
    Navigator.pop(context);
    Fluttertoast.showToast(msg: "You just renamed group",backgroundColor: Colors.green, textColor: Colors.white);
  }

  _updateNameInFriends(String name) async{
    QuerySnapshot querySnapshot = await Firestore.instance.collection("users_")
        .getDocuments();
    var list = querySnapshot.documents;
    print('$TAG lenght2  ${list.length}');
    for(var i = 0; i < list.length; i++){
      print('$TAG id2 ${list[i]['id']}');
      final QuerySnapshot result =
      await Firestore.instance.collection('users_').document(list[i]['id']).collection('my_friends').where('id', isEqualTo: id)
          .getDocuments();
      final List<DocumentSnapshot> documents = result.documents;
      if(documents.length > 0){
        Firestore.instance.collection('users_').document(list[i]['id']).collection('my_friends').document(id)
            .updateData({'nickname': name});
      }
    }
  }

  _renameBiodata(BuildContext context ,String bio){
    print('$TAG your id: ${id}');

    Firestore.instance.collection('users_').document(id).updateData({'bio': bio});
    Firestore.instance.collection('users_').document(id).snapshots().forEach((value){
      print('$TAG Biodata: ${value.data['bio']}');
      setState(() {
        myBio = value.data['bio'];
      });
    });
    Navigator.pop(context);
    Fluttertoast.showToast(msg: "Biodata changed",backgroundColor: Colors.green, textColor: Colors.white);
    _updateBioInFriends(bio);
  }

  _renameBiodataGroup(BuildContext context ,String bio){
    print('$TAG your id: ${id}');

    Firestore.instance.collection('groups').document(widget.id).updateData({'groupDesc': bio});
    Firestore.instance.collection('groups').document(widget.id).snapshots().forEach((value){
      print('$TAG Biodata: ${value.data['groupDesc']}');
      setState(() {
        myBio = value.data['groupDesc'];
      });
    });
    Navigator.pop(context);
    Fluttertoast.showToast(msg: "Descriptions changed",backgroundColor: Colors.green, textColor: Colors.white);
    _updateBioInFriends(bio);
  }

  _updateBioInFriends(String bio) async{
    QuerySnapshot querySnapshot = await Firestore.instance.collection("users_")
        .getDocuments();
    var list = querySnapshot.documents;
    print('$TAG lenght2  ${list.length}');
    for(var i = 0; i < list.length; i++){
      print('$TAG id2 ${list[i]['id']}');
      final QuerySnapshot result =
      await Firestore.instance.collection('users_').document(list[i]['id']).collection('my_friends').where('id', isEqualTo: id)
          .getDocuments();
      final List<DocumentSnapshot> documents = result.documents;
      if(documents.length > 0){
        Firestore.instance.collection('users_').document(list[i]['id']).collection('my_friends').document(id)
            .updateData({'bio': bio});
      }
    }

  }

  inRoom(String status) async {
    QuerySnapshot querySnapshot = await Firestore.instance.collection("users_")
        .getDocuments();
    var list = querySnapshot.documents;
    print('$TAG lenght all users_  ${list.length}');
    for(var i = 0; i < list.length; i++){
      print('$TAG document users_ ${list[i]['id']}');
      final QuerySnapshot result =
      await Firestore.instance.collection('users_').document(list[i]['id'])
          .collection('my_friends').where('id', isEqualTo: id)
          .getDocuments();
      final List<DocumentSnapshot> documents = result.documents;
      if(documents.length > 0){
        print('$TAG update from users_ ${list[i]['id']}');
        print('$TAG to my ${id}');
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

  Future<Null> handleSignOut() async {
    Fluttertoast.showToast(msg: "Logout proccess ...",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER
    );
    inRoom("offline");
    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();
    Timer(const Duration(milliseconds: 600), () {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginDiscuss()),
          ModalRoute.withName("/loginDiscuss"));
    });

  }

  @override
  Widget build(BuildContext context) {
    double c_height = MediaQuery.of(context).size.height;
    return widget.type == 1 ?
    //  type 1 = show my profile -------------------------------------------------------
    WillPopScope(
      onWillPop: (){
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => DiscussHomeScreen()),
            ModalRoute.withName("/discussroom"));
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomSheet: showBottom == true ? Container(
          height: c_height,
          child: Stack(
            children: <Widget>[
              Container(
                  height: c_height,
                  color: Colors.black,
                  child: PhotoView(
                    imageProvider: NetworkImage('${photoUrl}')
                  )
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: EdgeInsets.only(right:7.0, bottom: 10.0),
                  height: 35.0,
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      ButtonTheme(
                        child: FlatButton(
                            shape: new RoundedRectangleBorder(
                                borderRadius: new BorderRadius
                                    .circular(9.0),
                                side: BorderSide(
                                    color: Colors.white)
                            ),
                            color: Colors.transparent,
                            textColor: Colors.white,
                            padding: EdgeInsets.all(8.0),
                            onPressed: () {
                              setState(() {
                                showBottom = false;
                              });
                            },
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .center,
                                children: <Widget>[
                                  Text(
                                    "Minimize ",
                                    style: TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.white
                                    ),
                                  ),
                                  Icon(
                                    Icons.minimize,
                                    size: 20.0,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            )
                        ),
                      ),
                      ButtonTheme(
                        child: FlatButton(
                            shape: new RoundedRectangleBorder(
                                borderRadius: new BorderRadius
                                    .circular(9.0),
                                side: BorderSide(
                                    color: Colors.white)
                            ),
                            color: Colors.transparent,
                            textColor: Colors.white,
                            padding: EdgeInsets.all(8.0),
                            onPressed: () {
                              _showPopUp();
                            },
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .center,
                                children: <Widget>[
                                  Text(
                                    "Change ",
                                    style: TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.white
                                    ),
                                  ),
                                  Icon(
                                    Icons.image,
                                    size: 20.0,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            )
                        ),
                      ),
                    ],
                  ),
                )
              ),
            ],
          ),
        ):Container(
          height: 0.0,
        ),
        body: SingleChildScrollView(
          child: Container(
            color: _colorPrimary,
            child: Column(
              children: <Widget>[
                //  header
                Container(
                  color: _colorPrimary,
                  height: MediaQuery.of(context).size.height/2-50,
                  width: double.infinity,
                  child: Stack(
                    children: <Widget>[
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: EdgeInsets.only(top: 50.0, left: 0.0),
                          child: Container(
                            width: double.infinity,
                            child: Padding(
                              padding: EdgeInsets.only(top: 4.0,
                                  bottom: 4.0,
                                  left: 8.0,
                                  right: 8.0),
                              child: Column(
//                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  //  photo
                                  Material(
                                    child: InkWell(
                                      onTap: () {
//                                          photoView();
                                      setState(() {
                                        showBottom = true;
                                      });
                                      },
                                      child: CachedNetworkImage(
                                          placeholder: (context, url) => Container(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.0,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                            ),
                                            width: 50.0,
                                            height: 50.0,
                                            padding: EdgeInsets.all(15.0),
                                          ),
                                          imageUrl: '${photoUrl}',
                                          width: 55.0,
                                          height: 55.0,
                                          fit: BoxFit.fill
                                      ),
                                    ),
                                    borderRadius: BorderRadius
                                        .all(
                                        Radius.circular(25.0)),
                                    clipBehavior: Clip.hardEdge,
                                  ),
                                  SizedBox(
                                    height: 10.0,
                                  ),
                                  //  rename
                                  Padding(
                                    padding: EdgeInsets.only(
                                        left: 50.0, right: 50.0),
                                    child: ButtonTheme(
                                      minWidth: 80.0,
                                      height: 30.0,
                                      child: FlatButton(
                                          shape: new RoundedRectangleBorder(
                                              borderRadius: new BorderRadius
                                                  .circular(9.0),
                                              side: BorderSide(
                                                  color: Colors.white)
                                          ),
                                          color: Colors.transparent,
                                          textColor: Colors.white,
                                          padding: EdgeInsets.all(8.0),
                                          onPressed: () {
                                            // rename
                                            _showRename();
                                          },
                                          child: Center(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .center,
                                              children: <Widget>[
                                                Text(
                                                  "${titleName} ",
                                                  style: TextStyle(
                                                    fontSize: 14.0,
                                                    color: Colors.white
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.edit,
                                                  size: 20.0,
                                                  color: Colors.white,
                                                ),
                                              ],
                                            ),
                                          )
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 15.0,
                                  ),
                                  // edit bio
                                  Padding(
                                    padding: EdgeInsets.only(left: 10.0),
                                    child: InkWell(
                                      onTap: () {
                                        _showReBio();
                                      },
                                      child: Row(
                                        children: <Widget>[
                                          Text('My Bio ',
                                            style: TextStyle(
                                                color: Colors.white),
                                            textAlign: TextAlign.left,
                                          ),
                                          Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                            size: 20.0,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 9.0,
                                  ),
                                  // bio
                                  Padding(
                                    padding: EdgeInsets.only(
                                        left: 8.0, right: 8.0),
                                    child: Text('$myBio',
                                      maxLines: 3,
                                      overflow: TextOverflow.fade,
                                      style: TextStyle(color: Colors.white),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                //  body scroll
                Container(
                  height: MediaQuery.of(context).size.height/2+80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(60.0),
                      topRight: const Radius.circular(60.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 0.4,
                        offset: const Offset(1.0, 0.0),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                        top: 29.0, left: 19.0, right: 19.0,),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            'My Stories :',
                            style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            child: StreamBuilder(
                              stream: Firestore.instance.collection('stories')
                                  .where('idUser', isEqualTo: widget.id)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          _colorPrimary),
                                    ),
                                  );
                                }
                                else {
                                  return ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: snapshot.data.documents.length,
                                      itemBuilder: (BuildContext context,
                                          int index) =>
                                          buildItem(context,
                                              snapshot.data.documents[index])
                                  );
                                }
                              },
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: showBottom == false ? FloatingActionButton.extended(
          onPressed: () {
            handleSignOut();
          },
          elevation: 4.0,
          icon: Icon(Icons.close,color: Colors.white,),
          label: Text("Logout acount",style: TextStyle(color:Colors.white),),
          backgroundColor: _colorPrimary,
          foregroundColor: _colorPrimary,
        ):Container(),
      ),
    ):
    widget.type == 2 ?
    //  type 2 = show profile someone ----------------------------------------------------
    WillPopScope(
      onWillPop: (){
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => DiscussHomeScreen()),
            ModalRoute.withName("/discussroom"));
      },
      child: Scaffold(
        bottomSheet: showBottom == true ? Container(
          height: c_height,
          child: Stack(
            children: <Widget>[
              Container(
                  height: c_height,
                  color: Colors.black,
                  child: PhotoView(
                      imageProvider: NetworkImage('${photoUrl}')
                  )
              ),
              Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: EdgeInsets.only(right:7.0, bottom: 10.0),
                    height: 35.0,
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        ButtonTheme(
                          child: FlatButton(
                              shape: new RoundedRectangleBorder(
                                  borderRadius: new BorderRadius
                                      .circular(9.0),
                                  side: BorderSide(
                                      color: Colors.white)
                              ),
                              color: Colors.transparent,
                              textColor: Colors.white,
                              padding: EdgeInsets.all(8.0),
                              onPressed: () {
                                setState(() {
                                  showBottom = false;
                                });
                              },
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .center,
                                  children: <Widget>[
                                    Text(
                                      "Minimize ",
                                      style: TextStyle(
                                          fontSize: 12.0,
                                          color: Colors.white
                                      ),
                                    ),
                                    Icon(
                                      Icons.minimize,
                                      size: 20.0,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              )
                          ),
                        ),
                      ],
                    ),
                  )
              ),
            ],
          ),
        ):Container(
          height: 0.0,
        ),
          body: Container(
            color: _colorPrimary,
            height: double.infinity,
            width: double.infinity,
            child: Stack(
              children: <Widget>[
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.only(top: 50.0,left: 0.0),
                    child: Container(
                      width: double.infinity,
                      child: Padding(
                        padding: EdgeInsets.only(top: 4.0,
                            bottom: 4.0,
                            left: 8.0,
                            right: 8.0),
                        child: Column(
//                                mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Material(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    showBottom = true;
                                  });
                                },
                                child: CachedNetworkImage(
                                    placeholder: (context, url) => Container(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.0,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                      ),
                                      width: 50.0,
                                      height: 50.0,
                                      padding: EdgeInsets.all(15.0),
                                    ),
                                    imageUrl: '${photoUrl}',
                                    width: 185.0,
                                    height: 185.0,
                                    fit: BoxFit.fill
                                ),
                              ),
                              borderRadius: BorderRadius
                                  .all(
                                  Radius.circular(90.0)),
                              clipBehavior: Clip.hardEdge,
                            ),
                            SizedBox(
                              height: 10.0,
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 50.0, right: 50.0),
                              child: ButtonTheme(
                                minWidth: 80.0,
                                height: 30.0,
                                child: FlatButton(
                                    shape: new RoundedRectangleBorder(
                                        borderRadius: new BorderRadius.circular(9.0),
                                        side: BorderSide(color: Colors.white)
                                    ),
                                    color: Colors.transparent,
                                    textColor: Colors.white,
                                    padding: EdgeInsets.all(8.0),
                                    onPressed: () {
                                      // rename
                                    },
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget>[
                                          Text(
                                            "${titleName} ",
                                            style: TextStyle(
                                              fontSize: 14.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 9.0,
                            ),
                            Text('My Bio:',
                              style: TextStyle(color: Colors.white),
                              textAlign: TextAlign.left,
                            ),
                            SizedBox(
                              height: 9.0,
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 8.0, right: 8.0),
                              child: Text("$myBio",
                                maxLines: 10,
                                overflow: TextOverflow.fade,
                                style: TextStyle(color: Colors.white),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(top: 35.0,right: 9.0),
                    child: FloatingActionButton.extended(
                      onPressed: () {
                        showConfirmDelete();
                      },
                      elevation: 4.0,
                      icon: Icon(Icons.restore_from_trash,color: Colors.white,),
                      label: Text("Delete user",style: TextStyle(color:Colors.white),),
                      backgroundColor: Colors.red[300],
//                      foregroundColor: _colorPrimary,
                    ),
                  ),
                )
              ],
            ),
          ),
      ),
    ):
    widget.type == 3 ?
    //  type 3 = show profile group ------------------------------------------------------
    WillPopScope(
      onWillPop: () {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => DiscussHomeScreen()),
            ModalRoute.withName("/discussroom"));
      },
      child: Scaffold(
        bottomSheet: showBottom == true ? Container(
          height: c_height,
          child: Stack(
            children: <Widget>[
              Container(
                  height: c_height,
                  color: Colors.black,
                  child: PhotoView(
                      imageProvider: NetworkImage('${photoUrl}')
                  )
              ),
              Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: EdgeInsets.only(right:7.0, bottom: 10.0),
                    height: 35.0,
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        ButtonTheme(
                          child: FlatButton(
                              shape: new RoundedRectangleBorder(
                                  borderRadius: new BorderRadius
                                      .circular(9.0),
                                  side: BorderSide(
                                      color: Colors.white)
                              ),
                              color: Colors.transparent,
                              textColor: Colors.white,
                              padding: EdgeInsets.all(8.0),
                              onPressed: () {
                                setState(() {
                                  showBottom = false;
                                });
                              },
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .center,
                                  children: <Widget>[
                                    Text(
                                      "Minimize ",
                                      style: TextStyle(
                                          fontSize: 12.0,
                                          color: Colors.white
                                      ),
                                    ),
                                    Icon(
                                      Icons.minimize,
                                      size: 20.0,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              )
                          ),
                        ),
                        isAdmin == true ? ButtonTheme(
                          child: FlatButton(
                              shape: new RoundedRectangleBorder(
                                  borderRadius: new BorderRadius
                                      .circular(9.0),
                                  side: BorderSide(
                                      color: Colors.white)
                              ),
                              color: Colors.transparent,
                              textColor: Colors.white,
                              padding: EdgeInsets.all(8.0),
                              onPressed: () {
                                _showPopUp();
                              },
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .center,
                                  children: <Widget>[
                                    Text(
                                      "Change ",
                                      style: TextStyle(
                                          fontSize: 12.0,
                                          color: Colors.white
                                      ),
                                    ),
                                    Icon(
                                      Icons.image,
                                      size: 20.0,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              )
                          ),
                        ):Container(),
                      ],
                    ),
                  )
              ),
            ],
          ),
        ):Container(
          height: 0.0,
        ),
        body: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: Container(
            color: _colorPrimary,
            child: Column(
              children: <Widget>[
                //  header
                Container(
                  color: _colorPrimary,
                  height: MediaQuery.of(context).size.height/2,
                  width: double.infinity,
                  child: Stack(
                    children: <Widget>[
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: EdgeInsets.only(top: 50.0, left: 0.0),
                          child: Container(
                            width: double.infinity,
                            child: Padding(
                              padding: EdgeInsets.only(top: 4.0,
                                  bottom: 4.0,
                                  left: 8.0,
                                  right: 8.0),
                              child: Column(
//                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  //  photoGroup
                                  Material(
                                    child: InkWell(
                                      onTap: (){
                                        setState(() {
                                          showBottom = true;
                                        });
                                      },
                                      child: CachedNetworkImage(
                                          placeholder: (context, url) => Container(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.0,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                            ),
                                            width: 50.0,
                                            height: 50.0,
                                            padding: EdgeInsets.all(15.0),
                                          ),
                                          imageUrl: '${photoUrl}',
                                          width: 55.0,
                                          height: 55.0,
                                          fit: BoxFit.fill
                                      ),
                                    ),
                                    borderRadius: BorderRadius
                                        .all(
                                        Radius.circular(25.0)),
                                    clipBehavior: Clip.hardEdge,
                                  ),
                                  SizedBox(
                                    height: 10.0,
                                  ),
                                  //  rename group
                                  Padding(
                                    padding: EdgeInsets.only(
                                        left: 50.0, right: 50.0),
                                    child: ButtonTheme(
                                      minWidth: 80.0,
                                      height: 30.0,
                                      child: FlatButton(
                                          shape: new RoundedRectangleBorder(
                                              borderRadius: new BorderRadius
                                                  .circular(9.0),
                                              side: BorderSide(
                                                  color: Colors.white)
                                          ),
                                          color: Colors.transparent,
                                          textColor: Colors.white,
                                          padding: EdgeInsets.all(8.0),
                                          onPressed: () {
                                            if (isAdmin == true) {
                                              _showRenameGroup();
                                            }
                                          },
                                          child: Center(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .center,
                                              children: <Widget>[
                                                Text(
                                                  "${titleName} ",
                                                  style: TextStyle(
                                                    fontSize: 14.0,
                                                  ),
                                                ),
                                                isAdmin == true ? Icon(
                                                  Icons.edit,
                                                  size: 20.0,
                                                  color: Colors.white,
                                                ) : Text(""),
                                              ],
                                            ),
                                          )
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 9.0,
                                  ),
                                  //  edit desc group
                                  Padding(
                                    padding: EdgeInsets.only(left: 10.0),
                                    child: InkWell(
                                      onTap: () {
                                        if (isAdmin == true) {
                                          _showReBioGroup();
                                        }
                                      },
                                      child: Row(
                                        children: <Widget>[
                                          Text('Descriptions group: ',
                                            style: TextStyle(
                                                color: Colors.white),
                                            textAlign: TextAlign.left,
                                          ),
                                          isAdmin == true ? Icon(
                                            Icons.edit,
                                            size: 20.0,
                                            color: Colors.white,
                                          ) : Text(""),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 9.0,
                                  ),
                                  //   desc
                                  Padding(
                                    padding: EdgeInsets.only(
                                        left: 8.0, right: 8.0),
                                    child: Text('$groupDesc',
                                      maxLines: 3,
                                      overflow: TextOverflow.fade,
                                      style: TextStyle(color: Colors.white),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                //  body
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height/2,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(60.0),
                      topRight: const Radius.circular(60.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 1.0,
                        offset: const Offset(1.0, 0.0),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(top: 29.0, left: 19.0, right: 19.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Align(
                          alignment: Alignment.topLeft,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                'Member group(${listContactFirebaseModel
                                    .length}) :',
                                style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold
                                ),
                                textAlign: TextAlign.left,
                              ),
                              isAdmin == true ? ButtonTheme(
                                minWidth: 80.0,
                                height: 30.0,
                                child: FlatButton(
                                    shape: new RoundedRectangleBorder(
                                        borderRadius: new BorderRadius
                                            .circular(9.0),
                                        side: BorderSide(
                                            color: Colors.green)
                                    ),
                                    color: Colors.transparent,
                                    textColor: Colors.green,
                                    padding: EdgeInsets.all(8.0),
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(
                                          builder: (context) =>
                                              AddMemberGroupScreen(
                                                  idGroup: widget.id,
                                                  groupName: titleName,
                                                  photoUrl: photoUrl,
                                                  listIdMember: listIdMember)
                                      )
                                      );
                                    },
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .spaceBetween,
                                        children: <Widget>[
                                          Text(
                                            "Add member ",
                                            style: TextStyle(
                                              fontSize: 14.0,
                                            ),
                                          ),
                                          Icon(
                                            Icons.person_add,
                                            size: 20.0,
                                            color: Colors.green,
                                          ),
                                        ],
                                      ),
                                    )
                                ),
                              )
                                  : Container(),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            color: Colors.white,
                            width: double.infinity,
                            child: isLoading == true ? Center(
                             child: CircularProgressIndicator(backgroundColor: Colors.red,)
                            ):ListView.builder(
                                physics: ScrollPhysics(),
                                padding: EdgeInsets.only(bottom: 60.0),
                                itemCount: listContactFirebaseModel.length,
                                itemBuilder: (BuildContext context,
                                    int index) =>
                                    buildItemMember(context,index)),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: isAdmin == true && showBottom == false ? FloatingActionButton.extended(
          onPressed: () {
            showConfirmDeleteGroup();
          },
          elevation: 4.0,
          icon: Icon(Icons.restore_from_trash, color: Colors.white,),
          label: Text("Delete group", style: TextStyle(color: Colors.white),),
          backgroundColor: _colorPrimary,
          foregroundColor: _colorPrimary,
        ):Container(),
      ),
    )
    //  null
        : Scaffold(
          body: Container(
            child: CircularProgressIndicator(),
        ),
    );
  } //End Widget build

  _showPopUp(){
    showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (_context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) -   1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: AlertDialog(
                shape: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                title: Text('Select to'),
                content: Padding(
                  padding: EdgeInsets.only(bottom: 10.0,left: 4.0,right: 4.0),
                  child: Container(
                    height: 100,
                    color: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            InkWell(
                              onTap: (){
                                getImage();
                                Navigator.pop(context);
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Container(
                                      width: 45.0,
                                      height: 45.0,
                                      decoration: new BoxDecoration(
//                          shape: BoxShape.circle,
                                          image: new DecorationImage(
                                              fit: BoxFit.fitWidth,
                                              image: ExactAssetImage(
                                                  "assets/images/ic_gallery_attach.png"
                                              )
                                          )
                                      )
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(top: 4.0),
                                    child: Text("Gallery"),
                                  )
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 15.0,
                            ),
                            InkWell(
                              onTap: (){
                                getImageCamera();
                                Navigator.pop(context);
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Container(
                                    width: 45.0,
                                    height: 45.0,
                                    decoration: new BoxDecoration(
//                          shape: BoxShape.circle,
                                        image: new DecorationImage(
                                            fit: BoxFit.fitWidth,
                                            image: ExactAssetImage(
                                                "assets/images/ic_camera_attach.png"
                                            )
                                        )
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(top: 4.0),
                                    child: Text("Camera"),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
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

  Future getImage() async {
    try{
      imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
      print("You selected gallery image : " + imageFile.path);
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
      StorageUploadTask uploadTask = reference.putFile(imageFile);
      StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
      storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
        imageUrl = downloadUrl;
        updatePhoto(imageUrl);
      }, onError: (err) {
        Fluttertoast.showToast(msg: 'Info: ${err.toString()}');
        print('$TAG Info: ${err.toString()}');
      });
    }catch(e){
      print("$TAG getImage error: ${e}");
    }
  }

  Future getImageCamera() async {
    try{
      imageFile = await ImagePicker.pickImage(source: ImageSource.camera);
      print("You selected camera image : " + imageFile.path);
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
      StorageUploadTask uploadTask = reference.putFile(imageFile);
      StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
      storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
        imageUrl = downloadUrl;
        updatePhoto(imageUrl);
      }, onError: (err) {
        Fluttertoast.showToast(msg: 'Info: ${err.toString()}');
        print('$TAG Info: ${err.toString()}');
      });
    }catch(e){
      print("$TAG getImageCamera error: ${e}");
    }
  }

  updatePhoto(String imageUrl) async {
    Navigator.of(context).pop(true);
    if(widget.type==1){
//      update photo user
      QuerySnapshot querySnapshot = await Firestore.instance.collection("users_")
          .getDocuments();
      var list = querySnapshot.documents;
      print('$TAG lenght2  ${list.length}');
      for(var i = 0; i < list.length; i++){
        print('$TAG id2 ${list[i]['id']}');
        final QuerySnapshot result =
            await Firestore.instance.collection('users_').document(list[i]['id']).collection('my_friends').where('id', isEqualTo: id)
            .getDocuments();
        final List<DocumentSnapshot> documents = result.documents;
        if(documents.length > 0){
          Firestore.instance.collection('users_').document(list[i]['id']).collection('my_friends').document(id)
              .updateData({'photoUrl': imageUrl});
        }
      }
      Firestore.instance.collection('users_').document(id)
          .updateData({'photoUrl': imageUrl});
      prefs.setString(globals.keyPrefFirebasePhotoUrl, imageUrl);
      setState(() {
        photoUrl = imageUrl;
      });

    }
    if(widget.type==3){
//      update photo group
      Firestore.instance.collection('groups').document(widget.id)
          .updateData({'photoGroup': imageUrl});
      setState(() {
        photoUrl = imageUrl;
      });
      Fluttertoast.showToast(msg: "Refreshing group...",backgroundColor: Colors.green, textColor: Colors.white);
    }
    Fluttertoast.showToast(msg: "Refreshing profile ...",backgroundColor: Colors.green, textColor: Colors.white);
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => DiscussHomeScreen()),
        ModalRoute.withName("/discussroom"));
  }

  showConfirmDelete(){
    return showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        title: new Text('Information'),
        content: new Text('are you sure to delete ${titleName}\n'
            'from your contact?'),
        actions: <Widget>[
//          No
          new FlatButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: new Text('No'),
          ),
//          Yes
          new FlatButton(
            onPressed: () async {
              Firestore.instance.collection('users_').document(id)
                  .collection("my_friends")
                  .document(widget.id).delete();
              Firestore.instance.collection('users_').document(widget.id)
                  .collection("my_friends")
                  .document(id).delete();

              String param1 = "${widget.id}-${id}";
              String param2 = "${id}-${widget.id}";
              print("$TAG param1: ${param1}\nparam2: ${param2}");
              print("$TAG widget.groupChatId: ${widget.groupChatId}");

              Firestore.instance.collection("messages").document(widget.groupChatId)
                  .collection(widget.groupChatId)
                  .getDocuments().then((value){
                  print("$TAG - ${value.toString()}");
                  print("$TAG -- ${value.documents.length}");
                  for(int i=0; i< value.documents.length; i++){
                    print("$TAG --- ${value.documents[i].documentID}");
                    Firestore.instance.collection("messages")
                        .document(widget.groupChatId)
                        .collection(widget.groupChatId)
                        .document(value.documents[i].documentID).delete();
                  }
              }).whenComplete((){
                //                    Notification add
                Firestore.instance.collection('notifications')
                    .document("type4-"+timeId+widget.groupChatId)
                    .setData(
                    {
                      'notifId': "type4-"+timeId+widget.groupChatId,
                      'idTo': widget.id,
                      'photoUrlUser': photoUrl,
                      'text': "${yourName} delete you as friend",
                      'isRead': false,
//            contentImageStory: document['contentImageStory'],
//            listViewers: document['viewerStory'],
//            listLikers: document['likerStory'],
//            listDislikers: document['disLikerStory'],
                      'time': timeId,
                      'nameFrom': yourName,
                      'idFrom': id,
                      'type': "4",
                      'tag': "Remove Friend"
                    });
                Fluttertoast.showToast(msg: "You just deleted user",backgroundColor: Colors.green, textColor: Colors.white);
                _pushNotifToMember("You just deleted as friend",1,"");
              });
            },
            child: new Text('Yes'),
          ),
        ],
      ),
    );
  }

  showConfirmDeleteGroup(){
    return showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        title: new Text('Information'),
        content: new Text('are you sure to delete ${titleName} group?\n'
            'and chat history will be delete permanently.'),
        actions: <Widget>[
//          No
          new FlatButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: new Text('No'),
          ),
//          Yes
          new FlatButton(
            onPressed: () {
              Firestore.instance.collection('groups')
                  .document(widget.id).delete();
              Firestore.instance.collection('msg_group')
                  .document(widget.id).delete();

              Firestore.instance.collection("msg_group").document(widget.id)
                  .collection(widget.id)
                  .getDocuments().then((value){
                print("$TAG - ${value.toString()}");
                print("$TAG -- ${value.documents.length}");
                for(int i=0; i< value.documents.length; i++){
                  print("$TAG --- ${value.documents[i].documentID}");
                  Firestore.instance.collection("msg_group")
                      .document(widget.id)
                      .collection(widget.id)
                      .document(value.documents[i].documentID).delete();
                }
              }).whenComplete((){
                Fluttertoast.showToast(msg: "You just deleted group",backgroundColor: Colors.green, textColor: Colors.white);
                _pushNotifToMember("${yourName} as admin, has been deleted group",0,"");
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => DiscussHomeScreen()),
                    ModalRoute.withName("/discussroom"));
              });
            },
            child: new Text('Yes'),
          ),
        ],
      ),
    );
  }

  showConfirmDeleteMember(String _id, String member, String tokenMember){
    return showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        title: new Text('Information'),
        content: new Text('are you sure to delete ${titleName}\n'
            'from ${titleName}?'),
        actions: <Widget>[
//          No
          new FlatButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: new Text('No'),
          ),
//          Yes
          new FlatButton(
            onPressed: () {
              setState(() {
                isLoading = true;
                listIdMember.clear();
                listContactFirebaseModel.clear();
              });
              Firestore.instance.collection('notifications')
                  .document("type1-"+timeId+titleName)
                  .setData(
                  {
                    'notifId': "type1-"+timeId+titleName,
                    'groupId': widget.id,
                    'groupName': titleName,
                    'groupPhoto': photoUrl,
                    'text': "${yourName} Deleted you from ${titleName} group",
                    'isRead': false,
                    'time': timeId,
                    'nameFrom': yourName,
                    'idFrom': id,
                    'nameTo': member,
                    'idTo': _id,
                    'type': "1",
                    'tag': "Delete"
                  });
              Firestore.instance.collection('groups').document(widget.id).updateData({
                'member': (FieldValue.arrayRemove([_id])),
              });
              Fluttertoast.showToast(msg: "You just deleted user",backgroundColor: Colors.green, textColor: Colors.white);
              _pushNotifToMember("you was deleted ${member} from ${titleName}",0,tokenMember);
              Navigator.of(context).pop(false);
              Navigator.of(context).pop(false);
            },
            child: new Text('Yes'),
          ),
        ],
      ),
    );
  }

  Widget buildItemMember(BuildContext context, /*ContactFirebaseModel listContactFirebaseModel,*/ int index, ){
    return new Material(
      child: Stack(
        children: <Widget>[
          ListTile(
            leading: Material(
              child: CachedNetworkImage(
                placeholder: (context, url) =>
                    Container(
                      child: CircularProgressIndicator(
                        strokeWidth: 1.0,
                        valueColor: AlwaysStoppedAnimation<
                            Color>(_colorPrimary),
                      ),
                      width: 30.0,
                      height: 30.0,
                      padding: EdgeInsets.all(
                          10.0),
                    ),
                imageUrl: listContactFirebaseModel[index].getContactPhoto,
                width: 35.0,
                height: 35.0,
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.all(
                  Radius.circular(26.0)),
              clipBehavior: Clip.hardEdge,
            ),
            title: Text(
              listContactFirebaseModel[index].getContactName.toString() == "$yourName" ? "You":listContactFirebaseModel[index].contactName, style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold),),
            trailing: _checkAdmin(listContactFirebaseModel[index].contactId.toString(),index,/*listContactFirebaseModel*/),
          ),
        ],
      ),
    );
  }

  _checkAdmin(String id, int index, /*ContactFirebaseModel _listContactFirebaseModel*/){
    print('$TAG list contains: ${listIdAdmin.toString()} ? ${id}');
    if(listIdAdmin.toString().contains(id)){
      print("$TAG ADMIN");
      return Container(
        width: 90.0,
        height: 34,
        child: ButtonTheme(
          minWidth: 40.0,
          height: 16.0,
          child: FlatButton(
              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(10.0),
                  side: BorderSide(color: Colors.blue)
              ),
              color: Colors.white,
              textColor: Colors.blue,
              padding: EdgeInsets.all(8.0),
              onPressed: () {
                //
              },
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "Admin ",
                      style: TextStyle(
                        fontSize: 14.0,
                      ),
                    ),
                    Icon(
                      Icons.vpn_key,
                      size: 20.0,
                      color: Colors.blue,
                    ),

                  ],
                ),
              )
          ),
        ),
      );
    }
    else{
      print("$TAG MEMBER");
      print("$TAG ${listContactFirebaseModel[index].getContactId.toString()} = ${id}");
      return Container(
        width: 80.0,
        height: 34,
        child: listIdMember.toString().contains(id) && 
            isAdmin == false &&
            listContactFirebaseModel[index].getContactName.toString()=="${yourName}"?
        Text(""):
        isAdmin == true ?
//        Delete
        ButtonTheme(
          minWidth: 40.0,
          height: 16.0,
          child: FlatButton(
              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(10.0),
                  side: BorderSide(color: Colors.red)
              ),
              color: Colors.white,
              textColor: Colors.red,
              padding: EdgeInsets.all(8.0),
              onPressed: () {
                print("$TAG Deleting...");
                showConfirmDeleteMember(id,listContactFirebaseModel[index].getContactName.toString(),
                    listContactFirebaseModel[index].getContactToken.toString());
              },
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "Delete ",
                      style: TextStyle(
                        fontSize: 14.0,
                      ),
                    ),
                    Icon(
                      Icons.restore_from_trash,
                      size: 20.0,
                      color: Colors.red,
                    ),
                  ],
                ),
              )
          ),
        ):Text("")
      );
    }
  }

  Widget buildItem(BuildContext context, DocumentSnapshot document){
    print('$TAG ${document['contentCaptionStory']}');
    print('$TAG my id story ${widget.id}');

    try{
      if(document['likerStory']!=null){
        List<String> listLikers = List.from(document['likerStory']);
        liker = listLikers.length;
      }else{
        liker = 0;
      }
    }on Exception catch(e){
      liker = 0;
    }

    try{
      if(document['disLikerStory']!=null){
        List<String> listDisLikers = List.from(document['disLikerStory']);
        disLiker = listDisLikers.length;
      }else{
        disLiker = 0;
      }
    }on Exception catch(e){
      disLiker = 0;
    }

    try{
      if(document['viewerStory']!=null){
        listViewers = List.from(document['viewerStory']);
        viewers = listViewers.length;
      }else{
        viewers = 0;
      }
    }on Exception catch(e){
      viewers = 0;
    }

    try{
      listImageStory = List.from(document['contentImageStory']);
    }on Exception catch(e){
      listImageStory =['https://icon-library.net/images/no-image-available-icon/no-image-available-icon-6.jpg'];
    }

    print("$TAG time: ${document['timestamp']}");
    var date = new DateTime.fromMillisecondsSinceEpoch(int.parse(document.data['timestamp']));
    DateTime dateTimeNow = DateTime.now();
    final differenceInDays = dateTimeNow.difference(date).inDays;
    print("$TAG Dif: ${differenceInDays}");
//    check if diferent in 1 days or 24hours
    if(differenceInDays>=1){
      Firestore.instance.collection('stories').document(document.documentID).delete();
    }

    return new Stack(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(
              top: 5.0, left: 5.0, bottom: 0.0, right: 5.0),
          child: Card(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            elevation: 0.0,
            child: InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            DetailStoriesFirebaseScreen(
//                              type: "0",
                              idStory: document['idStory'],
                            )));
              },
              child: Container(
                height: 350.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(
                      '${listImageStory[0]}',
                    ),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.8),
                      spreadRadius: 2.0,
                      blurRadius: 2.0,
                      offset: Offset(
                          0, 7), // changes position of shadow
                    ),
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        InkWell(
                          onTap: (){
                            print('$TAG delete story');
                            _deleteStory(document['idStory']);
                          },
                          child: Container(
                            width: 200.0,
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(
                                    0.8),
                                borderRadius: new BorderRadius
                                    .only(
                                    bottomRight: const Radius
                                        .circular(40.0),
                                    bottomLeft: const Radius
                                        .circular(40.0),
                                    topLeft: const Radius
                                        .circular(40.0),
                                    topRight: const Radius
                                        .circular(40.0))
                            ),
                            child: Padding(
                              padding: EdgeInsets.only(top: 4.0,
                                  bottom: 4.0,
                                  left: 8.0,
                                  right: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .center,
                                children: <Widget>[
                                  //  icon delete
                                  Icon(
                                    Icons.delete,
                                    size: 40.0,
                                    color: Colors.red,
                                  ),
                                  SizedBox(
                                    width: 10.0,
                                  ),
                                  Flexible(
                                    child: Text('Delete',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight
                                              .bold),
                                      overflow: TextOverflow.fade,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 20.0,
                        ),
                        Container(
                          width: 240.0,
                          decoration: BoxDecoration(
                              color: Colors.black.withOpacity(
                                  0.3),
                              borderRadius: new BorderRadius
                                  .only(
                                  bottomRight: const Radius
                                      .circular(40.0),
                                  bottomLeft: const Radius
                                      .circular(40.0),
                                  topLeft: const Radius
                                      .circular(40.0),
                                  topRight: const Radius
                                      .circular(40.0))
                          ),
                          child: Padding(
                            padding: EdgeInsets.only(top: 4.0,
                                bottom: 4.0,
                                left: 8.0,
                                right: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .center,
                              children: <Widget>[
                                Flexible(
                                  child: Text('${liker} Likes',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight
                                            .bold),
                                    overflow: TextOverflow.fade,),
                                ),
                                SizedBox(
                                  width: 15.0,
                                ),
                                Flexible(
                                  child: Text('${disLiker} Dislikes',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight
                                            .bold),overflow: TextOverflow.fade,),
                                ),
                                SizedBox(
                                  width: 15.0,
                                ),
                                Flexible(
                                  child: Text('${viewers} Viewers',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight
                                            .bold),overflow: TextOverflow.fade,),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 20.0,
                        ),
                        Container(
                          width: 140.0,
                          decoration: BoxDecoration(
                              color: Colors.black.withOpacity(
                                  0.3),
                              borderRadius: new BorderRadius
                                  .only(
                                  bottomRight: const Radius
                                      .circular(40.0),
                                  bottomLeft: const Radius
                                      .circular(40.0),
                                  topLeft: const Radius
                                      .circular(40.0),
                                  topRight: const Radius
                                      .circular(40.0))
                          ),
                          child: Padding(
                            padding: EdgeInsets.only(top: 4.0,
                                bottom: 4.0,
                                left: 8.0,
                                right: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .center,
                              children: <Widget>[
                                Flexible(
                                  child: Text(
                                    DateFormat('kk:mm - dd MMM yyyy')
                                        .format(
                                        DateTime.fromMillisecondsSinceEpoch(
                                            int.parse(document['timestamp']))),
                                    style: TextStyle(color: Colors.white,
                                        fontSize: 12.0,
                                        fontStyle: FontStyle.italic),
                                    textAlign: TextAlign.right,

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
              ),
            ),
          ),
        ),
      ],
    );
  }

  _pushNotifToMember(String content, int type, String tokenMember) async {
//    0=group, 1=user
    if(type==0){
      for (int i = 0; i < listContactFirebaseModel.length; i++) {
        print("$TAG token out ${listContactFirebaseModel[i].getContactToken}");
        final postUrl = 'https://fcm.googleapis.com/fcm/send';
        final data = {
          "notification": {
            "body": "${content}",
            "title": "Group: ${titleName}"
          },
          "priority": "high",
          "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "id": "1",
            "status": "done"
          },
          "to": "${listContactFirebaseModel[i].getContactToken}"
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

      readLocal();
    }
    if(type==0 && tokenMember.length>0){
      print("$TAG TOKEN: ${tokenMember}");
      final postUrl = 'https://fcm.googleapis.com/fcm/send';
      final data = {
        "notification": {
          "body": "${content}",
          "title": "Group: ${titleName}"
        },
        "priority": "high",
        "data": {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "id": "1",
          "status": "done"
        },
        "to": "${tokenMember}"
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
    if(type==1){
      final postUrl = 'https://fcm.googleapis.com/fcm/send';
      final data = {
        "notification": {
          "body": "${content}",
          "title": "${yourName}"
        },
        "priority": "high",
        "data": {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "id": "1",
          "status": "done"
        },
        "to": "${tokenPeer}"
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
      final postUrl_ = 'https://fcm.googleapis.com/fcm/send';
      final data_ = {
        "notification": {
          "body": "${content}",
          "title": "${yourName}"
        },
        "priority": "high",
        "data": {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "id": "1",
          "status": "done"
        },
        "to": "${tokenPeer}"
      };
      final headers_ = {
        'content-type': 'application/json',
        'Authorization': 'key=${globals.serverKeyFirebaseStatic}'
      };
      final response_ = await http.post(postUrl_,
          body: json.encode(data_),
          encoding: Encoding.getByName('utf-8'),
          headers: headers_);
      if (response_.statusCode == 200) {
        // on success do sth
        print('FCM Success sent');
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => DiscussHomeScreen()),
            ModalRoute.withName("/discussroom"));
      } else {
        // on failure do sth
        print('FCM Failure sent');
      }
    }
  }

}
