import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taalk/views/room/DetailStoriesFirebaseScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taalk/helpers/GlobalVariable.dart' as globals;


class StoriesFirebaseScreen extends StatefulWidget {
  @override
  _StoriesFirebaseScreenState createState() => _StoriesFirebaseScreenState();
}

class _StoriesFirebaseScreenState extends State<StoriesFirebaseScreen> /*with WidgetsBindingObserver */{
  String TAG = 'StoriesFirebaseScreen';

  final controller = new PageController();
  ScrollController listScrollStoryController = new ScrollController();


  int liker = 0;
  int disLiker = 0;
  int viewers = 0;
  List<String> listImageStory  = new List<String>();
  List<String> listViewers = new List<String>();
  List<String> listLikers = new List<String>();
  List<String> listDisLikers = new List<String>();

  String id;
  String yourName;
  String myPhotoUrl = "";
  String myToken = "";
  Color _colorPrimary = Color(0xFF4aacf2);

  bool showStories = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
//    WidgetsBinding.instance.addObserver(this);
    listScrollStoryController = new ScrollController();
    _getPref();
  }


  @override
  void dispose() {
    // TODO: implement dispose
//    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  _getPref() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Stack(
          children: <Widget>[
            StreamBuilder(
              stream: Firestore.instance.collection('stories')
                  .orderBy('contentTime', descending: true)
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
                      padding: EdgeInsets.only(bottom: 70.0, top: 5.0, left: 0.0, right: 0.0),
                      controller: listScrollStoryController,
                      itemCount: snapshot.data.documents.length,
                      itemBuilder: (BuildContext context, int index) => buildItem(context, snapshot.data.documents[index])
                  );
                }
              },
            ),
          ],
        ),
      )
    );
  }

  Widget buildItem(BuildContext context, DocumentSnapshot document){
    try{
      if(document['likerStory']!=null){
        print('$TAG likerStory OK');
        listLikers = List.from(document['likerStory']);
        liker = listLikers.length;
      }else{
        print('$TAG ${document['contentCaptionStory']}=> likerStory null');
        print('$TAG likerStory null');
        liker = 0;
      }
    }on Exception catch(e){
      liker = 0;
    }

    try{
      if(document['disLikerStory']!=null){
        print('$TAG disLikerStory OK');
        listDisLikers = List.from(document['disLikerStory']);
        disLiker = listDisLikers.length;
      }else{
        print('$TAG ${document['contentCaptionStory']}=> disLikerStory null');
        print('$TAG disLikerStory null');
        disLiker = 0;
      }
    }on Exception catch(e){
      disLiker = 0;
    }

    try{
      if(document['viewerStory']!=null){
        listViewers = List.from(document['viewerStory']);
        viewers = listViewers.length;
        print('$TAG VIEW: ${listViewers.length}');
      }else{
        viewers = 0;
      }
    }on Exception catch(e){
      viewers = 0;
    }

    try{
      if(document['contentImageStory']==null){
        listImageStory = ['https://icon-library.net/images/no-image-available-icon/no-image-available-icon-6.jpg'];
      }
      else{
        listImageStory = List.from(document['contentImageStory']);
      }
    }on Exception catch(e){
      listImageStory = ['https://icon-library.net/images/no-image-available-icon/no-image-available-icon-6.jpg'];
    }

    double c_width = MediaQuery.of(context).size.width-100;
    print("$TAG size: ${c_width}");

    print("$TAG time: ${document.data['timestamp']}");
    var date = new DateTime.fromMillisecondsSinceEpoch(int.parse(document.data['timestamp']));
    DateTime dateTimeNow = DateTime.now();
    final differenceInDays = dateTimeNow.difference(date).inDays;
    print("$TAG Dif: ${differenceInDays}");
//    check if diferent in 1 days or 24hours
    if(differenceInDays>=1){
      Firestore.instance.collection('stories').document(document.documentID).delete();
    }

    if(document.data['shareStoryTo'].toString().contains(id)){
      return AnimationConfiguration.staggeredList(
          position: 1,
          duration: const Duration(milliseconds: 300),
          child: SlideAnimation(
            child: Container(
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  /*Profile*/
                  InkWell(
                    onTap: () {
                      if(document['idUser'].toString()!=id){
                        Firestore.instance.collection('stories')
                            .document(document['idStory'])
                            .updateData(
                            {
                              'viewerStory': (FieldValue.arrayUnion([yourName])),
                              'viewerPhotoStory': (FieldValue.arrayUnion([myPhotoUrl])),
                            }).whenComplete((){
                          print("$TAG OK READ");
                        });
                      }
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  DetailStoriesFirebaseScreen(
//                                  type: "0",
                                    idStory: document['idStory'],
                                  )));
                      print('clicked');
                    },
                    child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.only(
                            left: 12.0, top: 10.0, bottom: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Stack(
                              children: <Widget>[
                                Material(
                                  child: CachedNetworkImage(
//                              imageUrl: '${document['photoUrl']}',
                                      imageUrl: '${listImageStory[0]}',
                                      width: 48.0,
                                      height: 48.0,
                                      fit: BoxFit.fill
                                  ),
                                  borderRadius: BorderRadius
                                      .all(
                                      Radius.circular(25.0)),
                                  clipBehavior: Clip.hardEdge,
                                ),
                                Positioned(
                                  bottom: 1.0,
                                  right: 0.1,
                                  child: Container(
                                    child: Center(
                                      child: Text("${listImageStory.length}",style: TextStyle(color: Colors.white,fontSize: 9),),
                                    ),
                                    padding: EdgeInsets.all(1.0),
                                    decoration: BoxDecoration(
                                      color: Colors.primaries[Random()
                                          .nextInt(
                                          Colors.primaries.length)],
                                      border: Border.all(width: 1.0,color: Colors.white),
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: BoxConstraints(
                                      minWidth: 16.0,
                                      minHeight: 16.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: 17.0,
                            ),
                            Material(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text('${document['nickname']}',
                                    style: TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.black,
                                        fontWeight: FontWeight
                                            .bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(
                                    height: 2.0,
                                  ),
                                  Container(
                                    width: c_width,
                                    margin: EdgeInsets.only(bottom: 7.0),
                                    child: Text(
                                      '${document['contentCaptionStory']}',
                                      style: TextStyle(color: Colors.black54),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 5,
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 1.0,
                                  ),
                                  Container(
                                    width: MediaQuery.of(context).size.width-90,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        DateFormat('kk:mm - dd MMM yyyy').format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                                int.parse(document['timestamp']))),
                                        style: TextStyle(color: Colors.black38,
                                            fontSize: 11.0,
                                            fontStyle: FontStyle.italic),
                                        textAlign: TextAlign.right,

                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        )
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    height: 0.3,
                    color: Colors.grey,
                    margin: const EdgeInsets.only(top: 2.0, bottom: 2.0),),
                ],
              ),
            ),
          )
      );
    }else{
      return Container();
    }
  }


}
