import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taalk/views/room/ChatGroupScreen.dart';
import 'package:taalk/views/room/DetailStoriesFirebaseScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taalk/helpers/GlobalVariable.dart' as globals;

class NotificationRoomScreen extends StatefulWidget {
  @override
  _NotificationRoomScreenState createState() => _NotificationRoomScreenState();
}

class _NotificationRoomScreenState extends State<NotificationRoomScreen> {
  String TAG = "NotificationRoomScreen ";

  String id = "";
  String photoUrl = "";
  String yourName = "";

  double heightDrawer = 0.0;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print("$TAG initState running...");
    getPref();
  }

  getPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      photoUrl = prefs.getString(globals.keyPrefFirebasePhotoUrl);
      yourName = prefs.getString(globals.keyPrefFirebaseName);
      id = prefs.getString(globals.keyPrefFirebaseUserId) ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        child: Stack(
          children: <Widget>[
//            body
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: EdgeInsets.only(top: 80.0),
                color: Colors.white,
                child: StreamBuilder(
                  stream: Firestore.instance.collection('notifications')
                      .orderBy('time', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: Text("Connecting ..."),
                      );
                    }
                    else {
                      return ListView.builder(
                        padding: EdgeInsets.only(top: 10.0),
                        itemBuilder:(context, index) => buildItem(context, snapshot.data.documents[index]),
                        itemCount: snapshot.data.documents.length,
                      );
                    }
                  },
                ),
              ),
            ),
//            header
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.only(top: 40.0,left: 15.0),
                child: Text("Notifications",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25.0),),
              ),

            ),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(top: 30.0,right: 12.0),
                child: IconButton(
                  iconSize: 32.0,
                  icon: Icon(Icons.info_outline),
                  color: Colors.blue,
                  onPressed: (){
                    showInformation();
                  },
                )
              ),

            ),
          ],
        ),
      ),
    );
  }// End Widget build

  Widget buildItem(BuildContext context, DocumentSnapshot document) {
    print("$TAG documentID: ${document.documentID}");
    print("$TAG notifId: ${document.data['notifId']}");
    print("$TAG time: ${document.data['time']}");
    var date = new DateTime.fromMillisecondsSinceEpoch(int.parse(document.data['time']));
    DateTime dateTimeNow = DateTime.now();
    print("$TAG DateNow ------------ ${dateTimeNow}");
    final differenceInDays = dateTimeNow.difference(date).inDays;
    print("$TAG Dif: ${differenceInDays}");
//    check if diferent in 1 days or 24hours
    if(differenceInDays>=1){
      Firestore.instance.collection('notifications').document(document.documentID).delete();
    }

    if(document.data['idTo'].toString().contains(id))
    {
//      For group
      if(document.data['type']=="1"){
        return AnimationConfiguration.staggeredList(
            position: 1,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
                child: ScaleAnimation(
                    child: Container(
                      child: Column(
                        children: <Widget>[
                          FlatButton(
                            child: Row(
                              children: <Widget>[
                                Material(
                                  child: document['groupPhoto'] != null ?
                                  Stack(
                                    children: <Widget>[
                                      Material(
                                        child: CachedNetworkImage(
                                          placeholder: (context, url) => Container(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.0,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                            ),
                                            width: 50.0,
                                            height: 50.0,
                                            padding: EdgeInsets.all(15.0),
                                          ),
                                          imageUrl: document['groupPhoto'],
                                          width: 50.0,
                                          height: 50.0,
                                          fit: BoxFit.cover,
                                        ),
                                        borderRadius: BorderRadius.all(Radius.circular(26.0)),
                                        clipBehavior: Clip.hardEdge,
                                      ),
                                      Positioned(
                                        bottom: 0.0,
                                        right: 0.0,
                                        child: Image.asset(document['tag'] == "Add" ? "assets/images/ic_notif_add_group.png":
                                            "assets/images/ic_notif_delete_group.png",width: 20.0,height: 20.0,),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
//                                        title
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text('${document['groupName']}',
                                            style: document['isRead'] == false ? TextStyle(color: Colors.black,fontSize: 15.0)
                                                : TextStyle(color: Colors.black38,fontSize: 15.0),
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 3.0,
                                        ),
//                                        body
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text('${document['text']}',
                                            style: document['isRead'] == false ? TextStyle(color: Colors.black,fontSize: 14.0)
                                                : TextStyle(color: Colors.black38,fontSize: 16.0),
                                            textAlign: TextAlign.left,
                                          ),
//                                          alignment: Alignment.centerLeft,
//                                          margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 3.0),
                                        ),
                                        SizedBox(
                                          height: 3.0,
                                        ),
//                                        time
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            DateFormat('kk:mm - dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(int.parse(document['time']))),
                                            style: TextStyle(color: Colors.black38, fontSize: 12.0, fontStyle: FontStyle.italic),
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                      ],
                                    ),
                                    margin: EdgeInsets.only(left: 20.0),
                                  ),
                                ),
                              ],
                            ),
                            onPressed: () async {
                              Firestore.instance.collection('groups').document(document['groupId'])
                                  .snapshots().forEach((element) {
                                if(element.data == null){
                                  Fluttertoast.showToast(msg: "This group unavailable",backgroundColor: Colors.amber, textColor: Colors.white);
                                }
                                else{
                                  if(document['tag'] == "Add"){
                                    // Check is still member group
                                    Firestore.instance.collection('groups').getDocuments().then((value) {
                                      var _list = value.documents;
                                      for(int i=0;i<_list.length;i++){
                                        if(_list[i]['groupId']==document['groupId']){
                                          print("$TAG _list${_list[i]['groupId']} == $id");
                                          if(_list[i]['member'].contains(id)){
                                            print("$TAG _list${_list[i]['groupId']} ");
                                            print("$TAG _member${_list[i]['member'].toString()}");
                                            print("$TAG member");
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) => ChatGroupScreen(
                                                      groupId: document.data['groupId'],
                                                      groupName: document.data['groupName'],
                                                      photoGroup: document.data['groupPhoto'],
                                                    )));
                                          }else{
                                            print("$TAG not member");
                                            Fluttertoast.showToast(msg: "You are not member",backgroundColor: Colors.amber, textColor: Colors.white);
                                          }
                                        }
                                      }
                                    });
                                    Firestore.instance.collection('notifications').document(document['notifId'])
                                        .updateData({'isRead': true});
                                  }
                                  else{
                                    Firestore.instance.collection('notifications').document(document['notifId'])
                                        .updateData({'isRead': true});
                                    Fluttertoast.showToast(msg: "You was delete from this group",backgroundColor: Colors.red, textColor: Colors.white);
                                  }
                                }
                              });
                            },
                            color: Colors.white,
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
                    )
                )
            )
        );
      }
