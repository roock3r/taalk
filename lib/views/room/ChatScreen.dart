import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:taalk/helpers/Environtment.dart';
import 'package:taalk/models/ContactFirebaseModel.dart';
import 'package:taalk/views/room/DiscussHomeScreen.dart';
import 'package:taalk/views/room/ForwardFriendScreen.dart';
import 'package:taalk/views/room/SettingProfileFirebaseScreen.dart';
import 'package:taalk/views/room/ViewPhotoChat.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taalk/helpers/GlobalVariable.dart' as globals;
import 'dart:convert' show Encoding, json;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:image/image.dart' as IM;

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerAvatar;
  final String peerName;
  final String peerToken;
//  final String groupChatId;

  ChatScreen({Key key, @required this.peerId, @required this.peerAvatar, @required this.peerName, @required this.peerToken/*, @required this.groupChatId*/}) : super(key: key);

  @override
  State createState() => new ChatScreenState(peerId: peerId, peerAvatar: peerAvatar, peerName: peerName, peerToken: peerToken);
}

class ChatScreenState extends State<ChatScreen> {
  String TAG ="ChatScreen ";

  ChatScreenState({Key key, @required this.peerId, @required this.peerAvatar, @required this.peerName, @required this.peerToken});

  List<ContactFirebaseModel> listContactFirebaseModel = new List<ContactFirebaseModel>();
  bool isChecked = false;

  String peerId;
  String peerAvatar;
  String peerName;
  String peerToken;
  String id;
  String yourName;
  String myPhotoUrl;

  var listMessage;
  String groupChatId = '';
  SharedPreferences prefs;

  File imageFile;
  File imageFileCamera;
  bool isLoading;
  bool isShowSticker;
  String imageUrl;
  String inRoom = "";
  String filter = "";

  double Lat = 0.0;
  double Longi = 0.0;

//  bool isOnline = false;
  String status = "offline";

  Color _colorPrimary = Color(0xFF4aacf2);

  TextEditingController _textFieldController = TextEditingController();
  TextEditingController _textFieldControllerContactForward = TextEditingController();
  final TextEditingController textEditingController = new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
  final FocusNode focusNode = new FocusNode();

//  Permission permission;

  @override
  void initState() {
    super.initState();
    print('$TAG initState Running...');
    _getPref();
    _getInRoom();
    focusNode.addListener(onFocusChange);
    isLoading = false;
    isShowSticker = false;
    imageUrl = '';

    readLocal();
    checkStatus();
  }

  checkStatus(){
    Firestore.instance.collection('users_')
        .where("id",isEqualTo: widget.peerId)
        .snapshots().forEach((element) {
      print("$TAG status: ${element.documents[0]['inRoom']}");
      if(element.documents[0]['inRoom'].toString().contains("online")){
        if(mounted){
          setState(() {
            status = "Online";
          });
        }
      }
      if(element.documents[0]['inRoom'].toString().contains("offline")){
        if(mounted){
          setState(() {
            status = "Offline";
          });
        }
      }
    });
  }

  _getInRoom() async {
    Firestore.instance
        .collection('users')
        .where("id", isEqualTo: peerId)
        .snapshots()
        .listen((data) =>
        data.documents.forEach(
                (doc) => ({
              inRoom = doc['inRoom']
            })
        )
    );
  }

