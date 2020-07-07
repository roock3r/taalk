import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taalk/models/ContactFirebaseModel.dart';
import 'package:taalk/models/GroupFirebaseModel.dart';
import 'package:taalk/views/room/ChatGroupScreen.dart';
import 'package:taalk/views/room/CreateGroupScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:taalk/helpers/GlobalVariable.dart' as globals;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupFirebaseScreen extends StatefulWidget {
  @override
  _GroupFirebaseScreenState createState() => _GroupFirebaseScreenState();
}

class _GroupFirebaseScreenState extends State<GroupFirebaseScreen> with /*WidgetsBindingObserver,*/ SingleTickerProviderStateMixin {
  String TAG = "Discuss GroupFirebaseScreen";

  TextEditingController _textFieldController = TextEditingController();
  final ScrollController listScrollController = new ScrollController();
  TextEditingController inputGroupName = new TextEditingController();


  String filter = "";
  String id = "";
  String yourName = "";
  String docIdGroup = "";
  String contentIdGroup = "";

  List<ContactFirebaseModel> listContactFirebaseModel = new List<ContactFirebaseModel>();
  List<GroupFirebaseModel> listGroupFirebaseModel = new List<GroupFirebaseModel>();
  List<String> listGroupId = new List<String>();
  Color _colorPrimary = Color(0xFF4aacf2);

  bool isLoading;

  SharedPreferences prefs;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
//    WidgetsBinding.instance.addObserver(this);
//    _getDocumentId();
    _getPref();
    isLoading == true;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
//    WidgetsBinding.instance.removeObserver(this);
  }

  _getPref() async {
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
            // List
            Container(
              child: StreamBuilder(
                stream: Firestore.instance.collection('groups')
                    .orderBy('contentTime', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_colorPrimary),
                      ),
                    );
                  }
                  else {
                    return ListView.builder(
                      padding: EdgeInsets.only(top: 75.0),
                      controller: listScrollController,
                      itemBuilder:(context, index) => buildItem2(context, snapshot.data.documents[index]),
                      itemCount: snapshot.data.documents.length,
                    );
                  }
                },
              ),
            ),
            // Loading
            Positioned(
              child: isLoading == true ? Container(
                child: Center(
                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_colorPrimary)),
                ),
                color: Colors.white.withOpacity(0.8),
              )
                  : Container(),
            ),
            // Search
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: 70.0,
                padding: EdgeInsets.only(top: 10.0,left: 8.0,right: 8.0,bottom: 5.0),
                color: Colors.transparent,
                child: Stack(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topCenter,
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
                                    controller: inputGroupName,
                                    onChanged: (text){
                                      setState(() {
                                        print("$TAG text: $text");
                                        filter = text;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText: "Search group name",
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
                                    inputGroupName.clear();
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
          ],
        ),
      ),
    );
  }// End Widget Build

  Widget buildItem2(BuildContext _context, DocumentSnapshot document) {
    double _width = MediaQuery.of(_context).size.width/2;
    return AnimationConfiguration.staggeredList(
        position: 1,
        duration: const Duration(milliseconds: 300),
        child: SlideAnimation(
          child: Container(
            child: document.data['member'].toString().contains(id)
                && document.data['groupName'].contains(filter.toLowerCase())
                ? Container(
              child: Column(
                children: <Widget>[
                  FlatButton(
                    padding: EdgeInsets.fromLTRB(8.0, 10.0, 8.0, 10.0),
                    onPressed: (){
                      Firestore.instance.collection('groups')
                          .document(document['groupId'])
                          .updateData(
                          {
                            'memberRead': (FieldValue.arrayUnion([id])),
                          }
                      );
                      Navigator.push(
                          _context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  ChatGroupScreen(
                                    groupId: document.data['groupId'],
                                    groupName: document.data['groupName'],
                                    photoGroup: document.data['photoGroup'],
                                  )));
                    },
                    child: Row(
                      children: <Widget>[
                        Material(
                          child: document.data['photoGroup'] != null ?
                          Stack(
                            children: <Widget>[
                              Material(
                                child: CachedNetworkImage(
                                  placeholder: (context, url) =>
                                      Container(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.0,
                                          valueColor: AlwaysStoppedAnimation<
                                              Color>(_colorPrimary),
                                        ),
                                        width: 50.0,
                                        height: 50.0,
                                        padding: EdgeInsets.all(15.0),
                                      ),
                                  imageUrl: document.data['photoGroup'],
                                  width: 50.0,
                                  height: 50.0,
                                  fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.all(
                                    Radius.circular(26.0)),
                                clipBehavior: Clip.hardEdge,
                              ),
                            ],
                          ) : Icon(
                            Icons.account_circle,
                            size: 50.0,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(width: 16.0,),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '${document.data['groupName']}',
                              style: TextStyle(
                                  color: document.data['memberRead']
                                      .toString()
                                      .contains(id)
                                      ? Colors.grey
                                      : Colors.black87,
                                  fontSize: 15.0),
                            ),
                            SizedBox(height: 2.0,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(document.data['userFrom'] =='${yourName}' ? 'You:' :
                                document.data['userFrom'] == null ? '':
                                '${document.data['userFrom']}:',
                                  style: TextStyle(color: Colors.black38),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Container(
                                  width: _width-10,
                                  child: Wrap(
                                    direction: Axis.horizontal, // main axis (rows or columns)
                                    spacing: 0.0,
                                    runSpacing: 0.0,
                                    children: <Widget>[
                                      Text(document.data['lastContentGroup'] == null ? '':
                                      ' ${document.data['lastContentGroup']}',
                                        style: TextStyle(color: Colors.black38),
                                        maxLines: 1,
                                        softWrap: true,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.0,),
                            Container(
                              width: MediaQuery.of(_context).size.width-90,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  DateFormat('kk:mm - dd MMM yyyy').format(
                                      DateTime.fromMillisecondsSinceEpoch(
                                          int.parse(document.data['contentTime']))),
                                  style: TextStyle(color: Colors.black38,
                                      fontSize: 12.0,
                                      fontStyle: FontStyle.italic),
                                ),
                              )
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    height: 0.3,
                    color: Colors.grey,
                    margin: const EdgeInsets.only(top: 2.0, bottom: 2.0),),
                ],
              ),
            )
                :Container(),
            margin: EdgeInsets.only(bottom: 0.9, left: 0.0, right: 0.0),
          ),
        )
    );
  }

  Widget buildM(BuildContext context, DocumentSnapshot document){
      return Text("Test");
  }

  setTime(time,_contentIdGroup) async {
    contentIdGroup = _contentIdGroup;
    return Padding(
      padding: EdgeInsets.all(3.0),
      child: Text(
        DateFormat('kk:mm - dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(int.parse(time))),
        style: TextStyle(color: Colors.black38, fontSize: 12.0, fontStyle: FontStyle.italic),
        textAlign: TextAlign.right,
      ),
    );
  }


}
