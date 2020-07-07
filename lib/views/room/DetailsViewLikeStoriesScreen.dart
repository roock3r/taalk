import 'package:taalk/views/room/tabs/DisLikersStoriesScreen.dart';
import 'package:taalk/views/room/tabs/LikersSctoriesScreen.dart';
import 'package:taalk/views/room/tabs/ViewerStoriesScreen.dart';
import 'package:flutter/material.dart';

class DetailsViewLikeStoriesScreen extends StatefulWidget {
  String idStory;
  /*List<dynamic> listViewer_ = new List<dynamic>();
  List<dynamic> listLikers_ = new List<dynamic>();
  List<dynamic> listDislikers_ = new List<dynamic>();*/

  DetailsViewLikeStoriesScreen({
    this.idStory
    /*this.listViewer_,
    this.listLikers_,
    this.listDislikers_*/
  });

  @override
  _DetailsViewLikeStoriesScreenState createState() => _DetailsViewLikeStoriesScreenState();
}

class _DetailsViewLikeStoriesScreenState extends State<DetailsViewLikeStoriesScreen> with SingleTickerProviderStateMixin{
  String TAG = 'DetailsViewLikeStoriesScreen';

  // Create a tab controller
  TabController controller;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print('$TAG TAB ${widget.idStory}');

    controller = TabController(length: 3, vsync: this);
    controller.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handleTabSelection() {
//    setState(() {
//    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.black, //change your color here
          ),
          elevation: 3,
          // Title
          title: Padding(
            padding: EdgeInsets.only(top: 10.0,bottom: 0.0),
            child: Text(
              "Details",
              style: TextStyle(color: Colors.black),
            ),
          ),
          // Set the background color of the App Bar
          backgroundColor: Colors.white,
          centerTitle: true,
          bottom: getTabBar()),
      body: getTabBarView(<Widget>[
        ViewerStoriesScreen(idStory: widget.idStory),
        LikersSctoriesScreen(idStory: widget.idStory),
        DisLikersStoriesScreen(idStory: widget.idStory)
      ]),
    );
  }

  TabBar getTabBar() {
    return TabBar(
      labelColor: Colors.white,
      tabs: <Tab>[
        Tab(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('View',style: TextStyle(color: Colors.black),),
              SizedBox(width: 4.0,),
              Icon(Icons.remove_red_eye,color: Colors.blueAccent,),
            ],
          )
        ),
        Tab(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Like',style: TextStyle(color: Colors.black),),
              SizedBox(width: 4.0,),
              Icon(Icons.thumb_up,color:Colors.green,),
            ],
          )
        ),
        Tab(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Dislike',style: TextStyle(color: Colors.black),),
              SizedBox(width: 4.0,),
              Icon(Icons.thumb_down,color :Colors.red,),
            ],
          )
        ),
      ],
      // setup the controller
      controller: controller,
    );
  }

  TabBarView getTabBarView(var tabs) {
    return TabBarView(
      // Add tabs as widgets
      children: tabs,
      // set the controller
      controller: controller,
    );
  }


}
