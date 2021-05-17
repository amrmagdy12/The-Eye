import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_video_recorder_app/constant/Constant.dart';
import 'package:flutter_video_recorder_app/screen/VideoPlayerScreen.dart';
import 'package:path_provider/path_provider.dart';


class ResultScreen extends StatefulWidget {
  ResultScreen();

  @override
  State<StatefulWidget> createState() {
    return _ResultScreenState();
  }
}

class _ResultScreenState extends State<ResultScreen> {
  String _videoPath = null;
  double _headerHeight = 320.0;
  final String _assetPlayImagePath = 'assets/images/ic_play.png';
  final String _assetImagePath = 'assets/images/ic_no_video.png';

  var _thumbPath;

  var _videoName;

  _ResultScreenState();


  @override
  void dispose() async{
    // clear recorded video and exported frames ..
    var vidDeleted = await deleteVideorecorded() ;
    var framesDeleted = deleteDirectory("/data/data/com.aeologic.fluttervideorecorderapp/app_flutter/app_ExportImage") ;

    if (framesDeleted && vidDeleted)
      print("Disposing ResultScreen : video recorded and the exported frames are deleted");

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: <Widget>[
        _videoPath != null ? _getVideoContainer() : _getImageFromAsset(),
        _getCameraFab(),
        _getLogo(),
      ],
    ));
  }

  Widget _getImageFromAsset() {
    return ClipPath(
      child: Padding(
        padding: EdgeInsets.only(bottom: 30.0),
        child: Container(
            width: double.infinity,
            height: _headerHeight,
            color: Colors.grey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  _assetImagePath,
                  fit: BoxFit.fill,
                  width: 48.0,
                  height: 32.0,
                ),
                Container(
                  margin: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'No Video Available',
                    style: TextStyle(
                      color: Colors.grey[350],
                      //fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ],
            )),
      ),
    );
  }

  Widget _getVideoContainer() {
    return Container(
      padding: EdgeInsets.only(bottom: 30.0),
      child: new Container(
          width: double.infinity,
          height: _headerHeight,
          color: Colors.grey,
          child: Stack(
            children: <Widget>[
              _thumbPath != null
                  ? new Opacity(
                opacity: 0.5,
                child: new Image.file(
                  File(
                    _thumbPath,
                  ),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: _headerHeight,
                ),
              )
                  : new Container(),
              new Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(new MaterialPageRoute(
                            builder: (BuildContext context) =>
                            new VideoPlayerScreen(_videoPath)));
                      },
                      child: new Image.asset(
                        _assetPlayImagePath,
                        width: 72.0,
                        height: 72.0,
                      ),
                    ),
                    new Container(
                      margin: EdgeInsets.only(top: 2.0),
                      child: Text(
                        _videoName != null ? _videoName : "",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildPathWidget()
            ],
          )),
    );
  }

  Widget _buildPathWidget() {
    return _videoPath != null
        ? new Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        height: 100.0,
        padding: EdgeInsets.only(
            left: 10.0, right: 10.0, top: 5.0, bottom: 5.0),
        color: Color.fromRGBO(00, 00, 00, 0.7),
        child: Center(
          child: Text(
            _videoPath,
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    )
        : new Container();
  }

  Widget _getCameraFab() {
    return Positioned(
      top: _headerHeight - 30.0,
      right: 16.0,
      child: FloatingActionButton(
        onPressed: _recordVideo,
        child: Icon(
          Icons.videocam,
          color: Colors.white,
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _getLogo() {
    return Container(
      margin: EdgeInsets.only(top: 200.0),
      alignment: Alignment.center,
      child: Center(
        child: Image.asset(
          'assets/images/ic_flutter_devs_logo.png',
          width: 160.0,
          height: 160.0,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  bool deleteDirectory(String dirpath){
    final dir = Directory(dirpath);
    dir.deleteSync(recursive: false);
  }
  Future<bool> deleteVideorecorded() async {
    var dir = await getApplicationDocumentsDirectory() ;
    var path = dir.path ;
    String filepath = "$path/recorded.mp4" ;
    var file = File(filepath);

    var file_exists = await file.exists() ;

    if (file_exists){
      await file.delete() ;
      return true ;
    }

    return false ;
  }

  // method to be used in User Input Screen
  Future _recordVideo() async {
    final videoPath = await Navigator.of(context).pushNamed(CAMERA_SCREEN);
    setState(() {
      _videoPath = videoPath;
    });
  }
}
