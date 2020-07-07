import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:taalk/helpers/GlobalVariable.dart' as globals;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taalk/models/ContactFirebaseModel.dart';
import 'package:taalk/views/room/DiscussHomeScreen.dart';
import 'package:taalk/views/room/FriendGroupCreateScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateGroupScreen extends StatefulWidget {
  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  String TAG = 'CreateGroupScreen';

  String groupName = '-';
  String groupDesc = '-';
  // image group
  String id = "";
  String nickname = "";
  String photoUrl = "";
  String pushToken = "";

  TextEditingController _textFieldController = TextEditingController();
  TextEditingController inputName = TextEditingController();
  TextEditingController inputDesc = TextEditingController();

  File imageFile;
  File imageFileCamera;
  String imageUrl;

  var _image = null;
  Uint8List bytes = null;
  String base64Image;

  double heightDrawer = 0.0;

  List<ContactFirebaseModel> listContactFirebaseModel = new List<ContactFirebaseModel>();

  void initState() {
    // TODO: implement initState
    super.initState();
    print('$TAG initState Running...');
    _getPref();
    Timer(const Duration(milliseconds: 120), () {
      print("$TAG show header drawer");
      setState(() {
        heightDrawer = 300.0;
      });
    });
  }

  _getPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs = await SharedPreferences.getInstance();
    id = prefs.getString(globals.keyPrefFirebaseUserId) ?? '';
    nickname = prefs.getString(globals.keyPrefFirebaseName) ?? '';
    photoUrl = prefs.getString(globals.keyPrefFirebasePhotoUrl) ?? '';
    pushToken = prefs.getString(globals.keyPrefTokenFirebase) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop:(){
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => DiscussHomeScreen()),
            ModalRoute.withName("/discussroom"));
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomPadding: false,
        body: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 300.0),
            child: Padding(
              padding: EdgeInsets.only(top: 40.0, left: 15, right: 15, bottom: 10.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(width: 0, color: Colors.transparent),
                  color: Colors.transparent,
                ),
                child: Stack(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: EdgeInsets.only(top: 0.0,bottom: 0.0),
                        child: Container(
                            width: double.infinity,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.all(14.0),
                                  child: Text(
                                    "Create Group Discuss",
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                AnimatedContainer(
                                  width: double.infinity,
                                  height: heightDrawer,
                                  duration: Duration(seconds: 1),
                                  curve: Curves.easeInOut,
                                  decoration: BoxDecoration(
                                      image: DecorationImage(
                                      image: AssetImage(
                                      "assets/images/ic_tab_group.png"),
                                  fit: BoxFit.contain,
                                ),),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(15.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text('Group name',
                                        style: TextStyle(fontSize: 17.0),
                                      ),
                                      Card(
                                          color: Colors.white,
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: TextField(
                                              controller: inputName,
                                              maxLines: 2,
                                              autocorrect: true,
                                              decoration: InputDecoration.collapsed(hintText: "Enter group name"),
                                            ),
                                          )
                                      ),
                                      SizedBox(
                                        height: 15.0,
                                      ),
                                      Text('Group descriptions',
                                        style: TextStyle(fontSize: 17.0),
                                      ),
                                      Card(
                                          color: Colors.white,
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: TextField(
                                              controller: inputDesc,
                                              maxLines: 8,
                                              decoration: InputDecoration.collapsed(hintText: "Enter group description"),
                                            ),
                                          )
                                      ),
                                      SizedBox(
                                        height: 30.0,
                                      ),
                                      Container(
                                        child: Stack(
                                          children: <Widget>[
                                            Align(
                                              alignment: Alignment.topLeft,
                                              child: Padding(
                                                padding: EdgeInsets.only(left: 20.0),
                                                child: Text('Choose image group',
                                                  style: TextStyle(fontSize: 17.0),
                                                ),
                                              ),
                                            ),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: Stack(
                                                children: <Widget>[
                                                  InkWell(
                                                    onTap: (){
                                                      _showPopUp();
                                                    },
                                                    child: imageFile == null ? Container(
                                                        width: 70.0,
                                                        height: 70.0,
                                                        margin: EdgeInsets.fromLTRB(0.0, 0.0, 0, 0),
                                                        decoration: new BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            border: Border.all(
                                                              width: 2.0,
                                                              color: Colors.red,
                                                            ),
                                                            image: new DecorationImage(
                                                                fit: BoxFit.fill,
                                                                image: ExactAssetImage("assets/images/ic_profile_group.png")
                                                            )
                                                        )
                                                    )
                                                        : new ClipRRect(
                                                      borderRadius: new BorderRadius.circular(60.0),
                                                      child: new Image.memory(
                                                        bytes,
                                                        height: 75.0,
                                                        width: 75.0,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    bottom: 2.0,
                                                    right: 0.0,
                                                    child: InkWell(
                                                      onTap: (){
                                                        _showPopUp();
                                                      },
                                                      child: Container(
                                                        height: 27.0,
                                                        width: 27.0,
                                                        padding: EdgeInsets.all(1.0),
                                                        decoration: BoxDecoration(
                                                          color: Colors.red,
                                                          shape: BoxShape.circle,
                                                        ),
                                                        constraints: BoxConstraints(
                                                          minWidth: 10.0,
                                                          minHeight: 10.0,
                                                        ),
                                                        child: Center(
                                                          child: Icon(
                                                            Icons.camera_enhance,
                                                            color: Colors.white,
                                                            size: 20.0,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height: 20.0,
                                      ),
                                      ButtonTheme(
                                        minWidth: 480.0,
                                        height: 40.0,
                                        child: FlatButton(
                                            shape: new RoundedRectangleBorder(
                                                borderRadius: new BorderRadius.circular(15.0),
                                                side: BorderSide(color: Colors.green)
                                            ),
                                            color: Colors.white,
                                            textColor: Colors.green,
                                            padding: EdgeInsets.all(8.0),
                                            onPressed: () {
                                              _createGroup();
                                            },
                                            child: Center(
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: <Widget>[
                                                  Text(
                                                    "Next ",
                                                    style: TextStyle(
                                                      fontSize: 14.0,
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.navigate_next,
                                                    size: 20.0,
                                                    color: Colors.green,
                                                  ),
                                                ],
                                              ),
                                            )
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
        ),
      ),
    );
  }// End Widget Build

  _createGroup(){
    if(id == "" || inputName.text.toString() == "" || inputDesc.text.toString() == ""){
      Fluttertoast.showToast(msg: "Please write name or description correctly",backgroundColor: Colors.red, textColor: Colors.white);
    }
    else if(imageFile == null){
      Fluttertoast.showToast(msg: "Please add image",backgroundColor: Colors.red, textColor: Colors.white);
    }
    else{
//      _setContact();
      ContactFirebaseModel _contactFirebaseModel = new ContactFirebaseModel();
      _contactFirebaseModel.setContactId = id;
      _contactFirebaseModel.setContactName = nickname;
      _contactFirebaseModel.setContactPhoto = photoUrl;
      _contactFirebaseModel.setContactToken = pushToken;
      _contactFirebaseModel.setIsChecked = false;
      listContactFirebaseModel.add(_contactFirebaseModel);
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) =>
              FriendGroupCreateScreen(
              /*  listContactFirebaseModel:listContactFirebaseModel,*/
                groupName: inputName.text.toString(),
                groupDesc: inputDesc.text.toString(),
                imageFile: imageFile,
              )
          ),
          ModalRoute.withName("/friendsgroup"));
    }
  }

  _saveData(int type){
    if(type==1){
      setState(() {
        groupName = _textFieldController.text.toString();
      });
    }
    if(type==2){
      setState(() {
        groupDesc = _textFieldController.text.toString();
      });
    }
    _textFieldController.clear();
  }

  _showPopUp(){
    showGeneralDialog(
        barrierColor: Colors.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) -   1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: AlertDialog(
                shape: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                title: Text('Select to'),
                content: Padding(
                  padding: EdgeInsets.only(bottom: 10.0,left: 4.0,right: 4.0),
                  child: Container(
                    height: 100,
                    color: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            InkWell(
                              onTap: (){
                                getImage();
                                Navigator.pop(context);
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Container(
                                      width: 45.0,
                                      height: 45.0,
                                      decoration: new BoxDecoration(
//                          shape: BoxShape.circle,
                                          image: new DecorationImage(
                                              fit: BoxFit.fitWidth,
                                              image: ExactAssetImage(
                                                  "assets/images/ic_gallery_attach.png"
                                              )
                                          )
                                      )
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(top: 4.0),
                                    child: Text("Gallery"),
                                  )
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 15.0,
                            ),
                            InkWell(
                              onTap: (){
                                getImageCamera();
                                Navigator.pop(context);
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Container(
                                    width: 45.0,
                                    height: 45.0,
                                    decoration: new BoxDecoration(
//                          shape: BoxShape.circle,
                                        image: new DecorationImage(
                                            fit: BoxFit.fitWidth,
                                            image: ExactAssetImage(
                                                "assets/images/ic_camera_attach.png"
                                            )
                                        )
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(top: 4.0),
                                    child: Text("Camera"),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: true,
        barrierLabel: '',
        context: context,
        pageBuilder: (context, animation1, animation2) {});
  }

  Future getImage() async {
    imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
//    _image = await ImagePicker.pickImage(source: ImageSource.gallery);
    List<int> imageBytes = imageFile.readAsBytesSync();
    print("$TAG imagebytes: $imageBytes");
    base64Image = base64UrlEncode(imageBytes);
    print("$TAG base64: $base64Image");
    print("You selected gallery image : " + imageFile.path);
    setState(() {
      _image = imageFile;
      bytes = Base64Codec.urlSafe().decode(base64Image);
    });
    if (imageFile != null) {
//      setFile();
      setState(() {
        imageFile = imageFile;
      });
    }
  }

  Future getImageCamera() async {
    try{
      imageFile = await ImagePicker.pickImage(source: ImageSource.camera);
      List<int> imageBytes = imageFile.readAsBytesSync();
      print("$TAG imagebytes: $imageBytes");
      base64Image = base64UrlEncode(imageBytes);
      print("$TAG base64: $base64Image");
      print("You selected gallery image : " + imageFile.path);
      setState(() {
        _image = imageFile;
        bytes = Base64Codec.urlSafe().decode(base64Image);
      });
      if (imageFile != null) {
//      setFileCamera();
        setState(() {
          imageFile = imageFile;
        });
      }
    }catch(e){
      print("$TAG getImageCamera error: ${e}");
    }
  }

}
