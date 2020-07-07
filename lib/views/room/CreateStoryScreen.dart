import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert' show Encoding, json;
import 'package:taalk/views/room/DiscussHomeScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taalk/helpers/GlobalVariable.dart' as globals;


class CreateStoryScreen extends StatefulWidget {
  @override
  _CreateStoryScreenState createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  String TAG = 'CreateStoryScreen ';

  TextEditingController inputCaption = TextEditingController();


  String id;
  String yourName;
  String myPhotoUrl = "";
  String myToken = "";
  String caption = "";
  Color _colorPrimary = Color(0xFF4aacf2);

  List<File> listImage = new List();
  List listBytes = new List();
  List<String> ListImageUrl = List();
  List<String> listIdMyFriends = List();
  List listTokenFriends = List();
//  List<BytesModel> listBytesModel = new List<BytesModel>();

  TextEditingController _textFieldController = TextEditingController();

//  File imageFile;
  String imageUrl;
//  var _image = null;
  Uint8List bytes = null;
  String base64Image;

  double heightDrawer = 0.0;

  bool isLoading = false;
  bool showBottomCaption = false;

  String idDoc = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print("$TAG initState running...");
    _getPref();
    Timer(const Duration(milliseconds: 200), () {
      print("$TAG show body image");
      setState(() {
        heightDrawer = 270.0;
      });
    });
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
      idDoc = id+"-"+DateTime.now().millisecondsSinceEpoch.toString();
    });
    print('$TAG Your Id: ${id}');
    print('$TAG Your Name: ${yourName}');
    _getIdMyFriends();
  }

  _getIdMyFriends() async {
    QuerySnapshot querySnapshot = await Firestore.instance.collection("users_").document(id)
        .collection('my_friends').getDocuments();
    var list = querySnapshot.documents;
    print('$TAG my_friends length  ${list.length}');
    for(var i = 0; i < list.length; i++){
      print('$TAG my_friends id =-> ${list[i]['id']}');
      listIdMyFriends.add(list[i]['id']);
      listTokenFriends.add(list[i]['pushToken']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop:(){
        Navigator.pop(context,true);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomPadding: false,
        body: Stack(
          children: <Widget>[
//            Image
            Align(
              alignment: Alignment.center,
              child: Container(
                child: listImage.length > 0 ?
                //  list image
                Container(
                  height: double.infinity,
                  width: double.infinity,
                  child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: listBytes.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.all(0.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26
                                      .withOpacity(0.1),
                                  blurRadius: 1.0,
                                  offset: const Offset(
                                      0.0, 2.0),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(0.0),
                            width: MediaQuery.of(context).size.width * 1,
                            child: Stack(
                              children: <Widget>[
                                Container(
                                  child: Image.memory(listBytes[index],
                                    height: double.infinity,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: EdgeInsets
                                        .only(top: 30.0,right: 10.0),
                                    child: InkWell(
                                      onTap: () {
                                        print(
                                            '$TAG delete image story');
                                        _deleteImageStory(
                                            index);
                                      },
                                      child: Icon(
                                        Icons.delete,
                                        size: 40.0,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                )
                    : Container(
                    child:Center(
                        child: AnimatedContainer(
                          height: heightDrawer,
                          duration: Duration(seconds: 1),
                          curve: Curves.fastOutSlowIn,
                          child: Image(
                            image: AssetImage(
                                "assets/images/ic_tab_stories.png"),
                          ),
                        )
                    )
                ),
              ),
            ),
//            Caption
            Align(
              alignment: Alignment.center,
              child: showBottomCaption == true ? Card(
                  elevation: 0.0,
                  margin: EdgeInsets.only(left: 10.0, right: 10.0),
                  color: Colors.grey.withOpacity(0.5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: TextField(
                          style: new TextStyle(color: Colors.white),
                          controller: inputCaption,
                          maxLines: 7,
                          decoration: InputDecoration.collapsed(
                              hintText: "Enter caption timeline",
                              fillColor: Colors.white
                          ),
                        ),
                      ),
                      //  button caption
                      ButtonTheme(
                        height: 35.0,
                        minWidth: 50.0,
                        child: FlatButton(
                            shape: new RoundedRectangleBorder(
                                borderRadius: new BorderRadius
                                    .circular(15.0),
                                side: BorderSide(
                                    color: Colors.blue)
                            ),
                            color: Colors.white,
                            textColor: Colors.blue,
                            padding: EdgeInsets.all(8.0),
                            onPressed: () {
                              if(showBottomCaption==true){
                                setState(() {
                                  showBottomCaption = false;
                                  return;
                                });
                              }
                            },
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .center,
                                children: <Widget>[
                                  Text(
                                    "Minimize caption ",
                                    style: TextStyle(
                                      fontSize: 14.0,
                                    ),
                                  ),
                                  Icon(
                                    Icons.create,
                                    size: 20.0,
                                    color: Colors.blue,
                                  ),
                                ],
                              ),
                            )
                        ),
                      ),
                    ],
                  )
              ):Container(),
            ),
            //  body
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                  color: Colors.transparent,
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.all(0.0),
                        child: Column(
                          children: <Widget>[
                            listImage.length > 1 ? Card(child: Padding(
                              padding: EdgeInsets.all(3.0),
                              child: Text("Slide to right/left"),
                            ),):Text(""),
                            SizedBox(
                              height: 10.0,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                //  button camera or gallery
                                ButtonTheme(
                                  minWidth: MediaQuery.of(context).size.width / 3.5,
                                  height: 40.0,
                                  child: FlatButton(
                                      shape: new RoundedRectangleBorder(
                                          borderRadius: new BorderRadius
                                              .circular(15.0),
                                          side: BorderSide(
                                              color: Colors.yellow[800])
                                      ),
                                      color: Colors.white,
                                      textColor: Colors.yellow[800],
                                      padding: EdgeInsets.all(8.0),
                                      onPressed: () {
                                        if(listImage.length > 1){
                                          Fluttertoast.showToast(msg: "Max image is 2",backgroundColor: Colors.red,
                                              textColor: Colors.white);
                                        }else{
                                          _showPopUp();
                                        }
                                      },
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment
                                              .center,
                                          children: <Widget>[
                                            Text(
                                              "Add image ",
                                              style: TextStyle(
                                                fontSize: 14.0,
                                              ),
                                            ),
                                            Icon(
                                              Icons.filter,
                                              size: 20.0,
                                              color: Colors.yellow[800],
                                            ),
                                          ],
                                        ),
                                      )
                                  ),
                                ),
                                //  button caption
                                ButtonTheme(
                                  minWidth: MediaQuery.of(context).size.width / 3.5,
                                  height: 40.0,
                                  child: FlatButton(
                                      shape: new RoundedRectangleBorder(
                                          borderRadius: new BorderRadius
                                              .circular(15.0),
                                          side: BorderSide(
                                              color: Colors.blue)
                                      ),
                                      color: Colors.white,
                                      textColor: Colors.blue,
                                      padding: EdgeInsets.all(8.0),
                                      onPressed: () {
                                          if(showBottomCaption == false){
                                            setState(() {
                                              showBottomCaption = true;
                                              return;
                                            });
                                          }
                                      },
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment
                                              .center,
                                          children: <Widget>[
                                            Text(
                                              "Write caption ",
                                              style: TextStyle(
                                                fontSize: 14.0,
                                              ),
                                            ),
                                            Icon(
                                              Icons.create,
                                              size: 20.0,
                                              color: Colors.blue,
                                            ),
                                          ],
                                        ),
                                      )
                                  ),
                                ),
                                //  button posting
                                ButtonTheme(
                                  minWidth: MediaQuery.of(context).size.width / 3.5,
                                  height: 40.0,
                                  child: FlatButton(
                                      shape: new RoundedRectangleBorder(
                                          borderRadius: new BorderRadius
                                              .circular(15.0),
                                          side: BorderSide(
                                              color: Colors.green)
                                      ),
                                      color: Colors.white,
                                      textColor: Colors.green,
                                      padding: EdgeInsets.all(8.0),
                                      onPressed: () {
                                        _createStory();
                                      },
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment
                                              .center,
                                          children: <Widget>[
                                            Text(
                                              "Posting ",
                                              style: TextStyle(
                                                fontSize: 14.0,
                                              ),
                                            ),
                                            Icon(
                                              Icons.send,
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
                          ],
                        ),
                      ),
                    ],
                  )
              ),
            ),
            //  isLoading
            isLoading ? Align(
              child: Container(
                height: double.infinity,
                width: double.infinity,
                color: Colors.grey.withOpacity(0.5),
                child: Center(
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.grey)),
                ),
              ),
              alignment: Alignment.center,
            ) : Container(),
          ],
        ),
      ),
    );
  }

  _deleteImageStory(int index){
    setState(() {
      listBytes.removeAt(index);
      listImage.removeAt(index);
    });
    print('$TAG listBytes.length ${listBytes.length}');
    print('$TAG listImage.length ${listImage.length}');
  }

  _createStory() async {
    if(inputCaption != ""){
      //  posting image to firebase to get the link
      print('$TAG list ${listImage.length}');
      if(listImage.length == 0){
        print('$TAG complete without image');
        Fluttertoast.showToast(msg: 'Image must be fill');
      }
      else{
        setState(() {
          isLoading = true;
        });
        for(int i=0; i<listImage.length; i++){
          print('$TAG i to: ${i}');
          print('$TAG get link image: ${listImage[i]}');
          String fileName = DateTime.now().millisecondsSinceEpoch.toString();
          StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
          StorageUploadTask uploadTask = reference.putFile(listImage[i]);
          StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
          storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
            print("$TAG url: ${storageTaskSnapshot.ref.getDownloadURL()}");
            print("$TAG downloadUrl: ${downloadUrl}");
            setState(() {
              ListImageUrl.add(downloadUrl);
            });
            if(i==(listImage.length-1)){
              _postStoriesToFirebase(idDoc);
            }
          }, onError: (err) {
            setState(() {
              isLoading = false;
            });
            Fluttertoast.showToast(msg: 'Info: ${err.toString()}');
            print('$TAG Info: ${err.toString()}');
          });
        }
      }
    }
    else{
      Fluttertoast.showToast(msg: 'Caption must be fill');
    }
  }

  _postStoriesToFirebase(String idDoc){
    listIdMyFriends.add(id);
    print('$TAG imgUrl: ${ListImageUrl.length}');
    print('$TAG listImage: ${listImage.length}');
      if(ListImageUrl.length == listImage.length){
        Firestore.instance.collection('stories')
            .document(idDoc)
            .setData({
          'contentCaptionStory': inputCaption.text.toString(),
          // update contentImageStory when success post this and got link image upload
          'contentTime': DateTime.now().toString(),
          // update disLikerStory when user action
          'idStory': idDoc,
          'idUser': id,
          // update likerStory when user action
          'nickname': yourName,
          'photoUrl': myPhotoUrl,
          'pushToken': myToken,
          // update shareStoryTo when success post this
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          // update viewerStory when user action
        }).whenComplete(() {
          print('$TAG updating contentImageStory...');
          Firestore.instance.collection('stories')
              .document(idDoc)
              .updateData(
              {
                'contentImageStory': (FieldValue.arrayUnion(ListImageUrl)),
                'shareStoryTo': (FieldValue.arrayUnion(listIdMyFriends)),
                'likerStory': (FieldValue.arrayUnion([])),
                'disLikerStory': (FieldValue.arrayUnion([])),
                'viewerStory': (FieldValue.arrayUnion([])),
              }).whenComplete((){
            _sendNotifToMyFriends();
            Timer(const Duration(milliseconds: 800), () {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => DiscussHomeScreen()),
                  ModalRoute.withName("/discussroom"));        });
          });
        });

      }
  }

  _sendNotifToMyFriends() async {
    Fluttertoast.showToast(msg: 'Uploading stories...',backgroundColor: Colors.blue,textColor: Colors.white,
    toastLength: Toast.LENGTH_LONG);
    for(int i=0;i<listTokenFriends.length;i++){
      final postUrl = 'https://fcm.googleapis.com/fcm/send';
      var data = {
        "notification": {"body": "${yourName} just posting stories", "title": "Discuss Story"},
        "priority": "high",
        "data": {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "id": "1",
          "status": "done"
        },
        "to": "${listTokenFriends[i]}"
      };
      final headers = {
        'content-type': 'application/json',
        'Authorization': 'key=${globals.serverKeyFirebaseStatic}'
      };
      final response = await http.post(postUrl,
          body: json.encode(data),
          encoding: Encoding.getByName('utf-8'),
          headers: headers);
      if (response.statusCode == 200) {
        // on success do sth
        setState(() {
          isLoading = false;
        });
        print('FCM Success sent');
      } else {
        // on failure do sth
        print('FCM Failure sent');
      }
    }
  }

  _showForm(){
    //  type 1 = name, 2 = desc
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
                title: Text('Caption story'),
                content: Padding(
                  padding: EdgeInsets.only(bottom: 0.0, left: 4.0,right: 4.0),
                  child: Container(
                    height: 120,
                    color: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Container(
                              width: 200.0,
                              height: 25.0,
                              child: TextField(
                                style: TextStyle(height: 1.0,),
                                controller: _textFieldController,
                                decoration: InputDecoration(
                                  hintText: 'caption here',
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 25.0,
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Align(
                                alignment: Alignment.bottomLeft,
                                child: FlatButton(
                                  onPressed: () {
                                    _textFieldController.clear();
                                    Navigator.of(context).pop(); // To close the dialog
                                  },
                                  child: Text("Cancel"),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: FlatButton(
                                  onPressed: () {
                                    setState(() {
                                      caption = inputCaption.text.toString();
                                    });
                                    Navigator.of(context).pop(); // To close the dialog
                                  },
                                  child: Text("Set"),
                                ),
                              ),
                            ],
                          ),
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
        pageBuilder: (context, animation1, animation2) {}
    );
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
    File _file = await ImagePicker.pickImage(source: ImageSource.gallery);
    print("$TAG _file: ${_file.toString()}");

//    _image = await ImagePicker.pickImage(source: ImageSource.gallery);
    List<int> imageBytes = _file.readAsBytesSync();
    print("$TAG imagebytes: $imageBytes");
    base64Image = base64UrlEncode(imageBytes);
    print("$TAG base64: $base64Image");
    print("You selected gallery image : " + _file.path);
    setState(() {
      bytes = Base64Codec.urlSafe().decode(base64Image);
    });
    if (_file != null) {
//      setFile();
      setState(() {
        print('$TAG added!');
        listImage.add(_file);
        listBytes.add(bytes);
      });
    }
  }


  Future getImageCamera() async {
    File _file = await ImagePicker.pickImage(source: ImageSource.camera);
//    _image = await ImagePicker.pickImage(source: ImageSource.camera);
    List<int> imageBytes = _file.readAsBytesSync();
    print("$TAG imagebytes: $imageBytes");
    base64Image = base64UrlEncode(imageBytes);
    print("$TAG base64: $base64Image");
    print("You selected gallery image : " + _file.path);
    setState(() {
      bytes = Base64Codec.urlSafe().decode(base64Image);
    });
    if (_file != null) {
//      setFileCamera();
      setState(() {
        print('$TAG added!');
        listImage.add(_file);
        listBytes.add(bytes);
      });
    }
  }

}
