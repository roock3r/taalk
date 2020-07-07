import 'package:flutter/material.dart';

class MonitoringSettingScreen extends StatefulWidget{
  MonitoringSettingScreen();
  @override
  MonitoringSettingScreenState createState() => MonitoringSettingScreenState();
}

class MonitoringSettingScreenState extends State<MonitoringSettingScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          // center the children
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.settings,
              size: 160.0,
              color: Colors.green,
            ),
            Text("On progress...")
          ],
        ),
      ),
    );
  }
}
