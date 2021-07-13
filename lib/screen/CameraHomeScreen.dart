import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:circular_countdown/circular_countdown.dart';
import 'package:camera/camera.dart';
import 'package:flutter_video_recorder_app/constant/Constant.dart';
import 'package:flutter_video_recorder_app/utility/ScreenArgument.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:export_video_frame/export_video_frame.dart';

class CameraHomeScreen extends StatefulWidget {
  List<CameraDescription> cameras;

  CameraHomeScreen(this.cameras);

  @override
  State<StatefulWidget> createState() {
    return _CameraHomeScreenState();
  }
}

class _CameraHomeScreenState extends State<CameraHomeScreen> {
  String imagePath;
  bool _toggleCamera = false;
  bool _startRecording = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  CameraController controller;

  int video_duration = 10; // duration for capturing video
  String videoPath;
  VoidCallback videoPlayerListener;

  @override
  void initState() {
    try {
      onCameraSelected(widget.cameras[0]);
    } catch (e) {
      print(e.toString());
    }
    // instantiation for audio Player
    super.initState();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onUpdatecounts(CountdownUnit unit, int remaining) async {
    if (remaining == 10){
      await start_audio();
      onVideoRecordButtonPressed();
    }
    else {
      onVideoRecordButtonPressed();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cameras.isEmpty) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all(16.0),
        child: Text(
          'No Camera Found!',
          style: TextStyle(
            fontSize: 16.0,
            color: Colors.white,
          ),
        ),
      );
    }

    if (!controller.value.isInitialized) {
      return Container();
    }

    return AspectRatio(
      key: _scaffoldKey,
      aspectRatio: controller.value.aspectRatio,
      child: Container(
        child: Stack(
          children: <Widget>[
            CameraPreview(controller),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                height: 120.0,
                padding: EdgeInsets.all(20.0),
                color: Color.fromRGBO(00, 00, 00, 0.7),
                child: Stack(
                  //mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.center,
                      child: Material(
                       color: Colors.transparent,
                        child: InkWell(
                            child:
                              Center(
                                  child: TimeCircularCountdown(
                                    unit: CountdownUnit.second,
                                    countdownTotal: 10,
                                    onUpdated: _onUpdatecounts,
                                    onFinished: onStopButtonPressed,
                                  )
                              )
                            ),
                      ),
                    ),
                    !_startRecording ? _getToggleCamera() : new Container(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getToggleCamera() {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.all(Radius.circular(50.0)),
          onTap: () {
            !_toggleCamera
                ? onCameraSelected(widget.cameras[1])
                : onCameraSelected(widget.cameras[0]);
            setState(() {
              _toggleCamera = !_toggleCamera;
            });
          },
          /*child: Container(
            padding: EdgeInsets.all(4.0),
            child: Image.asset(
              'assets/images/ic_switch_camera_3.png',
              color: Colors.grey[200],
              width: 42.0,
              height: 42.0,
            ),*//*
          ),*/
        ),
      ),
    );
  }

  void onCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) await controller.dispose();
    controller = CameraController(cameraDescription, ResolutionPreset.medium);

    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        showSnackBar('Camera Error: ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showException(e);
    }

    if (mounted) setState(() {});
  }

  String timestamp() => new DateTime.now().millisecondsSinceEpoch.toString();

  void setCameraResult() => print("Recording Done!");

  void onVideoRecordButtonPressed() async {
    // awaiting for playing start sound (bell)
    print('onVideoRecordButtonPressed()');
      //succeed , start video recording
    startVideoRecording().then((String filePath) {
         if (mounted) setState(() {});
         if (filePath != null) showSnackBar('Saving video to $filePath');
       });


  }

  void onStopButtonPressed() {
    stopVideoRecording().then((_) {
      if (mounted) setState(() {});
      print('[CameraHomeScreen] Video is recorded');
      _getImagesByDuration();
      // get arguments from UserInput Screen
      var args = ModalRoute.of(context).settings.arguments as ScreenArgument;
      // push args to Result Screen
      Navigator.pushReplacementNamed(context, RESULT_SCREEN,arguments: args);

    });
  }

  Future _getImagesByDuration() async {
    final Directory extDir = await getApplicationDocumentsDirectory() ;
    
    final String dirPath = '${extDir.path}/Videos';
    final String filePath = '$dirPath/recorded.mp4';

    var duration = 1;
    for(int i = 0 ; i < video_duration ; i++){
      var image = await ExportVideoFrame.exportImageBySeconds(File(filePath),Duration(seconds:duration+i), pi/2);
    }
  }

  Future<String> startVideoRecording() async {
    if (!controller.value.isInitialized) {
      showSnackBar('Error: select a camera first.');
      return null;
    }

    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Videos';
    await new Directory(dirPath).create(recursive: true);

    final String filePath = '$dirPath/recorded.mp4';


    if (controller.value.isRecordingVideo) {
      return null;
    }

    try {
      videoPath = filePath;
      await controller.startVideoRecording(filePath);
    } on CameraException catch (e) {
      _showException(e);
      return null;
    }
    return filePath;
  }

  Future<void> stopVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.stopVideoRecording();
    } on CameraException catch (e) {
      _showException(e);
      return null;
    }

    setCameraResult();
  }

  void _showException(CameraException e) {
    logError(e.code, e.description);
    showSnackBar('Error: ${e.code}\n${e.description}');
  }

  void showSnackBar(String message) {
    var snackbar = SnackBar(content: Text(message),);
    ScaffoldMessenger.of(context).showSnackBar(snackbar) ;
  }

  void logError(String code, String message) =>
      showSnackBar('Error: $code\nMessage: $message');

  Future start_audio() async {
    AudioCache audioCache = AudioCache();
    await audioCache.play('audio/bell_audio.mp3');
  }

}