//      For story
      else if(document.data['type']=="2"){
        return AnimationConfiguration.staggeredList(
            position: 1,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
                child: ScaleAnimation(
                    child: Container(
                      child: Column(
                        children: <Widget>[
                          FlatButton(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Material(
                                  child: document['myPhoto'] != null ?
                                  Stack(
                                    children: <Widget>[
                                      Material(
                                        child: CachedNetworkImage(
                                          placeholder: (context, url) => Container(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.0,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                            ),
                                            width: 50.0,
                                            height: 50.0,
                                            padding: EdgeInsets.all(15.0),
                                          ),
                                          imageUrl: document['myPhoto'],
                                          width: 50.0,
                                          height: 50.0,
                                          fit: BoxFit.cover,
                                        ),
                                        borderRadius: BorderRadius.all(Radius.circular(26.0)),
                                        clipBehavior: Clip.hardEdge,
                                      ),
                                      Positioned(
                                        bottom: 0.0,
                                        right: 0.0,
                                        child: Image.asset("assets/images/ic_notif_story.png",width: 20.0,height: 20.0,),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
//                                        title
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text('${document['nameFrom']}',
                                            style: document['isRead'] == false ? TextStyle(color: Colors.black,fontSize: 15.0)
                                                : TextStyle(color: Colors.black38,fontSize: 15.0),
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 3.0,
                                        ),
//                                        body
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text('${document['text']}',
                                            style: document['isRead'] == false ? TextStyle(color: Colors.black,fontSize: 14.0)
                                                : TextStyle(color: Colors.black38,fontSize: 14.0),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text('${document['contentCaptionStory']}',
                                            style: TextStyle(color: Colors.black38,fontSize: 14.0),
                                            maxLines: 4,
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 3.0,
                                        ),
//                                        time
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            DateFormat('kk:mm - dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(int.parse(document['time']))),
                                            style: TextStyle(color: Colors.black38, fontSize: 12.0, fontStyle: FontStyle.italic),
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                      ],
                                    ),
                                    margin: EdgeInsets.only(left: 20.0),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Image.asset(document['tag'] == "Liked" ? "assets/images/ic_like_green.png":
                                  "assets/images/ic_dislike_red.png"
                                    ,height: 22.0,width: 22.0,),
                                ),
                              ],
                            ),
                            onPressed: () {
                              Firestore.instance.collection('notifications').document(document['notifId'])
                                  .updateData({'isRead': true});
                              print("$TAG iDStory: ${document['idStory']}");
                              Firestore.instance.collection('stories').document(document['idStory'])
                              .snapshots().forEach((element) {
                                if(element.data == null){
                                  Fluttertoast.showToast(msg: "This story unavailable",backgroundColor: Colors.amber, textColor: Colors.white);
                                }else{
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              DetailStoriesFirebaseScreen(
                                                idStory: document['idStory'],
                                              )));
                                }
                              });
                            },
                            color: Colors.white,
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
                    )
                )
            )
        );
      }
