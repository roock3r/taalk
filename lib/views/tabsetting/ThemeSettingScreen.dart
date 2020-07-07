import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taalk/helpers/GlobalVariable.dart' as globals;


class ThemeSettingScreen extends StatefulWidget{
  ThemeSettingScreen();
  @override
  ThemeSettingScreenState createState() => ThemeSettingScreenState();
}

class ThemeSettingScreenState extends State<ThemeSettingScreen> {
  String TAG = "ThemeSettingScreen";
  TextEditingController _textFieldController = TextEditingController();

  var imageData = null;
  Uint8List bytes = null;
  String base64Image;
  String title = "";

  // create some values
  Color pickerColor = Color(0xff443a49);
  Color currentColor = Color(0xff443a49);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print("$TAG initState Running");
    _getPref();
  }

  _getPref() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if(prefs.getString(globals.keyPrefTitleAttendance)!=null||prefs.getString(globals.keyPrefTitleAttendance)==""){
      setState(() {
        title = prefs.getString(globals.keyPrefTitleAttendance);
        print(" $TAG Pref title: $title");
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
              _openGallery();
            },
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Image.asset('assets/images/ic_background_green_64px.png',
                      height: 27),
                  Padding(
                      padding: EdgeInsets.fromLTRB(17, 0, 0, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text("Change Logo",
                              style:
                              TextStyle(fontSize: 16, color: Colors.black)),
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
              _displayPickerColor(context);
            },
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Image.asset('assets/images/ic_theme_green_64px.png',
                      height: 27),
                  Padding(
                      padding: EdgeInsets.fromLTRB(17, 0, 0, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text("Change Main Color",
                              style:
                              TextStyle(fontSize: 16, color: Colors.black)),
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
              _displayDialog(context);
            },
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Image.asset('assets/images/ic_edit_green_64px.png',
                      height: 27),
                  Padding(
                      padding: EdgeInsets.fromLTRB(17, 0, 0, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text("Set Title App",
                              style:
                              TextStyle(fontSize: 16, color: Colors.black)),
                          Text("$title", style: TextStyle(color: Colors.grey)),
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

  _openGallery() async {
    imageData = await ImagePicker.pickImage(source: ImageSource.gallery);
    List<int> imageBytes = imageData.readAsBytesSync();
    print("$TAG imagebytes: $imageBytes");
    base64Image = base64UrlEncode(imageBytes);
    print("$TAG base64: $base64Image");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(globals.keyPrefLogoAttendance, base64Image);
    print("You selected gallery image : " + imageData.path);
    setState(() {
      imageData = imageData;
//      base64Image = base64Image;
      bytes = Base64Codec.urlSafe().decode(base64Image);
    });
  }

  _displayDialog(BuildContext context) async {
    String value = "";
    value = title;
    _textFieldController.text = title;
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Set title app"),
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
                  _save(_textFieldController.text);
                  Navigator.of(context).pop();
                  _textFieldController.clear();
                },
              )
            ],
          );
        }
    );
  }

  _save(String value) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("$TAG $value");
    prefs.setString(globals.keyPrefTitleAttendance, value);
    setState(() {
      _getPref();
    }
    );
  }

  _displayPickerColor(BuildContext context) async{
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("Set color primary"),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: pickerColor,
                onColorChanged: changeColor,
                enableLabel: true,
                pickerAreaHeightPercent: 0.8,
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: const Text('Save'),
                onPressed: () {
                  _saveColorPrimary(pickerColor);
                  Navigator.of(context).pop();
                  _showAlert();
                },
              ),
            ],
          );
        }
    );
  }

  void _showAlert() async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Attentions!"),
            content: Text("Theme will be apply after you exit app"),
            actions: <Widget>[
              new FlatButton(
                child: new Text('Ok'),
                onPressed: () {
                  exit(0);
//                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  // ValueChanged<Color> callback
  void changeColor(Color color) {
    setState(() => pickerColor = color);
  }

  void _saveColorPrimary(Color pickerColor) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("$TAG value color $pickerColor");
    String colorStringPrimary = pickerColor.toString();
    print("$TAG color to string $pickerColor");
    prefs.setString(globals.keyPrefColorPrimaryAttendance, colorStringPrimary);
  }

}
