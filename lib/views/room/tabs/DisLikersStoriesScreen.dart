import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taalk/models/ContactFirebaseModel.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taalk/helpers/GlobalVariable.dart' as globals;



class DisLikersStoriesScreen extends StatefulWidget {
  String idStory;
  DisLikersStoriesScreen({this.idStory});

  @override
  _DisLikersStoriesScreenState createState() => _DisLikersStoriesScreenState();
}

class _DisLikersStoriesScreenState extends State<DisLikersStoriesScreen> {
  String TAG = 'DisLikersStoriesScreen';

  String id;
  String yourName;
  String myPhotoUrl = "";
  String myToken = "";
  int countViewers = 0;

  List<dynamic> listDislikers = new List<dynamic>();
  bool isLoading = true;

  Color _colorPrimary = Color(0xFF0b0f5e);

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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString(globals.keyPrefColorPrimaryAttendance) != null ||
        prefs.getString(globals.keyPrefColorPrimaryAttendance) == "") {
      String colorPrimary =
      prefs.getString(globals.keyPrefColorPrimaryAttendance);
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
      List<dynamic> listName = document.data['disLikerStory'];
      List<dynamic> listPhoto = document.data['disLikerPhotoStory'];
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