  _getPref()async{
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

  void onFocusChange() {
    if (focusNode.hasFocus) {
      // Hide sticker when keyboard appear
      setState(() {
        isShowSticker = false;
      });
    }
  }

  readLocal() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      id = prefs.getString(globals.keyPrefFirebaseUserId) ?? '';
      yourName = prefs.getString(globals.keyPrefFirebaseName) ?? '';
      myPhotoUrl = prefs.getString(globals.keyPrefFirebasePhotoUrl) ?? '';
    });
    print('$TAG Your Id: ${id}');
    if (id.hashCode <= peerId.hashCode) {
      groupChatId = '$id-$peerId';
      print('$TAG groupChatId[id-peerId]: ${groupChatId}');
    } else {
      groupChatId = '$peerId-$id';
      print('$TAG groupChatId[peerId-id]: ${groupChatId}');
    }
  }

  Future getImage() async {
    try{
      imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
      if (imageFile != null) {
        setState(() {
          isLoading = true;
        });
        uploadFile();
      }
    }catch(e){
      print("$TAG getImage() error: ${e.toString()}");
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

  void getSticker() {
    // Hide keyboard when sticker appear
    focusNode.unfocus();
    setState(() {
      isShowSticker = !isShowSticker;
    });
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

  _showDialogLongPress(String content) async {
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

  _showDialogLongPressImage(String content) async {
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

  void onSendMessage(String content, int type) async {
    // type: 0 = text, 1 = image, 2 = sticker
    if (content.trim() != '') {
      textEditingController.clear();
      var _date = DateTime.now().toString();
      var documentReference = Firestore.instance
          .collection('messages')
          .document(groupChatId)
          .collection(groupChatId)
          .document(_date);

      print("$TAG my id 'idFrom': ${id}");

      Firestore.instance.runTransaction((transaction) async {
        await transaction.set(
          documentReference,
          {
            'idFrom': id,
            'forwardFrom': "",
            'isForward': false,
            'idTo': peerId,
            'isRead': false,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'times': _date,
            'content': content,
            'type': type
          },
        );
      });
      listScrollController.animateTo(0.0, duration: Duration(milliseconds: 400), curve: Curves.bounceIn);
      if(type==0){

        print('FCM from Flutter');
        final postUrl = 'https://fcm.googleapis.com/fcm/send';
        final data = {
          "notification": {
            "body": "${content}",
            "title": "${yourName}",
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

      if(type==1||type==2){
        print('FCM from Flutter');
        final postUrl = 'https://fcm.googleapis.com/fcm/send';
        final data = {
          "notification": {
            "body": "[Image]",
            "title": "${yourName}",
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

      Firestore.instance.collection('users_').document(peerId).collection('my_friends').document(id)
          .updateData({'contentTime': DateTime.now().toString()});

      Firestore.instance.collection('users_').document(id).collection('my_friends').document(peerId)
          .updateData({'contentTime': DateTime.now().toString()});

      Firestore.instance.collection('users_').document(peerId).collection('my_friends').document(id)
          .updateData({'isNewContent': '1'});

    } else {
      Fluttertoast.showToast(msg: 'Nothing to send');
    }
  }

  Widget buildItem(int index, DocumentSnapshot document) {

    //  update isRead = true, where idTo = id
    bool isRead = false;
    print('$TAG peerId: ${peerId}');
    print('$TAG id: ${id}');
    print('$TAG idTo: ${document['idTo']}');


    if (document['idTo'] == id) {
      print('$TAG Update isRead');
      Firestore.instance.collection('messages').document(groupChatId).collection(groupChatId).where('times', isEqualTo: document['times']).snapshots()
          .forEach((value) {
        print('$TAG isRead idTo = ${id}: ${value.toString()}');

        Firestore.instance.collection('messages').document(groupChatId).collection(groupChatId).document(document['times'])
          .updateData({'isRead': true}).then((onValue){
        });

      });
    }
    else{
      print('$TAG Do not isRead');
    }

    if (document['idFrom'] == id) {
      // Right (my message) type: 0 = text, 1 = image, 2 = sticker, 3 Location(Unused)
      return Row(
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
                        _showDialogLongPress(document['content']);
                      },
                      onLongPress: (){
                        _listFriends();
                        _showDialogLongPress(document['content']);
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
                                  onOpen: (link) async {
                                    if (await canLaunch(document['content'])) {
                                      await launch(
                                        document['content'],
                                      );
                                    }
                                    else {
                                      throw 'Could not launch $link';
                                    }
                                  },
                                  humanize: true,
                                  text: document['content'],
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
                            Icons.check_circle,
                            color: document["isRead"] == true
                                ? Colors.blue
                                : Colors.grey,
                            size: 12.0
                        )
                            : Icon(
                          Icons.check_circle,
                          color: document["isRead"] == true
                              ? Colors.green
                              : Colors.grey,
                          size: 12.0,
                        ),
                        Text(
                            DateFormat('kk:mm')
                                .format(DateTime.fromMillisecondsSinceEpoch(int.parse(document['timestamp']))),
                            style: TextStyle(color: Colors.white, fontSize: 12.0, fontStyle: FontStyle.italic),
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
                topRight: Radius.circular(23.0),
                topLeft: Radius.circular(23.0),
                bottomRight: Radius.circular(0.0),
                bottomLeft: Radius.circular(23.0),
              ),
              boxShadow: [
                new BoxShadow(
                  color: Colors.grey,
                  blurRadius: 4.5,
                  spreadRadius: 0.3,
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
                        imageUrl: document['content'],
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
                _showDialogLongPressImage(document['content']);
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
                  blurRadius: 4.5,
                  spreadRadius: 0.3,
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
        mainAxisAlignment: MainAxisAlignment.end,
      );
    }
    else {
      // Left (peer message) type: 0 = text, 1 = image, 2 = sticker, 3 Location (Unused)
      return Container(
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
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
                              print("$TAG CLICK");
                              _listFriends();
                              _showDialogLongPress(document['content']);
                            },
                            onLongPress: (){
                              print("$TAG LONG CLICK");
                              _listFriends();
                              _showDialogLongPress(document['content']);
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
                                        onOpen: (link) async {
                                          if (await canLaunch(document['content'])) {
                                            await launch(
                                              document['content'],
                                            );
                                          }
                                          else {
                                            throw 'Could not launch $link';
                                          }
                                        },
                                        humanize: true,
                                        text: document['content'],
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
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              document["idFrom"] == id
                                  ? Icon(
                                  Icons.check_circle,
                                  color: document["isRead"] == true
                                      ? Colors.blue
                                      : Colors.grey,
                                  size: 12.0
                              )
                                  : Icon(
                                Icons.check_circle,
                                color: document["isRead"] == true
                                    ? Colors.green
                                    : Colors.grey,
                                size: 12.0,
                              ),
                              Text(
                                  DateFormat('kk:mm')
                                      .format(DateTime.fromMillisecondsSinceEpoch(int.parse(document['timestamp']))),
                                  style: TextStyle(color: Colors.grey[400], fontSize: 12.0, fontStyle: FontStyle.italic),
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
                        blurRadius: 4.5,
                        spreadRadius: 0.3,
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
                              imageUrl: document['content'],
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
                      _showDialogLongPressImage(document['content']);
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
                        blurRadius: 4.5,
                        spreadRadius: 0.3,
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
              margin: EdgeInsets.only(left: 0.0, top: 8.0, bottom: 8.0),
            )
                : Container()
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        margin: EdgeInsets.only(bottom: 10.0),
      );
    }
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

  Future<bool> onBackPress() {
    if (isShowSticker) {
      setState(() {
        isShowSticker = false;
      });
    } else {
//      Firestore.instance.collection('users').document(id).updateData({'chattingWith': null});
//      Navigator.pop(context);
    }

    return Future.value(false);
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (
                          context) =>
                          SettingProfileFirebaseScreen(
                            type: 2,
                            id: peerId,
                            groupChatId: groupChatId,
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
                    imageUrl: peerAvatar,
                    width: 35.0,
                    height: 35.0,
                    fit: BoxFit.cover
                ),
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
                clipBehavior: Clip.hardEdge,
              ),
              SizedBox(
                width: 12.0,
              ),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('${peerName}',style: TextStyle(color:Colors.white),maxLines: 1,overflow: TextOverflow.ellipsis,),
                    Text('$status',style: TextStyle(color:Colors.white,fontSize: 11.0),maxLines: 1,overflow: TextOverflow.ellipsis,)
                  ],
                ),
              )
            ],

          ),
          titleSpacing: 0.0,
        ),
        body: Container(
          color: Colors.grey[200],
          child:Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  // List of messages
                  buildListMessage(),
                  // Sticker
                  (isShowSticker ? buildSticker() : Container()),
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
  } // end Widget Build

  Widget _isOnline(BuildContext context, String peerId){
    print('$TAG check isOnline: ${peerId}');
    return new StreamBuilder(
        stream: Firestore.instance
            .collection('user')
            .where('id', isEqualTo:peerId)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            print('$TAG data ${snapshot.data.toString()}');
            return ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                itemCount: snapshot.data.documents.length,
                itemBuilder: (context ,int index){
                  return Text('${snapshot.data.documents[index]["inRoom"]}',
                    style: TextStyle(color: Colors.black38),
                    maxLines: 1,
                  );
                }
            );
          }
        }
    );
  }

  Widget buildSticker() {
    return Container(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi1', 2),
                child: new Image.asset(
                  'images/mimi1.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi2', 2),
                child: new Image.asset(
                  'images/mimi2.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi3', 2),
                child: new Image.asset(
                  'images/mimi3.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi4', 2),
                child: new Image.asset(
                  'images/mimi4.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi5', 2),
                child: new Image.asset(
                  'images/mimi5.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi6', 2),
                child: new Image.asset(
                  'images/mimi6.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi7', 2),
                child: new Image.asset(
                  'images/mimi7.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi8', 2),
                child: new Image.asset(
                  'images/mimi8.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi9', 2),
                child: new Image.asset(
                  'images/mimi9.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          )
        ],
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      ),
      decoration: new BoxDecoration(
          border: new Border(top: new BorderSide(color: Colors.grey, width: 0.5)), color: Colors.white),
      padding: EdgeInsets.all(5.0),
      height: 180.0,
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
//                      Location send
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
/**/
          // Edit text
          Flexible(
            child: Container(
              child: TextField(
                style: TextStyle(color: Colors.black87, fontSize: 15.0,height: 2.0,),
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
                color: Colors.green,
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

  Widget buildListMessage() {
    return Flexible(
      child: groupChatId == ''
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.red)))
          : StreamBuilder(
        stream: Firestore.instance
            .collection('messages')
            .document(groupChatId)
            .collection(groupChatId)
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

}
