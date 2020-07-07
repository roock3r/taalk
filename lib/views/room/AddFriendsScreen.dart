import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taalk/views/room/DiscussHomeScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taalk/helpers/GlobalVariable.dart' as globals;
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

class AddFriendsScreen extends StatefulWidget {
  @override
  _AddFriendsScreenState createState() => _AddFriendsScreenState();
}

class _AddFriendsScreenState extends State<AddFriendsScreen> {
  String TAG = "AddFriendsScreen ";

  TextEditingController _textFieldControllerContactForward = TextEditingController();
  String filter = null;
  SharedPreferences prefs;
  String id="";
  String yourName="";

  double heightDrawer = 0.0;

  bool isLoading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print('$TAG initState Running...');
    readLocal();
    Timer(const Duration(milliseconds: 200), () {
      print("$TAG show header drawer");
      setState(() {
        heightDrawer = 70.0;
      });
    });
  }

  readLocal() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      id = prefs.getString(globals.keyPrefFirebaseUserId) ?? '';
      yourName = prefs.getString(globals.keyPrefFirebaseName) ?? '';
    });
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
        body: Container(
          color: Colors.white,
          child: Stack(
            children: <Widget>[
              // List
              Container(
                color: Colors.grey[50],
                child: StreamBuilder(
                  stream: Firestore.instance.collection('users_')
                      .orderBy('nickname',descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      );
                    }
                    else {
                      return ListView.builder(
                        padding: EdgeInsets.only(top: 145.0),
                        itemBuilder:(context, index) => buildItem(context, snapshot.data.documents[index]),
                        itemCount: snapshot.data.documents.length,
                      );
                    }
                  },
                ),
              ),
              //  search
              Padding(
                padding: EdgeInsets.only(top: 30.0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 120.0,
                    color: Colors.transparent,
                    child: Column(
                      children: <Widget>[
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: EdgeInsets.only(top:10.0,bottom: 10.0,right: 10.0,left: 18.0),
                            child: Text('Add Friends',style: TextStyle(fontSize: 25.0,fontWeight: FontWeight.bold),),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(top: 0.0,left: 8.0,right: 8.0),
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
                                        controller: _textFieldControllerContactForward,
                                        onChanged: (text){
                                          _setFilter(text);
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
                                    icon: Icon(
                                        Icons.close,
                                        color:Colors.red
                                    ),
                                    onPressed: () {
//                                      _setFilter(_textFieldControllerContactForward.text.toString());
                                      setState(() {
                                        filter = null;
                                        _textFieldControllerContactForward.text = "";
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
              ),
              //  loading
              isLoading == true ? Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.2),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                ),
              )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }// End Widget build

  Widget buildItem(BuildContext context, DocumentSnapshot document) {
//    if(filter!=""){
      if(filter != null){
        if(document.data['nickname'].toString().contains(filter)){
          print('$TAG filter BY -> : ${filter}');
          print('$TAG result filter - > ${document.data['nickname']}');
          print('$TAG ${document['id']} == ${id}');
          if (document['id'] == id) {
            print('$TAG null');
            return Container();
          }
          else {
            print('$TAG show');
            return Container(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(top: 10.0,bottom: 10.0),
                    child: Material(
                      child: ListTile(
                        leading: Material(
                          child: document['photoUrl'] != null ?
                          Stack(
                            children: <Widget>[
                              Material(
                                child: CachedNetworkImage(
                                  placeholder: (context, url) => Container(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.0,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
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
                            ],
                          )
                              : Icon(
                            Icons.account_circle,
                            size: 50.0,
                            color: Colors.black54,
                          ),
                        ),
                        title: Container(
                          child: Text('${document['nickname']}',
                            style: TextStyle(color: Colors.black,fontSize: 15.0),
                          ),
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                        ),
                        trailing: Container(
                          width: 80.0,
                          height: 34,
                          child: ButtonTheme(
                            minWidth: 40.0,
                            height: 16.0,
                            child: FlatButton(
                                shape: new RoundedRectangleBorder(
                                    borderRadius: new BorderRadius.circular(10.0),
                                    side: BorderSide(color: Colors.green)
                                ),
                                color: Colors.white,
                                textColor: Colors.green,
                                padding: EdgeInsets.all(8.0),
                                onPressed: () {
                                  _saveToRequestFriends(document['id'],document['nickname'],document['pushToken']);
                                },
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        "Add ",
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
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
              margin: EdgeInsets.only(bottom: 0.9, left: 0.0, right: 0.0),
            );
          }
        }
      }
      if(filter==""||filter==null){
        return Container();
      }
//    }
  }

  _setFilter(String text){
    print('$TAG by: $text');
    print('$TAG length: ${text.length}');
    if(text.length==0){
      setState(() {
        filter = null;
      });
    }
    if(text.length>0){
      setState(() {
        filter = text;
      });
    }
  }

  _saveToRequestFriends(String peerId, String peerName, String token) async{
    setState(() {
      isLoading = true;
    });
    String requestIdTo = peerId+'-'+id;
    String requestIdFrom = id+'-'+peerId;
    //  check if request has data
    final QuerySnapshot result = await Firestore.instance.collection('request_friends')
        .where('requestIdTo', isEqualTo: requestIdTo)
        .getDocuments();
    final List<DocumentSnapshot> documents = result.documents;

    final QuerySnapshot result2 = await Firestore.instance.collection('request_friends')
        .where('requestIdFrom', isEqualTo: requestIdFrom)
        .getDocuments();
    final List<DocumentSnapshot> documents2 = result2.documents;

    print('$TAG where requestIdTo : ${requestIdFrom}');
    print('$TAG where requestIdFrom: ${requestIdTo}');

    if(documents.length == 0 && documents2.length == 0){
      print('$TAG Friends added to request');
      final QuerySnapshot resultFriends = await Firestore.instance.collection('users_')
          .document(id)
          .collection('my_friends')
          .where('id', isEqualTo: peerId)
          .getDocuments();
      final List<DocumentSnapshot> documentsFriends = resultFriends.documents;
      if(documentsFriends.length == 0){
        Firestore.instance.collection('request_friends').document(peerId)
            .setData({
          'requestIdTo': requestIdFrom,
          'requestIdFrom': requestIdTo,
          'userIdFrom': id,
          'userNameFrom': yourName,
          'userIdTo': peerId,
          'userNameTo': peerName,
        });
        _showDialog(1,"Friends success to add, waiting for accept");
        _sendPushNotif(token);
        setState(() {
          isLoading = false;
        });
      }
      else{
        print('$TAG Already to be friends');
        _showDialog(0,"Already to be friends");
        setState(() {
          isLoading = false;
        });
      }
    }
    else{
      print('$TAG Friends has been add, waiting to accept');
      _showDialog(0,"Friends has been add, waiting to accept");
      setState(() {
        isLoading = false;
      });
    }

  }

  _sendPushNotif(String token) async {
    print('FCM from Flutter');
    final postUrl = 'https://fcm.googleapis.com/fcm/send';
    final data = {
      "notification": {"body": "${yourName}, just added you to be friends", "title": "New friends request"},
      "priority": "high",
      "data": {
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "id": "1",
        "status": "done"
      },
      "to": "${token}"
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

  _showDialog(int type ,String msg){
    showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) -   1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: AlertDialog(
                shape: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                title: Text('Information'),
                content: Text('${msg}',style: TextStyle(color: type==1?Colors.green:Colors.red),),
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

  _showListFriends(){

  }

}// End Class
