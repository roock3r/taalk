import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taalk/views/LoginDiscuss.dart';
import 'package:taalk/views/room/CreateStoryScreen.dart';
import 'package:taalk/views/room/DiscussHomeScreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/GlobalVariable.dart' as globals;

void main() async {
  runApp(MyHomePage());
}

class MyHomePage extends StatefulWidget {

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {

  String TAG = "Main ";

  Color _colorPrimary = Color(0xFF4aacf2);
  Color _primaryColorDark = Color(0xFF0686e0);
  Color _accentColor = Color(0xFFf7e949);

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    print("$TAG initState Running");
    getPref();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      print('$TAG - Background AppLifecycleState paused');

      WidgetsBinding.instance.removeObserver(this);
    }
    if (state == AppLifecycleState.resumed) {
      print('$TAG - Foreground AppLifecycleState resumed');
    }
    if (state == AppLifecycleState.inactive) {
      print('$TAG - Background AppLifecycleState inactive');
      WidgetsBinding.instance.removeObserver(this);
    }
  }

  getPref()async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if(prefs.getString(globals.keyPrefColorPrimaryAttendance)!=null||prefs.getString(globals.keyPrefColorPrimaryAttendance)==""){
      setState(() {
        String colorPrimary = prefs.getString(globals.keyPrefColorPrimaryAttendance);
        print("main string color: $colorPrimary");
        String valueString = colorPrimary.split('(0x')[1].split(')')[0];
        int value = int.parse(valueString, radix: 16);
        _colorPrimary = new Color(value);
      });
    }
  }

  inRoom(String status) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String id = prefs.getString(globals.keyPrefFirebaseUserId) ?? '';
    QuerySnapshot querySnapshot = await Firestore.instance.collection("users_")
        .getDocuments();
    var list = querySnapshot.documents;
    print('$TAG lenght all users_  ${list.length}');
    for(var i = 0; i < list.length; i++){
      print('$TAG document users_ ${list[i]['id']}');
      final QuerySnapshot result =
      await Firestore.instance.collection('users_').document(list[i]['id'])
          .collection('my_friends').where('id', isEqualTo: id)
          .getDocuments();
      final List<DocumentSnapshot> documents = result.documents;
      if(documents.length > 0){
        print('$TAG update from users_ ${list[i]['id']}');
        print('$TAG to my ${id}');
        Firestore.instance.collection('users_')
            .document(list[i]['id'])
            .collection('my_friends')
            .document(id)
            .updateData({'inRoom': status});
      }
      Firestore.instance.collection('users_')
          .document(id)
          .updateData({'inRoom': status});
    }
    print("$TAG CLOSED INROOM");
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: new ThemeData(
        canvasColor: Colors.transparent,
        primaryColor: _colorPrimary,
        primaryColorDark: _primaryColorDark,
        accentColor: _accentColor,
      ),
      home: new LoginDiscuss(),
      routes: <String, WidgetBuilder>{
        '/loginDiscuss': (BuildContext context) => new LoginDiscuss(),
        '/logout': (BuildContext context) => new DiscussHomeScreen(),
        '/discusshome': (BuildContext context) => new DiscussHomeScreen(),
        '/storyscreen': (BuildContext context) => new CreateStoryScreen(),
      },
    );
  }

}