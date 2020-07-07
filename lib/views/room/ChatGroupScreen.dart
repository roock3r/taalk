import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:taalk/models/ContactFirebaseModel.dart';
import 'package:taalk/views/room/DiscussHomeScreen.dart';
import 'package:taalk/views/room/ForwardFriendScreen.dart';
import 'package:taalk/views/room/SettingProfileFirebaseScreen.dart';
import 'package:taalk/views/room/ViewPhotoChat.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as IM;

import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:taalk/helpers/GlobalVariable.dart' as globals;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert' show Encoding, json;
import 'package:http/http.dart' as http;

//import '../ViewPhotoChat.dart';

class ChatGroupScreen extends StatefulWidget {
  String groupId;
  String groupName;
  String photoGroup;
  ChatGroupScreen({this.groupId,this.groupName,this.photoGroup});

  @override
  _ChatGroupScreenState createState() => _ChatGroupScreenState();
}

class _ChatGroupScreenState extends State<ChatGroupScreen> /*with WidgetsBindingObserver*/ {
  String TAG = 'Discuss ChatGroupScreen';

  String userNull = "data:image/png;base64,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";

  var listMessage;
  SharedPreferences prefs;

  final TextEditingController textEditingController = new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
  List<dynamic> listMember = new List<dynamic>();
  List<String> listTokenMember = new List<String>();
  List<String> listUserRead = new List<String>();
  List<String> listImage = new List<String>();
  List<dynamic> listMemberRead = new List<dynamic>();
  bool isLoading;

  List<ContactFirebaseModel> listContactFirebaseModel = new List<ContactFirebaseModel>();

  String id;
  String yourName;
  String myPhotoUrl = "";
  String myToken = "";

  File imageFile;
  File imageFileCamera;
  String imageUrl;

  Color _colorPrimary = Color(0xFF4aacf2);

  double Lat = 0.0;
  double Longi = 0.0;

  @override
  void initState() {
    // TODO: implement initState
//    WidgetsBinding.instance.addObserver(this);
    super.initState();
    getPref();
    isLoading = false;
    if(mounted){
      getTokenMember();
    }
  }

  @override
  void dispose() {
//    WidgetsBinding.instance.removeObserver(this);
    // TODO: implement dispose
    super.dispose();
  }


  getTokenMember() async {
    if (mounted) {
      Firestore.instance.collection('groups')
          .document(widget.groupId)
          .snapshots()
          .forEach((value) {
        listMember = value.data['member'];
        for (int i = 0; i < listMember.length; i++) {
          Firestore.instance.collection('users_')
              .document(listMember[i])
              .snapshots()
              .forEach((value) {
            if (mounted) {
              setState(() {
                listTokenMember.add(value.data['pushToken']);
              });
            }
          });
        }
      });
    }
  }

  getListMemberRead(String contentIdGroup) async {
    print("$TAG 111");
    listMemberRead.clear();
    listImage.clear();
    listUserRead.clear();
    if (mounted) {
      Firestore.instance.collection('msg_group')
          .document(widget.groupId)
          .collection(widget.groupId)
          .document(contentIdGroup)
          .snapshots()
          .forEach((value) {
        listMemberRead = value.data['memberReadMsg'];
        for (int i = 0; i < listMemberRead.length; i++) {
          Firestore.instance.collection('users_')
              .document(listMemberRead[i])
              .snapshots()
              .forEach((value) {
            if (mounted) {
              setState(() {
                listImage.add(value.data['photoUrl']);
                listUserRead.add(value.data['nickname']);
              });
            }
          });
        }
      });
    }
  }

  getPref() async {
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

    prefs = await SharedPreferences.getInstance();
    setState(() {
      id = prefs.getString(globals.keyPrefFirebaseUserId) ?? '';
      yourName = prefs.getString(globals.keyPrefFirebaseName) ?? '';
      myPhotoUrl = prefs.getString(globals.keyPrefFirebasePhotoUrl) ?? '';
      myToken = prefs.getString(globals.keyPrefTokenFirebase) ?? '';
    });
    print('$TAG Your Id: ${id}');
    print('$TAG Your Name: ${yourName}');
    print('$TAG Group ID: ${widget.groupId}');
  }

