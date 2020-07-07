import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taalk/models/ContactFirebaseModel.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taalk/helpers/GlobalVariable.dart' as globals;



class ViewerStoriesScreen extends StatefulWidget {
  String idStory;

  ViewerStoriesScreen({this.idStory});

  @override
  _ViewerStoriesScreenState createState() => _ViewerStoriesScreenState();
}

class _ViewerStoriesScreenState extends State<ViewerStoriesScreen> {
  String TAG = 'ViewerStoriesScreen';

  String id;
  String yourName;
  String myPhotoUrl = "";
  String myToken = "";

  SharedPreferences prefs;

  int countViewers = 0;
  List<dynamic> listViewers = new List<dynamic>();
  bool isLoading = true;

  Color _colorPrimary = Color(0xFF0b0f5e);

  List<ContactFirebaseModel> listContactFirebaseModel = new List<ContactFirebaseModel>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getPref();
    set();
  }

  set(){
    Timer(const Duration(milliseconds: 100), () {
      setState(() {
        isLoading = false;
      });
    });
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.only(top: 5.0),
          child: isLoading == true ? Container(
            color: Colors.white,
            child: Center(
              child: CircularProgressIndicator(backgroundColor: Colors.red,)
            )
          )
              :StreamBuilder(
            stream: Firestore.instance.collection('stories')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: Text("Connecting..."),
                );
              }
              else {
                return ListView.builder(
                  padding: EdgeInsets.only(top: 0.0),
                  itemBuilder: (context, index) => buildItem(context, snapshot.data.documents[index]),
                  itemCount: snapshot.data.documents.length,
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget buildItem(BuildContext context, DocumentSnapshot document){
    if(document.documentID==widget.idStory){
      print("$TAG looping: ${document.data['viewerStory'].toString()}");
      List<dynamic> listName = document.data['viewerStory'];
      List<dynamic> listPhoto = document.data['viewerPhotoStory'];
      for(int i=0;i<listName.length;i++){
        print("$TAG name: ${listName[i]}");
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
                  imageUrl: listPhoto[i],
                  width: 35.0,
                  height: 35.0,
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.all(
                    Radius.circular(26.0)),
                clipBehavior: Clip.hardEdge,
              ),
                title: Text(
                  listName[i], style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold),),
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



}
