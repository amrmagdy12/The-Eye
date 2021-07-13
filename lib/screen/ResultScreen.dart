import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_video_recorder_app/constant/Constant.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_video_recorder_app/utility/ScreenArgument.dart';
import 'package:logging/logging.dart';

class ResultScreen extends StatefulWidget {
  ResultScreen();

  @override
  State<StatefulWidget> createState() {
    return _ResultScreenState();
  }
}

class _ResultScreenState extends State<ResultScreen> {
  // paths for Frames
  List<String> paths = [];

  //request data
  var _formData;

  var _dio = Dio();

  //dio response variable
  var response;

  //Result Screen logger
  var logger = new Logger("[ResultScreen]");

  //argument passed
  var args;

  //message passed for chosen service
  String _service;

  _ResultScreenState();

  // indicate wether server responds
  bool is_responded = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    getFrames();
  }

  @override
  void dispose() async {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Result Screen

    args = ModalRoute.of(context).settings.arguments as ScreenArgument;

    _service = args.title;

    _formData = initRequest();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: null,
        body: Stack(alignment: Alignment.center, children: <Widget>[
          Container(
            height: double.infinity,
            width: double.infinity,
            child: Container(
              height: 150,
              width: 150,
              child: is_responded
                  ? Align(
                      alignment: Alignment.center,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: <Widget>[
                            ListTile(
                              leading: _service == CURRENCY_CHOICE
                                  ? FaIcon(FontAwesomeIcons.moneyBillWave)
                                  : _service == COLOR_CHOICE
                                      ? FaIcon(FontAwesomeIcons.palette)
                                      : FaIcon(FontAwesomeIcons.fileCode),
                              title: _service == CURRENCY_CHOICE
                                  ? Text(
                                      "Currency",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    )
                                  : _service == COLOR_CHOICE
                                      ? Text(
                                          "Color",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15),
                                        )
                                      : Text(
                                          "Text Extraction",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15),
                                        ),
                            ),
                            _service == CURRENCY_CHOICE
                                ? Image.asset(
                                    "assets/images/currency_image.jpg")
                                : _service == COLOR_CHOICE
                                    ? Image.asset(
                                        "assets/images/color_image.jpg")
                                    : Image.asset(
                                        "assets/images/ocr_image.jpg"),

                            // response text
                          ],
                        ),
                      ),
                    )
                  : Align(
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          //   CircularProgressIndicator(
                          //     value: null ,
                          //     strokeWidth: 8.0,
                          //   ),
                          //   Text("Please wait"),
                          ElevatedButton(
                              onPressed: sendRequest, child: Text("press"))
                        ],
                      ),
                    ),
            ),
          ),
        ]),
      ),
    );
  }

  Future<FormData> initRequest() async {
    _service == CURRENCY_CHOICE
        ? _dio.options.baseUrl =
            "http://blindassist.newtechhosting.net:5005/predict-currency"
        : _service == COLOR_CHOICE
            ? _dio.options.baseUrl =
                "http://blindassist.newtechhosting.net:5005/detect-color"
            : _dio.options.baseUrl =
                "http://blindassist.newtechhosting.net:5005/detect-text";
    var formData = FormData.fromMap({
      'image1': await MultipartFile.fromFile(paths[1], filename: 'Frame1'),
      'image2': await MultipartFile.fromFile(paths[2], filename: 'Frame2'),
      'image3': await MultipartFile.fromFile(paths[5], filename: 'Frame3'),
      'image4': await MultipartFile.fromFile(paths[9], filename: 'Frame9'),
    });

    return formData;
  }

  void getFrames() {
    var dir = Directory(
        "/data/data/com.aeologic.fluttervideorecorderapp/app_ExportImage");
    var files = dir.listSync().toList();
    files.forEach((element) {
      paths.add(element.path);
    });
  }

  void updateScreenwithResponse() {
    setState(() {
      is_responded = !is_responded;
    });
  }

  void sendRequest() async {
    _service == CURRENCY_CHOICE
        ? await _dio
            .post("http://blindassist.newtechhosting.net:5005/predict-currency",
                data: _formData)
            .then((value) => updateScreenwithResponse)
        : _service == COLOR_CHOICE
            ? response = await _dio
                .post("http://blindassist.newtechhosting.net:5005/detect-color",
                    data: _formData)
                .then((value) => updateScreenwithResponse)
            : response = await _dio
                .post("http://blindassist.newtechhosting.net:5005/detect-text",
                    data: _formData)
                .then((value) => updateScreenwithResponse);

    if (response.statusCode == 200)
      // then a valid response
      logger.finer("Uploaded");
    else {
      var snackbar =
          SnackBar(content: Text("Error: " + response.statusMessage));
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    }
  }
}