//      For Delete friend
      else if(document.data['type']=="4"){
        return AnimationConfiguration.staggeredList(
            position: 1,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
                child: ScaleAnimation(
                    child: Container(
                      child: Column(
                        children: <Widget>[
                          FlatButton(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Material(
                                  child: document['photoUrlUser'] != null ?
                                  Stack(
                                    children: <Widget>[
                                      Material(
                                        child: CachedNetworkImage(
                                          placeholder: (context, url) => Container(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.0,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                            ),
                                            width: 50.0,
                                            height: 50.0,
                                            padding: EdgeInsets.all(15.0),
                                          ),
                                          imageUrl: document['photoUrlUser'],
                                          width: 50.0,
                                          height: 50.0,
                                          fit: BoxFit.cover,
                                        ),
                                        borderRadius: BorderRadius.all(Radius.circular(26.0)),
                                        clipBehavior: Clip.hardEdge,
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
//                                        title
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text('${document['nameFrom']}',
                                            style: document['isRead'] == false ? TextStyle(color: Colors.black,fontSize: 15.0)
                                                : TextStyle(color: Colors.black38,fontSize: 15.0),
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 3.0,
                                        ),
//                                        body
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text('${document['text']}',
                                            style: document['isRead'] == false ? TextStyle(color: Colors.black,fontSize: 14.0)
                                                : TextStyle(color: Colors.black38,fontSize: 14.0),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text('${document['contentCaptionStory']}',
                                            style: TextStyle(color: Colors.black38,fontSize: 14.0),
                                            maxLines: 4,
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 3.0,
                                        ),
//                                        time
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            DateFormat('kk:mm - dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(int.parse(document['time']))),
                                            style: TextStyle(color: Colors.black38, fontSize: 12.0, fontStyle: FontStyle.italic),
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                      ],
                                    ),
                                    margin: EdgeInsets.only(left: 20.0),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Icon(
                                    Icons.remove_circle,
                                    size: 25.0,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            onPressed: () {
                              Firestore.instance.collection('notifications').document(document['notifId'])
                                  .updateData({'isRead': true});
                              print("$TAG check type notif: ${document['type']}");
                              if(document['isRead'] == false){
                                    Fluttertoast.showToast(msg: "This notification just tell you, no detail",backgroundColor: Colors.amber, textColor: Colors.white);
                              }
                            },
                            color: Colors.white,
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
                    )
                )
            )
        );
      }
      else{
        return Container();
      }
    }else{
      return Container();
    }
  }

  showInformation(){
    return showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        title: new Text('Information'),
        content: new Text('Notification will be delete permanently\nafter 24 hour or 1 day'),
        actions: <Widget>[
          new FlatButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: new Text('Close'),
          ),
        ],
      ),
    );
  }
}
