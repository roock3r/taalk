import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
//import 'package:pinch_zoom_image/pinch_zoom_image.dart';

class ViewPhotoChat extends StatefulWidget {
  String urlPhoto;

  ViewPhotoChat({this.urlPhoto});
  @override
  _ViewPhotoChatState createState() => _ViewPhotoChatState();
}

class _ViewPhotoChatState extends State<ViewPhotoChat> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white, //change your color here
        ),
        title: Text('Image View',style: TextStyle(color: Colors.white),),
      ),
      body: Container(
        height: double.infinity,
          color: Colors.black,
          child: PhotoView(
              imageProvider: NetworkImage('${widget.urlPhoto}')
          )
      ),
    );
  }
}
