import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taalk/views/room/DetailsViewLikeStoriesScreen.dart';
import 'package:taalk/views/room/DiscussHomeScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:taalk/helpers/GlobalVariable.dart' as globals;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'dart:convert' show Encoding, json;
import 'package:http/http.dart' as http;

class DetailStoriesFirebaseScreen extends StatefulWidget {
//  String type = "0";
  String idStory = "";

  DetailStoriesFirebaseScreen({
//    this.type,
    this.idStory,
  });

  @override
  _DetailStoriesFirebaseScreenState createState() => _DetailStoriesFirebaseScreenState();
}

class _DetailStoriesFirebaseScreenState extends State<DetailStoriesFirebaseScreen> {
  String TAG = 'Discuss DetailStoriesFirebaseScreen';

  double _panelHeightOpen = 270.0;
  double _panelHeightClosed = 47.0;

  String timeId = DateTime.now().millisecondsSinceEpoch.toString();

  SharedPreferences prefs;

  int _pageSlider = 0;
  double count;
  double val = 1.0;
  String id;
  String yourName;
  String myPhotoUrl = "";
  String myToken = "";
  Color _colorPrimary = Color(0xFF4aacf2);

  bool isLoading = true;

  String idUser = "";
  String contentBodyStory = "";
  String contentCaptionStory = "";
  String photoUrl = "";
  String nickname = "";
  String pushToken = "";
  List listContentImageStory = new List();
  List<dynamic> listViewers = new List<dynamic>();
  List<dynamic> listLikers = new List<dynamic>();
  List<dynamic> listDislikers = new List<dynamic>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getPref();
  }

  @override
  void dispose() {
    super.dispose();
  }

  _getPref() async {
    prefs = await SharedPreferences.getInstance();
    if (prefs.getString(globals.keyPrefColorPrimaryAttendance) != null ||
        prefs.getString(globals.keyPrefColorPrimaryAttendance) == "") {
      String colorPrimary =
      prefs.getString(globals.keyPrefColorPrimaryAttendance);
      print("$TAG pref string color: $colorPrimary");
      String valueString = colorPrimary.split('(0x')[1].split(')')[0];
      int value = int.parse(valueString, radix: 16);
      setState(() {
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
    print('$TAG Story Id: ${widget.idStory}');
    print('$TAG Your Name: ${yourName}');
    _fetchingStory();
  }

  _fetchingStory(){
    print("$TAG _fetchingStory");
    Firestore.instance.collection('stories').snapshots().forEach((value) {
      for(int i=0; i<value.documents.length;i++){
        if(value.documents[i]['idStory'].toString().contains(widget.idStory)){
          print("$TAG // ${value.documents[i]['idStory'].toString()}");
          print("$TAG /// ${widget.idStory}");
          if(mounted){
            setState(() {
              idUser = value.documents[i]['idUser'];
              contentBodyStory = value.documents[i]['contentBodyStory'];
              contentCaptionStory = value.documents[i]['contentCaptionStory'];
              photoUrl = value.documents[i]['photoUrl'];
              nickname = value.documents[i]['nickname'];
              pushToken = value.documents[i]['pushToken'];
              listContentImageStory = value.documents[i]['contentImageStory'];
              listViewers = value.documents[i]['viewerStory'];
              listLikers = value.documents[i]['likerStory'];
              listDislikers = value.documents[i]['disLikerStory'];
              isLoading = false;
              count = listContentImageStory.length.toDouble();
            });
          }
        }
      }
    }).whenComplete((){
      _updateViewers();
    });
  }

  _updateViewers() async {
    prefs = await SharedPreferences.getInstance();
    if(idUser != prefs.getString(globals.keyPrefFirebaseUserId)){
      Firestore.instance.collection('stories')
          .document(widget.idStory)
          .updateData(
          {
            'viewerStory': (FieldValue.arrayUnion([prefs.getString(globals.keyPrefFirebaseName)])),
            'viewerPhotoStory': (FieldValue.arrayUnion([prefs.getString(globals.keyPrefFirebasePhotoUrl)])),
          }).whenComplete((){
            print("$TAG OK READ");
      });
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
        child: SlidingUpPanel(
          maxHeight: _panelHeightOpen,
          minHeight: _panelHeightClosed,
          color: Colors.transparent,
          panel: Container(
            height: 200.0,
            decoration: BoxDecoration(
                borderRadius: new BorderRadius
                    .only(
                    topLeft: const Radius
                        .circular(40.0),
                    topRight: const Radius
                        .circular(40.0)),
                color: Colors.white
            ),
            padding: EdgeInsets.only(top: 20.0,left: 12.0,right: 12.0,bottom: 10.0),
            child: Stack(
              children: <Widget>[
                Align(
                  alignment: Alignment.topCenter,
                  child: Column(
                    children: <Widget>[
                      //  button like or dislike
                      Container(
                        height: 50.0,
                        child: Padding(
                          padding: EdgeInsets.only(top: 0.0,
                              bottom: 6.0,
                              left: 8.0,
                              right: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              //  like
                              id == idUser ? Container()
                                  :ButtonTheme(
                                minWidth: 80.0,
                                height: 40.0,
                                child: FlatButton(
                                    shape: new RoundedRectangleBorder(
                                        borderRadius: new BorderRadius.circular(15.0),
                                        side: BorderSide(color: Colors.green)
                                    ),
                                    color: Colors.transparent,
                                    textColor: Colors.green,
                                    padding: EdgeInsets.all(8.0),
                                    onPressed: () {
                                      // liked
                                      updateLikerOrDisliker(1);
                                    },
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget>[
                                          Text(
                                            "Like ",
                                            style: TextStyle(
                                              fontSize: 14.0,
                                            ),
                                          ),
                                          Icon(
                                            Icons.thumb_up,
                                            size: 20.0,
                                            color: Colors.green,
                                          ),
                                        ],
                                      ),
                                    )
                                ),
                              ),
                              SizedBox(
                                width: 10.0,
                              ),
                              //  disliker
                              id == idUser ? Container()
                                  : ButtonTheme(
                                minWidth: 80.0,
                                height: 40.0,
                                child: FlatButton(
                                    shape: new RoundedRectangleBorder(
                                        borderRadius: new BorderRadius.circular(15.0),
                                        side: BorderSide(color: Colors.red)
                                    ),
                                    color: Colors.transparent,
                                    textColor: Colors.red,
                                    padding: EdgeInsets.all(8.0),
                                    onPressed: () {
                                      // disliker
                                      updateLikerOrDisliker(0);
                                    },
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget>[
                                          Text(
                                            "Dislike ",
                                            style: TextStyle(
                                              fontSize: 14.0,
                                            ),
                                          ),
                                          Icon(
                                            Icons.thumb_down,
                                            size: 20.0,
                                            color: Colors.red,
                                          ),
                                        ],
                                      ),
                                    )
                                ),
                              ),
                              SizedBox(
                                width: 10.0,
                              ),
                              _showOwner(),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 8.0,
                      ),
                      // caption
                      SingleChildScrollView(
                        child: Material(
                          child: Column(
                            children: <Widget>[
                              Linkify(
                                onOpen: (link){
                                  // copyLink
                                },
                                humanize: true,
                                text: contentCaptionStory,
                                style: TextStyle(fontSize: 16.0,color:Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          collapsed: Container(
            height: 20.0,
            decoration: BoxDecoration(
                color: _colorPrimary,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0))
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(10.0, 8.0, 10.0, 8.0),
              child: Stack(
                children: <Widget>[
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Material(
                        child: Text("Swipe up",
                          style: TextStyle(
                              fontSize: 11.0, color: Colors.white),),
                      )
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.arrow_upward,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: isLoading == false ? Container(
              color: Colors.black,
              child: Stack(
                children: <Widget>[
                  CarouselSlider(
                    height: double.infinity,
                    autoPlay: true,
                    enableInfiniteScroll: false,
                    reverse: false,
                    enlargeCenterPage: false,
                    aspectRatio: 16 / 9,
                    viewportFraction: 0.8,
                    scrollDirection: Axis.vertical,
                    onPageChanged: (index){
                      _pageIndex(index);
                    },
                    autoPlayInterval: Duration(seconds: 5),
                    items: listContentImageStory.length != null ? listContentImageStory.map((i) {
                      return Builder(
                        builder: (BuildContext context) {
                          return Material(
                            child: Container(
//                              padding: EdgeInsets.only(top: 20.0, bottom: 10.0),
                              width: double.infinity,
                              margin: EdgeInsets.symmetric(horizontal: 1.2),
                              decoration: BoxDecoration(
                                  color: Colors.black
                              ),
                              child: Container(
                                color: Colors.transparent,
                                width: double.infinity,
                                child: Padding(
                                    padding: EdgeInsets.only(
                                        top: 0.0, bottom: 0.0, left: 0.0, right: 0.0),
                                    child: Stack(
                                      children: <Widget>[
                                        Align(
                                          alignment: Alignment.center,
                                          child: Container(
                                            height: double.infinity,
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                image: CachedNetworkImageProvider(
                                                  '${i}',
                                                ),
                                                fit: BoxFit.contain,
                                              ),
                                              borderRadius: BorderRadius.circular(10.0),
                                              boxShadow: [],
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }).toList()
                        : Container(),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 0.0,left: 0.0),
                      child: Column(
                        children: <Widget>[
                          Material(
                            color: Colors.transparent,
                            child: Slider(
                              onChanged: (value){

                              },
                              value: val,
                              label: '$val',
                              max: count,
                              inactiveColor: Colors.white,
                              activeColor: Colors.green,
                            ),
                          ),
                          Container(
                            width: 200.0,
                            decoration: BoxDecoration(
                                color: Colors.white,
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Material(
                                    child: CachedNetworkImage(
                                        imageUrl: '${photoUrl}',
                                        width: 30.0,
                                        height: 30.0,
                                        fit: BoxFit.fill
                                    ),
                                    borderRadius: BorderRadius
                                        .all(
                                        Radius.circular(25.0)),
                                    clipBehavior: Clip.hardEdge,
                                  ),
                                  SizedBox(
                                    width: 10.0,
                                  ),
                                  Material(
                                    child: Text('${nickname}',
                                      style: TextStyle(
                                          fontSize: 15.0,
                                          color: Colors.black54,
                                          fontWeight: FontWeight
                                              .bold),
                                      overflow: TextOverflow.fade,
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
                ],
              )
          ):Container(child: Center(child:CircularProgressIndicator(
            backgroundColor: Colors.red,
          ))),
        )
    );
  }

  updateLikerOrDisliker(int type) async {
    _updateViewers();
    //  1 = liker, 0 = disliker
    prefs = await SharedPreferences.getInstance();
    if(type==1){
      Firestore.instance.collection('stories')
          .document(widget.idStory)
          .updateData(
          {
            'likerStory': (FieldValue.arrayUnion([prefs.getString(globals.keyPrefFirebaseName)])),
            'likerPhotoStory': (FieldValue.arrayUnion([prefs.getString(globals.keyPrefFirebasePhotoUrl)]))
          }).whenComplete((){
              Firestore.instance.collection('stories')
                  .document(widget.idStory)
                  .updateData(
                  {
                    'disLikerStory': (FieldValue.arrayRemove([prefs.getString(globals.keyPrefFirebaseName)])),
                    'disLikerPhotoStory': (FieldValue.arrayRemove([prefs.getString(globals.keyPrefFirebasePhotoUrl)])),
                  }).then((value){
              });
      });

      //                    Notification add
      Firestore.instance.collection('notifications')
          .document("type2-"+timeId+widget.idStory)
          .setData(
          {
            'notifId': "type2-"+timeId+widget.idStory,
            'idStory': widget.idStory,
            'idTo': idUser,
            'contentCaptionStory': contentCaptionStory,
            'photoUrlUser': photoUrl,
            'nameTo': nickname,
            'pushTokenUser': pushToken,
            'text': "${prefs.getString(globals.keyPrefFirebaseName)} liked your story",
            'isRead': false,
//            contentImageStory: document['contentImageStory'],
//            listViewers: document['viewerStory'],
//            listLikers: document['likerStory'],
//            listDislikers: document['disLikerStory'],
            'time': timeId,
            'nameFrom': prefs.getString(globals.keyPrefFirebaseName),
            'idFrom': prefs.getString(globals.keyPrefFirebaseUserId),
            'myPhoto': prefs.getString(globals.keyPrefFirebasePhotoUrl),
            'type': "2",
            'tag': "Liked"
          });
      Fluttertoast.showToast(msg: "You just Liked",backgroundColor: Colors.green, textColor: Colors.white);
    }

    if(type==0){
      Firestore.instance.collection('stories')
          .document(widget.idStory)
          .updateData(
          {
            'disLikerStory': (FieldValue.arrayUnion([prefs.getString(globals.keyPrefFirebaseName)])),
            'disLikerPhotoStory': (FieldValue.arrayUnion([prefs.getString(globals.keyPrefFirebasePhotoUrl)])),
          }).whenComplete((){
        Firestore.instance.collection('stories')
            .document(widget.idStory)
            .updateData(
            {
              'likerStory': (FieldValue.arrayRemove([prefs.getString(globals.keyPrefFirebaseName)])),
              'likerPhotoStory': (FieldValue.arrayRemove([prefs.getString(globals.keyPrefFirebasePhotoUrl)])),
            }).then((value){
        }).then((onError){
          print('$TAG likerStory: ${onError.toString()}');
        });
      });

      //                    Notification add
      Firestore.instance.collection('notifications')
          .document("type2-"+timeId+widget.idStory)
          .setData(
          {
            'notifId': "type2-"+timeId+widget.idStory,
            'idStory': widget.idStory,
            'idTo': idUser,
            'contentCaptionStory': contentCaptionStory,
            'photoUrlUser': photoUrl,
            'nameTo': nickname,
            'pushTokenUser': pushToken,
            'text': "${yourName} disliked your story",
            'isRead': false,
//            contentImageStory: document['contentImageStory'],
//            listViewers: document['viewerStory'],
//            listLikers: document['likerStory'],
//            listDislikers: document['disLikerStory'],
            'time': timeId,
            'nameFrom': yourName,
            'idFrom': id,
            'myPhoto': myPhotoUrl,
            'type': "2",
            'tag': "Disliked"
          });
      Fluttertoast.showToast(msg: "You just Disliked",backgroundColor: Colors.red, textColor: Colors.white);
    }

    _sendNotif(type);
  }

  _sendNotif(int type) async {
    final postUrl = 'https://fcm.googleapis.com/fcm/send';
    String body;
    if(type==1){
      body = "${yourName} just liked your stories";
    }
    if(type==0){
      body = "${yourName} just disliked your stories";
    }
    var data = {
      "notification": {"body": "${body}", "title": "Discuss Story"},
      "priority": "high",
      "data": {
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "id": "1",
        "status": "done"
      },
      "to": "${pushToken}"
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

  _showOwner(){
    print('$TAG compare: ${idUser} to ${id}');
    print('$TAG length 1: ${idUser.length} - ${idUser.length}');
//    print('$TAG length 2: ${id.length} - ${id}');
    if(id == idUser){
      return ButtonTheme(
        minWidth: 80.0,
        height: 40.0,
        child: FlatButton(
            shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(15.0),
                side: BorderSide(color: Colors.blueAccent)
            ),
            color: Colors.transparent,
            textColor: Colors.blueAccent,
            padding: EdgeInsets.all(8.0),
            onPressed: () {
              Navigator.push(
                  context,
                  new MaterialPageRoute(
                      builder: (BuildContext context) =>
                          DetailsViewLikeStoriesScreen(
                            idStory: widget.idStory
                              /*listViewer_: listViewers,
                              listLikers_: listLikers,
                              listDislikers_: listDislikers*/
                          )));
            },
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Details ",
                    style: TextStyle(
                      fontSize: 14.0,
                    ),
                  ),
                  Icon(
                    Icons.info_outline,
                    size: 20.0,
                    color: Colors.blueAccent,
                  ),
                ],
              ),
            )
        ),
      );
    }else{
      return Container();
    }
  }

  _pageIndex(int index){
    print('$TAG index: ${index}');
    if(index==0){
      setState(() {
        val = 1.0;
      });
    }else{
      setState(() {
        val = val + 1.0;
      });
    }
  }

}
