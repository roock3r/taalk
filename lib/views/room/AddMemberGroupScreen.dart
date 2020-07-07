import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taalk/models/ContactFirebaseModel.dart';
import 'package:taalk/views/room/DiscussHomeScreen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taalk/helpers/GlobalVariable.dart' as globals;
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';


class AddMemberGroupScreen extends StatefulWidget {
  String idGroup;
  List<String> listIdMember;
  String groupName;
  String photoUrl;

  AddMemberGroupScreen({this.idGroup,this.groupName,this.listIdMember,this.photoUrl});

  @override
  _AddMemberGroupScreenState createState() => _AddMemberGroupScreenState();
}

class _AddMemberGroupScreenState extends State<AddMemberGroupScreen> {
  String TAG = "AddMemberGroupScreen ";

  Color _colorPrimary = Color(0xFF4aacf2);
  TextEditingController _textFieldControllerContactForward = TextEditingController();
  String filter = "";

  bool isGetContact = true;


  List listMember = new List();
  List listMe = new List();
  String imageUrl = "";
  String id;
  String idGroup;
  String token;
  String yourName;
  String timeId = DateTime.now().millisecondsSinceEpoch.toString();
  bool isLoading = false;
  List<ContactFirebaseModel> listContactFirebaseModel = new List<ContactFirebaseModel>();
  int x;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print("$TAG idMember: ${widget.listIdMember.toString()}");
    _getPref();
    idGroup = widget.idGroup;
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
    setState(() {
      id = prefs.getString(globals.keyPrefFirebaseUserId) ?? '';
      yourName = prefs.getString(globals.keyPrefFirebaseName) ?? '';
      token = prefs.getString(globals.keyPrefTokenFirebase) ?? '';
    });
    print('$TAG - your id: ${id}');
    listMe.add(id);
    getContact();
  }

  getContact() async {
    QuerySnapshot querySnapshot = await Firestore.instance.collection("users_").document(id)
        .collection('my_friends').orderBy('nickname', descending: true)
        .getDocuments();
    var list = querySnapshot.documents;
    print('$TAG id: ${list.length}');
    for(var i = 0; i < list.length; i++){
      ContactFirebaseModel _contactFirebaseModel = new ContactFirebaseModel();
      _contactFirebaseModel.setContactId = list[i]['id'];
      _contactFirebaseModel.setContactName = list[i]['nickname'];
      _contactFirebaseModel.setContactPhoto = list[i]['photoUrl'];
      _contactFirebaseModel.setContactToken = list[i]['pushToken'];
      _contactFirebaseModel.setIsChecked = false;
      setState(() {
          listContactFirebaseModel.add(_contactFirebaseModel);
      });
      if(i==list.length-1 /*&& listIdMember.length==listContactFirebaseModel.length*/){
        setState(() {
          isGetContact = false;
        });
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
            ModalRoute.withName("/discusshome"));
      },
      child: Scaffold(
        body: Container(
          color: Colors.white,
          child: Stack(
            children: <Widget>[
              //  list contact
              Container(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.only(top: 150.0),
                  child: isGetContact == true ? Center(
                      child: CircularProgressIndicator(backgroundColor: Colors.red,)
                  ):ListView.builder(
                      itemCount: listContactFirebaseModel.length,
                      itemBuilder: (BuildContext context, int index) => buildItem(context,listContactFirebaseModel[index])),
                ),
              ),
              //  top
              Padding(
                padding: EdgeInsets.only(top: 30.0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 150.0,
                    color: Colors.transparent,
                    child: Column(
                      children: <Widget>[
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: EdgeInsets.only(top:10.0,bottom: 10.0,right: 10.0,left: 18.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('Select member to',style: TextStyle(fontSize: 16.0),),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('${widget.groupName}',style: TextStyle(fontSize: 25.0,fontWeight: FontWeight.bold),textAlign: TextAlign.left,),
                                ),
                              ],
                            ),
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
              // bottom
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
//                                Navigator.of(context).pop();
                              },
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      "Add  ",
                                      style: TextStyle(
                                        fontSize: 14.0,
                                      ),
                                    ),
                                    Icon(
                                      Icons.group_add,
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

  Widget buildItem(BuildContext context, ContactFirebaseModel listContactFirebaseModel, ){
    if(listContactFirebaseModel.getContactName.contains(filter)&& !widget.listIdMember.contains(listContactFirebaseModel.getContactId)){
      print('$TAG by filter =-> : ${filter}');
      print('$TAG id =-> : ${listContactFirebaseModel.getContactId}');
      print("$TAG widget.listIdMember: ${widget.listIdMember.toString()}");
      if(listContactFirebaseModel.getContactId == id){
        return Container();
      }else{
        return Material(
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
    else if(filter == "" && !widget.listIdMember.contains(listContactFirebaseModel.getContactId)){
      print('$TAG by filter =-> : ${filter}');
      print('$TAG id =-> : ${listContactFirebaseModel.getContactId}');
      print("$TAG widget.listIdMember: ${widget.listIdMember.toString()}");
      if(listContactFirebaseModel.getContactId == id){
        return Container();
      }else{
        return Material(
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
    else{
      return Container();
    }
  }

  void _sendTo(){
    setState(() {
      isLoading = true;
    });
    int i = 0;
    for(i = 0; i<listContactFirebaseModel.length;i++){
      if(listContactFirebaseModel[i].getIsChecked == true){
        print('$TAG id to add ${listContactFirebaseModel[i].getContactId}');
        setState(() {
          listMember.add(listContactFirebaseModel[i].getContactId);
        });
        _sent(i,listContactFirebaseModel[i]);
      }
    }
  }

  _sent(int count, ContactFirebaseModel listContactFirebaseModel) async {
//    if(listMember.length > 0){
    print('$TAG +MEMBER+ ${count.toString()} ${listContactFirebaseModel.getContactId}');

    //                    Notification add
    Firestore.instance.collection('notifications')
        .document("type1-"+timeId+widget.groupName)
        .setData(
        {
          'notifId': "type1-"+timeId+widget.groupName,
          'groupId': idGroup,
          'groupName': widget.groupName,
          'groupPhoto': widget.photoUrl,
          'text': "${yourName} added you to ${widget.groupName} group",
          'isRead': false,
          'time': timeId,
          'nameFrom': yourName,
          'idFrom': id,
          'nameTo': listContactFirebaseModel.getContactName,
          'idTo': listContactFirebaseModel.getContactId,
          'type': "1",
          'tag': "Add"
        });

    String peerName = listContactFirebaseModel.getContactName;
    String peerId = listContactFirebaseModel.getContactId;
    final postUrl = 'https://fcm.googleapis.com/fcm/send';
    var data = {
      "notification": {"body": "${peerName}, you just added to group ${widget.groupName}", "title": "${yourName}"},
      "priority": "high",
      "data": {
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "id": "1",
        "status": "done"
      },
      "to": "${listContactFirebaseModel.getContactToken}"
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
    _showForm(widget.groupName);

  }

  _showForm(String groupName){
    //  type 1 = name, 2 = desc
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
                title: Text("Success to added"),
                content: WillPopScope(
                  onWillPop: (){
                    Firestore.instance.collection('groups')
                        .document(idGroup)
                        .updateData(
                        {
                          'member': (FieldValue.arrayUnion(listMember)),
                          'isNewContent': '1',
                        });

                    Navigator.of(context).pop(); // To close the dialog
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => DiscussHomeScreen()),
                        ModalRoute.withName("/discussroom"));
                  },
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 0.0, left: 4.0,right: 4.0),
                    child: Container(
                      height: 120,
                      color: Colors.transparent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Align(
                                  alignment: Alignment.bottomLeft,
                                  child: FlatButton(
                                    onPressed: () {
                                      Firestore.instance.collection('groups')
                                          .document(idGroup)
                                          .updateData(
                                          {
                                            'member': (FieldValue.arrayUnion(listMember)),
                                            'isNewContent': '1',
                                          });

                                      Navigator.of(context).pop(); // To close the dialog
                                      Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(builder: (context) => DiscussHomeScreen()),
                                          ModalRoute.withName("/discussroom"));
                                    },
                                    child: Text("Close"),
                                  ),
                                ),
                              ],
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

}