  bool isLastMessageLeft(int index) {
    if ((index > 0 && listMessage != null && listMessage[index - 1]['idFrom'] == id) || index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 && listMessage != null && listMessage[index - 1]['idFrom'] != id) || index == 0) {
      return true;
    } else {
      return false;
    }
  }

  Future getImage() async {
    imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (imageFile != null) {
      setState(() {
        isLoading = true;
      });
      uploadFile();
    }
  }

  Future getImageCamera() async {
    imageFileCamera = await ImagePicker.pickImage(source: ImageSource.camera);
    if (imageFileCamera != null) {
      setState(() {
        isLoading = true;
      });
      uploadFileCamera();
    }
  }

  Future uploadFile() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putFile(imageFile);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
      imageUrl = downloadUrl;
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, 1);
      });
    }, onError: (err) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: 'Info: ${err.toString()}');
      print('$TAG Info: ${err.toString()}');
    });
  }

  Future uploadFileCamera() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putFile(imageFileCamera);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
      imageUrl = downloadUrl;
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, 1);
      });
    }, onError: (err) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: 'Info: ${err.toString()}');
      print('$TAG Info: ${err.toString()}');
    });
  }

  void onSendMessage(String content, int type) async {
    // type: 0 = text, 1 = image, 2 = sticker
    if (content.trim() != '') {
      textEditingController.clear();
      var _date = DateTime.now().toString();
      var documentReference = Firestore.instance
          .collection('msg_group')
          .document(widget.groupId)
          .collection(widget.groupId)
          .document(widget.groupId+_date);

      Firestore.instance.runTransaction((transaction) async {
        await transaction.set(
          documentReference,
          {
            'contentIdGroup': widget.groupId+_date,
            'contentGroup': content,
            'forwardFrom': "",
            'groupId': widget.groupId,
            'idFrom': id,
            'userFrom': yourName,
            'isForward': false,
            'photoUrlFrom': myPhotoUrl,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'contentTime': DateTime.now().toString(),
            'type': type
          },
        );
      });
      listScrollController.animateTo(0.0, duration: Duration(milliseconds: 400), curve: Curves.bounceIn);
      Firestore.instance.collection('groups').document(widget.groupId)
          .updateData(
          {
            'memberRead': (FieldValue.delete())
          });

      if(type==0){
        for(int i=0;i<listTokenMember.length;i++){
          if(listTokenMember[i]!= myToken){
            print('$TAG push to: ${listTokenMember[i]}');
            _pushNotifToMember(listTokenMember[i],content,type);
          }
        }
      }

      if(type==1||type==2){
        for(int i=0;i<listTokenMember.length;i++){
          if(listTokenMember[i]!= myToken){
            print('$TAG push to: ${listTokenMember[i]}');
            _pushNotifToMember(listTokenMember[i],content,type);
          }
        }
      }

      Firestore.instance.collection('groups').document(widget.groupId)
          .updateData(
          {
            'contentTime': DateTime.now().millisecondsSinceEpoch.toString(),
            'lastContentGroup': content,
            'idFrom': id,
            'userFrom': yourName,
            'memberRead': (FieldValue.arrayUnion([id]))
          });

    } else {
      Fluttertoast.showToast(msg: 'Nothing to send');
    }
  }

  _pushNotifToMember(String peerToken, String content, int type) async {
    print('FCM from Flutter');
    if(peerToken != myToken){
      if(type==0){
        final postUrl = 'https://fcm.googleapis.com/fcm/send';
        final data = {
          "notification": {
            "body": "${yourName}: ${content}",
            "title": "Group: ${widget.groupName}"
          },
          "priority": "high",
          "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "id": "1",
            "status": "done"
          },
          "to": "${peerToken}"
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
      else{
        final postUrl = 'https://fcm.googleapis.com/fcm/send';
        final data = {
          "notification": {
            "body": "Image",
            "title": "Group: ${widget.groupName}",
            "image": "${content}"
          },
          "priority": "high",
          "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "id": "1",
            "status": "done"
          },
          "to": "${peerToken}"
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
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: (){
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => DiscussHomeScreen()),
            ModalRoute.withName("/discussroom"));
      },
      child: Scaffold(
        appBar: new AppBar(
          iconTheme: IconThemeData(
            color: Colors.white, //change your color here
          ),
          backgroundColor: _colorPrimary,
          actions: <Widget>[
            InkWell(
              onTap: (){
                print('$TAG group detail');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (
                          context) =>
                          SettingProfileFirebaseScreen(
                            type: 3,
                            id: widget.groupId,
                          )
                  ),
                );
              },
              child: Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 30.0,
              ),
            ),
            SizedBox(
              width: 15.0,
            ),
          ],
          elevation: 3,
          title: Row(
//            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Material(
                child: CachedNetworkImage(
                    imageUrl: widget.photoGroup,
                    width: 35.0,
                    height: 35.0,
                    fit: BoxFit.cover
                ),
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
                clipBehavior: Clip.hardEdge,
              ),
              SizedBox(
                width: 8.0,
              ),
              Flexible(
                child: Text('${widget.groupName}',
                  style: TextStyle(color:Colors.white,fontSize: 16.0),overflow: TextOverflow.ellipsis,maxLines: 1,),
              )
            ],

          ),
          titleSpacing: 0.0,
        ),
        body: Container(
          color: Colors.grey[200],
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  // List of messages
                  buildListMessage(),
                  // Input content
                  buildInput(),
                ],
              ),
              // Loading
              buildLoading()
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLoading() {
    return Positioned(
      child: isLoading
          ? Container(
        child: Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.grey)),
        ),
        color: Colors.white.withOpacity(0.8),
      )
          : Container(),
    );
  }

  Widget buildInput() {
    return Container(
      child: Row(
        children: <Widget>[
          // Button send image
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 1.0),
              child: new IconButton(
                icon: new Icon(Icons.attach_file,color: Colors.red,),
                onPressed: _showAttach,
                color: Colors.grey,
              ),
            ),
            color: Colors.white,
          ),
          // Edit text
          Flexible(
            child: Container(
              child: TextField(
                style: TextStyle(color: Colors.grey, fontSize: 15.0,height: 2.0,),
                controller: textEditingController,
                decoration: InputDecoration.collapsed(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
//                focusNode: focusNode,
              ),
            ),
          ),
          // Button send message
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 8.0),
              child: new IconButton(
                icon: new Icon(Icons.send),
                onPressed: () => onSendMessage(textEditingController.text, 0),
                color: _colorPrimary,
              ),
            ),
            color: Colors.white,
          ),
        ],
      ),
      width: double.infinity,
      height: 50.0,
      decoration: new BoxDecoration(
          border: new Border(top: new BorderSide(color: Colors.grey, width: 0.5)), color: Colors.white),
    );
  }

  Widget _showAttach(){
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Padding(
            padding: EdgeInsets.only(bottom: 10.0,left: 4.0,right: 4.0),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: new BorderRadius.circular(10.0),
                border: Border.all(width: 0.0, color: Colors.transparent),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4.0,
                    offset: const Offset(0.0, 3.0),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
//                      Gallery
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
//                      Camera
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
//                      Location
                      InkWell(
                        onTap: () async {
                          LocationData locationData;
                          Location location = new Location();
                          locationData = await location.getLocation();
                          setState(() {
                            Lat = locationData.latitude;
                            Longi = locationData.longitude;
                          });
                          onSendMessage("https://www.google.com/maps/search/?api=1&query=${Lat},${Longi}", 0);
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
                                          "assets/images/ic_map_attach.png"
                                      )
                                  )
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 4.0),
                              child: Text("Location"),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget buildListMessage() {
    return Flexible(
      child: widget.groupId == ''
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.red)))
          : StreamBuilder(
        stream: Firestore.instance
            .collection('msg_group')
            .document(widget.groupId)
            .collection(widget.groupId)
            .orderBy('timestamp', descending: true)
//            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.red)));
          } else {
            listMessage = snapshot.data.documents;
            return ListView.builder(
              padding: EdgeInsets.all(10.0),
              itemBuilder: (context, index) => buildItem(index, snapshot.data.documents[index]),
              itemCount: snapshot.data.documents.length,
              reverse: true,
              controller: listScrollController,
            );
          }
        },
      ),
    );
  }

  Widget buildItem(int index, DocumentSnapshot document) {
    print('$TAG idFrom ${document['idFrom']}');
    print('$TAG contentIdGroup: ${document['contentIdGroup']}');
    print('$TAG contentGroup: ${document['contentGroup']}');
    print('$TAG type: ${document['type']}');
    Firestore.instance.collection('msg_group')
        .document(document['groupId'])
        .collection(document['groupId'])
        .document(document['contentIdGroup'])
        .updateData(
        {
          'memberReadMsg': (FieldValue.arrayUnion([id])),
        }
    );
    if (document['idFrom'] == id) {
      print('document[idFrom] == id');
      // Right (my message) type: 0 = text, 1 = image, 2 = sticker, 3 Location(Unused)
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          document['type'] == 0
          // Text
              ? Container(
            child: Column(
              children: <Widget>[
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    child: InkWell(
                      onTap: (){
                        _listFriends();
                        _showDialogLongPress(document['contentGroup'],document['contentIdGroup']);
                      },
                      onLongPress: (){
                        _listFriends();
                        _showDialogLongPress(document['contentGroup'],document['contentIdGroup']);
                      },
                      child: Column(
                        children: <Widget>[
                          Align(
                            alignment: Alignment.centerRight,
                            child: Column(
                              children: <Widget>[
                                document['isForward'] == true ?
                                Text('Forwardby: ${document['forwardFrom']}',style: TextStyle(fontSize: 10,color: Colors.red),):
                                SizedBox(),
                              ],
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              children: <Widget>[
                                Linkify(
                                  onOpen: (link){
//                                    _listFriends();
//                                    _showDialogLongPress(document['content']);
                                  },
                                  humanize: true,
                                  text: document['contentGroup'],
                                  style: TextStyle(color:Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 1.0,
                ),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        document["idFrom"] == id
                            ? Icon(
                            Icons.arrow_upward,
                            color: Colors.blue,
                            size: 12.0
                        )
                            : Icon(
                          Icons.arrow_downward,
                          color: Colors.green,
                          size: 12.0,
                        ),
                        Text(
                            DateFormat('kk:mm')
                                .format(DateTime.fromMillisecondsSinceEpoch(int.parse(document['timestamp']))),
                            style: TextStyle(color: Colors.grey[300], fontSize: 12.0, fontStyle: FontStyle.italic),
                            textAlign: TextAlign.right
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
            width: 250.0,
            decoration: BoxDecoration(color: _colorPrimary,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(0.0),
                topLeft: Radius.circular(23.0),
                bottomRight: Radius.circular(23.0),
                bottomLeft: Radius.circular(23.0),
              ),
              boxShadow: [
                new BoxShadow(
                  color: Colors.grey,
                  blurRadius: 1.5,
                  offset: new Offset(1.0, 1.5),
                )
              ],
            ),
            margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20.0 : 10.0, right: 10.0),
          )
              : document['type'] == 1
          // Image
              ? Container(
            child: FlatButton(
              child: Material(
                child: Stack(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerRight,
                      child: CachedNetworkImage(
                        placeholder: (context, url) => Container(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                          ),
                          width: 300.0,
                          height: 300.0,
                          padding: EdgeInsets.all(70.0),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.all(
                              Radius.circular(8.0),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Material(
                          child: Image.asset(
                            'images/img_not_available.jpeg',
                            width: 200.0,
                            height: 200.0,
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.all(
                            Radius.circular(8.0),
                          ),
                          clipBehavior: Clip.hardEdge,
                        ),
                        imageUrl: document['contentGroup'],
                        width: 300.0,
                        height: 300.0,
                        fit: BoxFit.fill,
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: document['isForward'] == true ?
                      Padding(
                        padding: EdgeInsets.only(top: 4.0,bottom: 4.0,right: 4.0,left: 4.0),
                        child: Text('Forwardby: ${document['forwardFrom']}',style: TextStyle(fontSize: 13,color: Colors.red),),
                      ):
                      SizedBox(),
                    ),
                  ],
                ),
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
                clipBehavior: Clip.hardEdge,
              ),
              onPressed: () {
                print('$TAG click image');
                _listFriends();
                _showDialogLongPressImage(document['contentGroup'],document['contentIdGroup']);
              },
              padding: EdgeInsets.all(0),
            ),
            decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(18.0),
                topLeft: Radius.circular(18.0),
                bottomRight: Radius.circular(18.0),
                bottomLeft: Radius.circular(18.0),
              ),
              boxShadow: [
                new BoxShadow(
                  color: Colors.grey,
                  blurRadius: 2.0,
                  offset: new Offset(1.0, 1.5),
                )
              ],
            ),
            margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20.0 : 10.0, right: 10.0),
          )
          // Sticker
              : Container(
            color: Colors.green,
            child: new Image.asset(
              'images/${document['content']}.gif',
              width: 100.0,
              height: 100.0,
              fit: BoxFit.cover,
            ),
            margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20.0 : 10.0, right: 10.0),
          ),
          isLastMessageRight(index)
              ? Material(
            child: CachedNetworkImage(
              placeholder: (context, url) => Container(
                child: CircularProgressIndicator(
                  strokeWidth: 1.0,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
                width: 35.0,
                height: 35.0,
                padding: EdgeInsets.all(10.0),
              ),
              imageUrl: document['photoUrlFrom'],
              width: 35.0,
              height: 35.0,
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.all(
              Radius.circular(18.0),
            ),
            clipBehavior: Clip.hardEdge,
          )
              : Container(width: 35.0),
        ],
      );
    }
    else {
      print('document[idFrom] == id');
      // Left (peer message) type: 0 = text, 1 = image, 2 = sticker, 3 Location(unused)
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Material(
                  child: CachedNetworkImage(
                    placeholder: (context, url) => Container(
                      child: CircularProgressIndicator(
                        strokeWidth: 1.0,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                      width: 35.0,
                      height: 35.0,
                      padding: EdgeInsets.all(10.0),
                    ),
                    imageUrl: document['photoUrlFrom'],
                    width: 35.0,
                    height: 35.0,
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.all(
                    Radius.circular(18.0),
                  ),
                  clipBehavior: Clip.hardEdge,
                ),
                SizedBox(width: 9.0,),
                document['type'] == 0
                // Text
                    ? Container(
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          child: InkWell(
                            onTap: (){
                              _listFriends();
                              _showDialogLongPress(document['contentGroup'],document['contentIdGroup']);
                            },
                            onLongPress: (){
                              _listFriends();
                              _showDialogLongPress(document['contentGroup'],document['contentIdGroup']);
                            },
                            child: Column(
                              children: <Widget>[
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Column(
                                    children: <Widget>[
                                      document['isForward'] == true ?
                                      Text('Forwardby: ${document['forwardFrom']}',style: TextStyle(fontSize: 10,color: Colors.red),):
                                      SizedBox(),
                                    ],
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    children: <Widget>[
                                      Linkify(
                                        onOpen: (link){
//                                          _listFriends();
//                                          _showDialogLongPress(document['content']);
                                        },
                                        humanize: true,
                                        text: document['contentGroup'],
                                        style: TextStyle(color:Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 1.0,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              document["idFrom"] == id
                                  ? Icon(
                                  Icons.arrow_upward,
                                  color: Colors.blue,
                                  size: 12.0
                              )
                                  : Icon(
                                Icons.arrow_downward,
                                color: Colors.green,
                                size: 12.0,
                              ),
                              Text(
                                  DateFormat('kk:mm')
                                      .format(DateTime.fromMillisecondsSinceEpoch(int.parse(document['timestamp']))),
                                  style: TextStyle(color: Colors.grey[700], fontSize: 12.0, fontStyle: FontStyle.italic),
                                  textAlign: TextAlign.right
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                  width: 250.0,
                  decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(23.0),
                      topLeft: Radius.circular(0.0),
                      bottomRight: Radius.circular(23.0),
                      bottomLeft: Radius.circular(23.0),
                    ),
                    boxShadow: [
                      new BoxShadow(
                        color: Colors.grey,
                        blurRadius: 1.5,
                        offset: new Offset(1.0, 1.5),
                      )
                    ],
                  ),
                  margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20.0 : 10.0, right: 10.0),
                )
                    : document['type'] == 1
                // Image
                    ? Container(
                  child: FlatButton(
                    child: Material(
                      child: Stack(
                        children: <Widget>[
                          Align(
                            alignment: Alignment.centerRight,
                            child: CachedNetworkImage(
                              placeholder: (context, url) => Container(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                ),
                                width: 300.0,
                                height: 300.0,
                                padding: EdgeInsets.all(70.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8.0),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Material(
                                child: Image.asset(
                                  'images/img_not_available.jpeg',
                                  width: 200.0,
                                  height: 200.0,
                                  fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8.0),
                                ),
                                clipBehavior: Clip.hardEdge,
                              ),
                              imageUrl: document['contentGroup'],
                              width: 300.0,
                              height: 300.0,
                              fit: BoxFit.fill,
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: document['isForward'] == true ?
                            Padding(
                              padding: EdgeInsets.only(top: 4.0,bottom: 4.0,right: 4.0,left: 4.0),
                              child: Text('Forwardby: ${document['forwardFrom']}',style: TextStyle(fontSize: 13,color: Colors.red),),
                            ):
                            SizedBox(),
                          ),
                        ],
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      clipBehavior: Clip.hardEdge,
                    ),
                    onPressed: () {
                      print('$TAG click image');
                      _listFriends();
                      _showDialogLongPressImage(document['contentGroup'],document['contentIdGroup']);
                    },
                    padding: EdgeInsets.all(0),
                  ),
                  decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(18.0),
                      topLeft: Radius.circular(18.0),
                      bottomRight: Radius.circular(18.0),
                      bottomLeft: Radius.circular(18.0),
                    ),
                    boxShadow: [
                      new BoxShadow(
                        color: Colors.grey,
                        blurRadius: 2.0,
                        offset: new Offset(1.0, 1.5),
                      )
                    ],
                  ),
                  margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20.0 : 10.0, right: 10.0),
                )
                // Sticker
                    : Container(
                  child: new Image.asset(
                    'images/${document['content']}.gif',
                    width: 100.0,
                    height: 100.0,
                    fit: BoxFit.cover,
                  ),
                  margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20.0 : 10.0, right: 10.0),
                ),
              ],
            ),
            // Time
            isLastMessageLeft(index)
                ? Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
//                color: Colors.grey[300],
              ),
              child: Text(
                  DateFormat('dd MMM yyyy')
                      .format(DateTime.fromMillisecondsSinceEpoch(int.parse(document['timestamp']))),
                  style: TextStyle(color: Colors.grey, fontSize: 12.0, fontStyle: FontStyle.italic), textAlign: TextAlign.center
              ),
              margin: EdgeInsets.only(left: 0.0, top: 0.0, bottom: 2.0),
            )
                : Container()
          ],
        ),
        margin: EdgeInsets.only(bottom: 5.0),
      );
    }

  }

  _listFriends() async {
    Firestore.instance.collection('users_').document(id).collection('my_friends')
        .orderBy('nickname', descending: false).snapshots()
        .listen((data) => data.documents.forEach((doc){
      print('$TAG id: ${doc['id']}');
      print('$TAG nickname: ${doc['nickname']}');
      if(doc['id']!= id){
        ContactFirebaseModel _contactFirebaseModel = new ContactFirebaseModel();
        _contactFirebaseModel.setContactId = doc['id'];
        _contactFirebaseModel.setContactName = doc['nickname'];
        _contactFirebaseModel.setContactPhoto = doc['photoUrl'];
        _contactFirebaseModel.setContactToken = doc['pushToken'];
        _contactFirebaseModel.setIsChecked = false;
        listContactFirebaseModel.add(_contactFirebaseModel);
      }
      print('$TAG LIST: ${listContactFirebaseModel.length}');
    })
    );
  }

  _showDialogLongPress(String content, String contentIdGroup) async {
    MediaQueryData deviceInfo = MediaQuery.of(context);
    showDialog(
      context: context,
      barrierDismissible: true,
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
//                      Copy
                      InkWell(
                        onTap: () {
                          Clipboard.setData(new ClipboardData(text: content));
                          Fluttertoast.showToast(msg: 'Text copied');
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              Image.asset('assets/images/ic_copy_chat.png',
                                  height: 27),
                              Padding(
                                  padding: EdgeInsets.fromLTRB(17, 0, 0, 0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text("Copy text",
                                          style:
                                          TextStyle(fontSize: 16, color: Colors.black)),
                                    ],
                                  )),
                            ],
                          ),
                        ),
                      ),
//                      Forward
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (
                                    context) =>
                                    ForwardFriendScreen(
                                      type: 0,
                                      content: content,
                                      listContactFirebaseModel: listContactFirebaseModel,
                                    )),
                          );

                        },
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              Image.asset('assets/images/ic_forward_chat.png',
                                  height: 27),
                              Padding(
                                  padding: EdgeInsets.fromLTRB(17, 0, 0, 0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text("Forward to",
                                          style:
                                          TextStyle(fontSize: 16, color: Colors.black)),
                                    ],
                                  )),
                            ],
                          ),
                        ),
                      ),
