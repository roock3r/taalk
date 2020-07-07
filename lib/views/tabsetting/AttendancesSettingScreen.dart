import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taalk/helpers/GlobalVariable.dart' as globals;

class AttendancesSettingScreen extends StatefulWidget {
  AttendancesSettingScreen();
  @override
  AttendancesSettingScreenState createState() =>
      AttendancesSettingScreenState();
}

class AttendancesSettingScreenState extends State<AttendancesSettingScreen> {
  String TAG = "AttendancesSettingScreen";
  TextEditingController _textFieldController = TextEditingController();

  String url_login = "";
  String url = "";
  String api = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print("$TAG InitStateRunning");
    _getPref();
  }

  _getPref() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if(prefs.getString(globals.keyPrefUrlAttendance)!=null||prefs.getString(globals.keyPrefUrlAttendance)==""){
      setState(() {
        url = prefs.getString(globals.keyPrefUrlAttendance);
        print("Pref url: $url");
      });
    }
    if(prefs.getString(globals.keyPrefApiAttendance)!=null||prefs.getString(globals.keyPrefApiAttendance)==""){
      setState(() {
        api = prefs.getString(globals.keyPrefApiAttendance);
        print("Pref api: $api");
      });
    }
    if(prefs.getString(globals.keyPrefUrlLoginAttendance)!=null||prefs.getString(globals.keyPrefUrlLoginAttendance)==""){
      setState(() {
        url_login = prefs.getString(globals.keyPrefUrlLoginAttendance);
        print("Pref url login: $url_login");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: <Widget>[
          InkWell(
            onTap: () {
              _displayDialog(context, 1);
            },
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Image.asset('assets/images/ic_server_green_24px.png',
                      height: 27),
                  Padding(
                      padding: EdgeInsets.fromLTRB(17, 0, 0, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text("Set base url",
                              style:
                              TextStyle(fontSize: 16, color: Colors.black)),
                          Text(url,
                              style: TextStyle(color: Colors.grey)),
                        ],
                      )),
                ],
              ),
            ),
          ),
          new Divider(
            color: Colors.grey,
          ),
          InkWell(
            onTap: () {
              _displayDialog(context, 2);
            },
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Image.asset('assets/images/ic_set_api_green_24px.png',
                      height: 27),
                  Padding(
                      padding: EdgeInsets.fromLTRB(17, 0, 0, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text("Set base api",
                              style:
                              TextStyle(fontSize: 16, color: Colors.black)),
                          Text("$api", style: TextStyle(color: Colors.grey)),
                        ],
                      )),
                ],
              ),
            ),
          ),
          new Divider(
            color: Colors.grey,
          ),
          InkWell(
            onTap: () {
              _displayDialog(context, 3);
            },
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Image.asset('assets/images/ic_server_green_24px.png',
                      height: 27),
                  Padding(
                      padding: EdgeInsets.fromLTRB(17, 0, 0, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text("Set url login",
                              style:
                              TextStyle(fontSize: 16, color: Colors.black)),
                          Text(url_login,
                              style: TextStyle(color: Colors.grey)),
                        ],
                      )),
                ],
              ),
            ),
          ),
          new Divider(
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  _displayDialog(BuildContext context, int i) async {
    String title = "";
    String value = "";
    if(i==1){
      title = "Set base url:";
      value = url;
      _textFieldController.text = url;
    }
    if(i==2){
      title = "Set base api:";
      value = api;
      _textFieldController.text = api;
    }
    if(i==3){
      title = "Set url login:";
      value = url_login;
      _textFieldController.text = url_login;
    }
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: TextField(
              controller: _textFieldController,
              decoration: InputDecoration(hintText: value, labelText: value),
            ),
            actions: <Widget>[
              new FlatButton(
                child: new Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _getPref();
                  });
                },
              ),
              new FlatButton(
                child: new Text('Save'),
                onPressed: () {
                  _save(i,_textFieldController.text);
                  Navigator.of(context).pop();
                  _textFieldController.clear();
                },
              )
            ],
          );
        });
  }

  _save(int i, String value) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if(i==1){
      print("$TAG $value");
      prefs.setString(globals.keyPrefUrlAttendance, value);
      setState(() {
        _getPref();
      });
    }
    if(i==2){
      print("$TAG $value");
      prefs.setString(globals.keyPrefApiAttendance, value);
      setState(() {
        _getPref();
      });
    }
    if(i==3){
      print("$TAG $value");
      prefs.setString(globals.keyPrefUrlLoginAttendance, value);
      setState(() {
        _getPref();
      });
    }
  }

}//end state
