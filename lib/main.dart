import 'package:camera/camera.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_video_recorder_app/constant/Constant.dart';
import 'package:flutter_video_recorder_app/screen/CameraHomeScreen.dart';
import 'package:flutter_video_recorder_app/screen/ResultScreen.dart';
import 'package:flutter_video_recorder_app/screen/SplashScreen.dart';
import 'package:flutter_video_recorder_app/screen/UserInputScreen.dart';

List<CameraDescription> cameras;

Future<Null> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    //logError(e.code, e.description);
  }
  runApp(
    MaterialApp(
      title: "Video Recorder App",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),
      routes: <String, WidgetBuilder>{
        USER_INPUT_SCREEN:( BuildContext context) => UserInputScreen(),
        RESULT_SCREEN: (BuildContext context) => ResultScreen(),
        CAMERA_SCREEN: (BuildContext context) => CameraHomeScreen(cameras),
      },
    ),
  );
}
