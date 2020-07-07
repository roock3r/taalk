import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taalk/models/ContactFirebaseModel.dart';
import 'package:flutter/material.dart';
import 'dart:convert' show Encoding, json;
import 'package:http/http.dart' as http;
import 'package:taalk/helpers/GlobalVariable.dart' as globals;
import 'package:shared_preferences/shared_preferences.dart';


class ForwardFriendScreen extends StatefulWidget {
  String content;
  int type;
  List<ContactFirebaseModel> listContactFirebaseModel;

  ForwardFriendScreen({Key key, @required this.type, @required this.content, @required this.listContactFirebaseModel}) : super(key: key);

  @override
  _ForwardFriendScreenState createState() => _ForwardFriendScreenState();
}

class _ForwardFriendScreenState extends State<ForwardFriendScreen> {
  String TAG = 'ForwardFriendScreen';

  Color _colorPrimary = Color(0xFF4aacf2);
  TextEditingController _textFieldControllerContactForward = TextEditingController();
  String filter = "";

  String id;
  String yourName;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print('$TAG initState Running...');
    _getPref();
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
    prefs = await SharedPreferences.getInstance();
    id = prefs.getString(globals.keyPrefFirebaseUserId) ?? '';
    yourName = prefs.getString(globals.keyPrefFirebaseName) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Stack(
          children: <Widget>[
            Container(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.only(top: 120.0),
                child: ListView.builder(
                    itemCount: widget.listContactFirebaseModel.length,
                    itemBuilder: (BuildContext context, int index) => buildItem(context,widget.listContactFirebaseModel[index])),
              ),
            ),
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
                          child: Text('Forward to ...',style: TextStyle(fontSize: 25.0,fontWeight: FontWeight.bold),),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 0.0,left: 8.0,right: 8.0),
                        color: Colors.transparent,
                        child: Card(
                          elevation: 3.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                          child: Container(
                            color: Colors.transparent,
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
                                      _textFieldControllerContactForward.clear();
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
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding:EdgeInsets.only(left: 8.0,right: 8.0,bottom: 8.0,top: 8.0),
                child: Container(
                  height: 50.0,
                  color: Colors.transparent,
                  child: Column(
                    children: <Widget>[
                      ButtonTheme(
                        minWidth: 480.0,
                        height: 40.0,
                        child: FlatButton(
                            shape: new RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(15.0),
                                side: BorderSide(color: Colors.green)
                            ),
                            color: Colors.white,
                            textColor: Colors.green,
                            padding: EdgeInsets.all(8.0),
                            onPressed: () {
                              _sendTo();
                              Navigator.of(context).pop();
                            },
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    "Send  ",
                                    style: TextStyle(
                                      fontSize: 14.0,
                                    ),
                                  ),
                                  Icon(
                                    Icons.send,
                                    size: 20.0,
                                    color: Colors.green,
                                  ),
                                ],
                              ),
                            )
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildItem(BuildContext context, ContactFirebaseModel listContactFirebaseModel, ){
    if(listContactFirebaseModel.getContactName.contains(filter)){
      print('$TAG filter BY -> : ${filter}');
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
                  imageUrl: listContactFirebaseModel.getContactPhoto,
                  width: 35.0,
                  height: 35.0,
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.all(
                    Radius.circular(26.0)),
                clipBehavior: Clip.hardEdge,
              ),
              title: Text(
                listContactFirebaseModel.contactName, style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold),),
              trailing: Checkbox(
                checkColor: Colors.white,
                activeColor: Colors.blue,
                value: listContactFirebaseModel.getIsChecked,
                onChanged: (bool val){
                  setState(() {
                    listContactFirebaseModel.setIsChecked = val;
                  });
                },
              ),
            ),
          ],
        ),
      );
    }
    if(filter == ""){
      print('$TAG filter NULL -> : ${filter}');
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
                  imageUrl: listContactFirebaseModel.getContactPhoto,
                  width: 35.0,
                  height: 35.0,
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.all(
                    Radius.circular(26.0)),
                clipBehavior: Clip.hardEdge,
              ),
              title: Text(
                listContactFirebaseModel.contactName, style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold),),
              trailing: Checkbox(
                checkColor: Colors.white,
                activeColor: Colors.blue,
                value: listContactFirebaseModel.getIsChecked,
                onChanged: (bool val){
                  setState(() {
                    listContactFirebaseModel.setIsChecked = val;
                  });
                },
              ),
            ),
          ],
        ),
      );
    }
  }

  void _sendTo()async{
    for(int i = 0; i<widget.listContactFirebaseModel.length;i++){
      print('$TAG IS: ${widget.listContactFirebaseModel[i].getIsChecked}');
      if(widget.listContactFirebaseModel[i].getIsChecked==true){
        String groupChatId;
        String peerId = widget.listContactFirebaseModel[i].getContactId;
        print('$TAG selected: ${widget.listContactFirebaseModel[i].getContactId}');

        Firestore.instance.collection('users_').document(peerId).collection('my_friends').document(id)
            .updateData({'contentTime': DateTime.now().toString()});

        Firestore.instance.collection('users_').document(id).collection('my_friends').document(peerId)
            .updateData({'contentTime': DateTime.now().toString()});

        Firestore.instance.collection('users_').document(peerId).collection('my_friends').document(id)
            .updateData({'isNewContent': true});

        if (id.hashCode <= peerId.hashCode) {
          groupChatId = '$id-$peerId';
          print('$TAG groupChatId[id-peerId]: ${groupChatId}');
        } else {
          groupChatId = '$peerId-$id';
          print('$TAG groupChatId[peerId-id]: ${groupChatId}');
        }
//        Firestore.instance.collection('users').document(id).updateData({'chattingWith': peerId});
        var _date = DateTime.now().toString();
        var documentReference = Firestore.instance
            .collection('messages')
            .document(groupChatId)
            .collection(groupChatId)
            .document(_date);

        Firestore.instance.runTransaction((transaction) async {
          await transaction.set(
            documentReference,
            {
              'idFrom': id,
              'forwardFrom': yourName,
              'isForward': true,
              'idTo': peerId,
              'isRead': false,
              'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
              'times': _date,
              'content': '${widget.content}',
              'type': widget.type
            },
          );
        });

        print('FCM from Flutter');
        final postUrl = 'https://fcm.googleapis.com/fcm/send';
        var data;
        if(widget.type==0){
          data = {
            "notification": {"body": "${widget.content}", "title": "${yourName}"},
            "priority": "high",
            "data": {
              "click_action": "FLUTTER_NOTIFICATION_CLICK",
              "id": "1",
              "status": "done"
            },
            "to": "${widget.listContactFirebaseModel[i].getContactToken}"
          };
        }
        if(widget.type==1){
          data = {
            "notification": {"body": "Image", "title": "${yourName}"},
            "priority": "high",
            "data": {
              "click_action": "FLUTTER_NOTIFICATION_CLICK",
              "id": "1",
              "status": "done"
            },
            "to": "${widget.listContactFirebaseModel[i].getContactToken}"
          };
        }
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

        Firestore.instance.collection('users_').document(peerId).collection('my_friends').document(id)
            .updateData({'contentTime': DateTime.now().toString()});
        Firestore.instance.collection('users_').document(peerId).collection('my_friends').document(id)
            .updateData({'isNewContent': true});

      }
    }
  }
}