//                      user have read
                      InkWell(
                        onTap: () {
                          showMemberReadDialog(deviceInfo,contentIdGroup);
                        },
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              Icon(Icons.remove_red_eye,color: Colors.blueAccent,size: 27.0,),
                              Padding(
                                  padding: EdgeInsets.fromLTRB(17, 0, 0, 0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text("Who have read",
                                          style:
                                          TextStyle(fontSize: 16, color: Colors.black)),
                                    ],
                                  )),
                            ],
                          ),
                        ),
                      ),
                      //close
                      InkWell(
                        onTap: () {
                          listContactFirebaseModel.clear();
                          Navigator.pop(context);
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
                                      Text("Close",
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

  showMemberReadDialog(MediaQueryData deviceInfo, String contentIdGroup){
    getListMemberRead(contentIdGroup);
    showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeOut.transform(a1.value) -   1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: Material(
                child: Container(
                  margin: EdgeInsets.only(left: 0.0,right: 0.0,top: 130.0,),
                  decoration: new BoxDecoration(
                      color: Colors.white,
                      borderRadius: new BorderRadius.only(
                          topLeft: const Radius.circular(40.0),
                          topRight: const Radius.circular(40.0)
                      )
                  ),
                  child: AnimationConfiguration.staggeredList(
                    position: 1,
                    duration: const Duration(milliseconds: 150),
                    child: SlideAnimation(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(top: 30.0,left: 15.0),
                              child: Text("Read message",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
                            ),
                            SizedBox(
                              height: 7.0,
                            ),
                            Expanded(
                              child: Container(
//                              height: deviceInfo.size.height - 220,
                                color: Colors.white,
                                child: ListView.builder(
                                  padding: EdgeInsets.only(top: 0.0),
                                  itemBuilder:(context, index) {
                                    return ListTile(
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
                                          imageUrl: listImage[index],
                                          width: 35.0,
                                          height: 35.0,
                                          fit: BoxFit.cover,
                                        ),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(26.0)),
                                        clipBehavior: Clip.hardEdge,
                                      ),
                                      title: Text(listUserRead[index]== yourName ? 'You' : listUserRead[index]),
                                    );
                                  },
                                  itemCount: listUserRead.length,
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
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: true,
        barrierLabel: '',
        context: context,
        pageBuilder: (context, animation1, animation2) {});
  }

  _showDialogLongPressImage(String content, String contentIdGroup) async {
    MediaQueryData deviceInfo = MediaQuery.of(context);
    showDialog(
      context: context,
      barrierDismissible: true,
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
                      //  view full image
                      InkWell(
                        onTap: () {
                          Navigator.push(context,MaterialPageRoute(builder: (context) => ViewPhotoChat(urlPhoto: content,)));
                        },
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              Image.asset('assets/images/ic_image_detail.png',
                                  height: 27),
                              Padding(
                                  padding: EdgeInsets.fromLTRB(17, 0, 0, 0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text("View full screen",
                                          style:
                                          TextStyle(fontSize: 16, color: Colors.black)),
                                    ],
                                  )),
                            ],
                          ),
                        ),
                      ),
                      //  user have read
                      InkWell(
                        onTap: () {
                          showMemberReadDialog(deviceInfo,contentIdGroup);
                        },
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              Icon(Icons.remove_red_eye,color: Colors.blueAccent,size: 27.0,),
                              Padding(
                                  padding: EdgeInsets.fromLTRB(17, 0, 0, 0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text("Who have read",
                                          style:
                                          TextStyle(fontSize: 16, color: Colors.black)),
                                    ],
                                  )),
                            ],
                          ),
                        ),
                      ),
                      //   forward
                      InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (
                                      context) =>
                                      ForwardFriendScreen(
                                        type: 1,
                                        content: content,
                                        listContactFirebaseModel: listContactFirebaseModel,
                                      ))
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              Image.asset('assets/images/ic_forward_chat.png',
                                  height: 27),
                              Padding(
                                  padding: EdgeInsets.fromLTRB(17, 0, 0, 0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text("Forward to",
                                          style:
                                          TextStyle(fontSize: 16, color: Colors.black)),
                                    ],
                                  )),
                            ],
                          ),
                        ),
                      ),
                      //close
                      InkWell(
                        onTap: () {
                          listContactFirebaseModel.clear();
                          Navigator.pop(context);
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
                                      Text("Close",
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

}
