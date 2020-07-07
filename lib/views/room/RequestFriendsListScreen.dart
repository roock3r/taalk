import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taalk/views/room/DiscussHomeScreen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RequestFriendsListScreen extends StatefulWidget {
  String id;
  List<String> listRequest = new List<String>();

  RequestFriendsListScreen({this.id, this.listRequest});

  @override
  _RequestFriendsListScreenState createState() => _RequestFriendsListScreenState();
}

class _RequestFriendsListScreenState extends State<RequestFriendsListScreen> with WidgetsBindingObserver {
  String TAG = 'RequestFriendsListScreen';

  TextEditingController _textFieldControllerContactForward = TextEditingController();
  String filter = "";

  List<UserRequest> listUserRequest = new List<UserRequest>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('$TAG initState Running');
    _getUser();
  }

  _getUser()async{
    widget.listRequest.forEach((val) async {
      print('$TAG value: ${val}');
      QuerySnapshot querySnapshot = await Firestore.instance.collection("users_")
          .where('id',isEqualTo: val)
          .getDocuments();
      var list = querySnapshot.documents;
      print('$TAG lenght request   ${list.length}');
      for(var i = 0; i < list.length; i++){
        print('$TAG userIdFrom ${list[i]['nickname']}');
        UserRequest request = new UserRequest();
        request.setChattingWith = list[i]['chattingWith'];
        request.setContactContentTime = list[i]['contentTime'];
        request.setCreateAt = list[i]['createAt'];
        request.setContactId = list[i]['id'];
        request.setInRoom = list[i]['inRoom'];
        request.setIsNewContent = list[i]['isNewContent'];
        request.setContactName = list[i]['nickname'];
        request.setContactPhoto = list[i]['photoUrl'];
        request.setContactToken = list[i]['pushToken'];
        setState(() {
          listUserRequest.add(request);
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      print('$TAG - Background AppLifecycleState paused');
    }
    if (state == AppLifecycleState.resumed) {
      print('$TAG - Foreground AppLifecycleState resumed');
    }
    if (state == AppLifecycleState.inactive) {
      print('$TAG - Background AppLifecycleState inactive');
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
        body: Container(
          color: Colors.white,
          child: Stack(
            children: <Widget>[
              // List
              Container(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.only(top: 120.0),
                  child: ListView.builder(
                      itemCount: listUserRequest.length,
                      itemBuilder: (BuildContext context, int index) => buildItem(context,listUserRequest[index],index)),
                ),
              ),
              //  search
              Padding(
                padding: EdgeInsets.only(top: 30.0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 120.0,
                    child: Column(
                      children: <Widget>[
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: EdgeInsets.only(top:10.0,bottom: 10.0,right: 10.0,left: 18.0),
                            child: Text('Request Friends',style: TextStyle(fontSize: 25.0,fontWeight: FontWeight.bold),),
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
                                          setState(() {
                                            filter = text;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          hintText: "Search by nickname",
                                          border: InputBorder.none,
                                          icon: Icon(Icons.search,color:Colors.grey),
                                          contentPadding: EdgeInsets.all(5.0),
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                        Icons.send,
                                        color:Colors.blue
                                    ),
                                    onPressed: () {

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
            ],
          ),
        ),
      ),
    );
  }

  Widget buildItem(BuildContext context, UserRequest listContactFirebaseModel,int index ){
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
                              Color>(Colors.blue),
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
              trailing: Container(
                width: 90.0,
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
//                        _saveToRequestFriends(document['id'],document['nickname']);
                        print('$TAG myId: ${widget.id}');
                        print('$TAG peerId: ${listContactFirebaseModel.getContactId}');
                        _addToMyFriends(
                          listContactFirebaseModel.getChattingWith,
                          listContactFirebaseModel.getContactContentTime,
                          listContactFirebaseModel.getCreateAt,
                          listContactFirebaseModel.getContactId,
                          listContactFirebaseModel.getInRoom,
                          listContactFirebaseModel.getIsNewContent,
                          listContactFirebaseModel.getContactName,
                          listContactFirebaseModel.getContactPhoto,
                          listContactFirebaseModel.getContactToken,
                        );
                        _addToYourFriends(
                          listContactFirebaseModel.getChattingWith,
                          listContactFirebaseModel.getContactContentTime,
                          listContactFirebaseModel.getCreateAt,
                          listContactFirebaseModel.getContactId,
                          listContactFirebaseModel.getInRoom,
                          listContactFirebaseModel.getIsNewContent,
                          listContactFirebaseModel.getContactName,
                          listContactFirebaseModel.getContactPhoto,
                          listContactFirebaseModel.getContactToken,
                        );
                        setState(() {
                          listUserRequest.removeAt(index);
                        });
                        _deleteRequestList();
                      },
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              "Accept ",
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
                              Color>(Colors.blue),
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
              trailing: Container(
                width: 90.0,
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
//                        _saveToRequestFriends(document['id'],document['nickname']);
                        print('$TAG myId: ${widget.id}');
                        print('$TAG peerId: ${listContactFirebaseModel.getContactId}');
                        _addToMyFriends(
                          listContactFirebaseModel.getChattingWith,
                          listContactFirebaseModel.getContactContentTime,
                          listContactFirebaseModel.getCreateAt,
                          listContactFirebaseModel.getContactId,
                          listContactFirebaseModel.getInRoom,
                          listContactFirebaseModel.getIsNewContent,
                          listContactFirebaseModel.getContactName,
                          listContactFirebaseModel.getContactPhoto,
                          listContactFirebaseModel.getContactToken,
                        );
                        _addToYourFriends(
                          listContactFirebaseModel.getChattingWith,
                          listContactFirebaseModel.getContactContentTime,
                          listContactFirebaseModel.getCreateAt,
                          listContactFirebaseModel.getContactId,
                          listContactFirebaseModel.getInRoom,
                          listContactFirebaseModel.getIsNewContent,
                          listContactFirebaseModel.getContactName,
                          listContactFirebaseModel.getContactPhoto,
                          listContactFirebaseModel.getContactToken,
                        );
                        setState(() {
                          listUserRequest.removeAt(index);
                        });
                        _deleteRequestList();
                      },
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              "Accept ",
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
          ],
        ),
      );
    }
  }


  _addToMyFriends(String chattingWith, String contentTime, String createAt, String peerId,
      String inRoom, bool isNewContent,String nickname,String photo,String token) async {
    final QuerySnapshot result =
    await Firestore.instance.collection('users_').document(widget.id).collection('my_friends').where('id', isEqualTo: peerId)
        .getDocuments();
    final List<DocumentSnapshot> documents = result.documents;
    if(documents.length == 0){
      Firestore.instance.collection('users_')
          .document(widget.id).collection('my_friends').document(peerId)
          .setData({
        'chattingWith': null,
        'contentTime': DateTime.now().toString(),
        'createdAt': DateTime.now().toString(),
        'id': peerId,
        'inRoom': inRoom,
        'isNewContent': false,
        'isTyping': false,
        'nickname': nickname,
        'photoUrl': photo,
        'pushToken': token,
      });
      Fluttertoast.showToast(msg: "Success accept");
    }else{
      print('$TAG Friends already accept 1');
    }
  }

  _addToYourFriends(String chattingWith, String contentTime, String createAt, String peerId,
      String inRoom, bool isNewContent,String nickname,String photo,String token) async {
    final QuerySnapshot result =
    await Firestore.instance.collection('users_').document(peerId).collection('my_friends').where('id', isEqualTo: widget.id)
        .getDocuments();
    final List<DocumentSnapshot> documents = result.documents;
    if(documents.length == 0){

      QuerySnapshot querySnapshot = await Firestore.instance.collection("users_")
          .where('id',isEqualTo: widget.id)
          .limit(1)
          .getDocuments();
      var list = querySnapshot.documents;
      print('$TAG get my   ${list.length}');
      for(var i = 0; i < list.length; i++){
        print('$TAG userIdFrom ${list[i]['userIdFrom']}');

        Firestore.instance.collection('users_')
            .document(peerId).collection('my_friends').document(widget.id)
            .setData({
          'chattingWith': null,
          'contentTime': DateTime.now().toString(),
          'createdAt': DateTime.now().toString(),
          'id': list[i]['id'],
          'inRoom': inRoom,
          'isNewContent': false,
          'isTyping': false,
          'nickname': list[i]['nickname'],
          'photoUrl': list[i]['photoUrl'],
          'pushToken': list[i]['pushToken'],
        });

      }

      Fluttertoast.showToast(msg: "Success accept");
      print('$TAG Success add 2');
    }else{
      print('$TAG Friends already accept 2');

    }
  }

  _deleteRequestList()async{
    Firestore.instance
        .collection('request_friends')
        .document(widget.id)
        .delete()
        .whenComplete((){
      print('$TAG Success delete request');
    });
  }

}

class UserRequest{
  String chattingWith;
  String contactContentTime;
  String createAt;
  String contactId;
  String inRoom;
  bool isNewContent;
  String contactName;
  String contactPhoto;
  String contactToken;

  String get getChattingWith => chattingWith;
  set setChattingWith(String value) => chattingWith = value;

  String get getContactContentTime => contactContentTime;
  set setContactContentTime(String value) => contactContentTime = value;

  String get getCreateAt => createAt;
  set setCreateAt(String value) => createAt = value;

  String get getContactId => contactId;
  set setContactId(String value) => contactId = value;

  String get getInRoom => inRoom;
  set setInRoom(String value) => inRoom = value;

  bool get getIsNewContent => isNewContent;
  set setIsNewContent(bool value) => isNewContent = value;

  String get getContactName => contactName;
  set setContactName(String value) => contactName = value;

  String get getContactPhoto => contactPhoto;
  set setContactPhoto(String value) => contactPhoto = value;

  String get getContactToken => contactToken;
  set setContactToken(String value) => contactToken = value;

}
