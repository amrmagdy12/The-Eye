import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_video_recorder_app/constant/Constant.dart';
import 'package:flutter_video_recorder_app/generated/i18n.dart';
import 'package:flutter_video_recorder_app/screen/UserInputScreen.dart';
import 'package:logging/logging.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_video_recorder_app/utility/ScreenArgument.dart';
import 'package:flutter_video_recorder_app/utility/Text_to_speech.dart';
import 'package:path_provider/path_provider.dart';

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
  Response response;

  //Result Screen logger
  var logger = new Logger("[ResultScreen]");

  //argument passed
  var args;

  //message passed (chosen service)
  String _service;

  _ResultScreenState();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() async {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Result Screen
    getFrames();

    args = ModalRoute.of(context).settings.arguments as ScreenArgument;

    _service = args.title;

    initialize();

    return Scaffold(
      appBar: null,
      body: Padding(
        padding: EdgeInsets.all(50.0),
        child: Center(
          child: Container(
              height: double.infinity,
              width: double.infinity,
              child: FutureBuilder<int>(
                  future: sendRequest(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData) {
                      // text to speech response to the user
                      return ResponseScreen(_service, snapshot, response);
                    } else {
                      if (snapshot.hasError && response != null) {
                        print(response.statusMessage);
                        return Container();
                      }
                      return Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: Colors.white70, width: 1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: EdgeInsets.only(top: 60.0, left: 60.0),
                            child: Align(
                                alignment: Alignment.center,
                                child: Column(children: [
                                  CircularProgressIndicator(
                                    value: null,
                                    strokeWidth: 6.0,
                                  ),
                                  Padding(
                                      padding: EdgeInsets.only(top: 10),
                                      child: Center(
                                        child: Text(
                                          "برجاء الانتظار",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15.0),
                                        ),
                                      )),
                                ])),
                          ),
                        ),
                      );
                    }
                  })),
        ),
      ),
    );
  }

  void initialize() async {
    await initRequest();
  }

  Future initRequest() async {
    _service == CURRENCY_CHOICE
        ? _dio.options.baseUrl =
            "http://blindassist.newtechhosting.net:5005/predict-currency"
        : _service == COLOR_CHOICE
            ? _dio.options.baseUrl =
                "http://blindassist.newtechhosting.net:5005/detect-color"
            : _dio.options.baseUrl =
                "http://blindassist.newtechhosting.net:5005/detect-text";
  }

  void getFrames() async {
    var dir = Directory(
        "/data/data/com.aeologic.fluttervideorecorderapp/app_ExportImage");
    var files = dir.listSync().toList();

    files.forEach((element) {
      paths.add(element.path);
    });
  }

  Future<int> sendRequest() async {
    _formData = FormData.fromMap({
      'image1': await MultipartFile.fromFile(paths[1], filename: 'Frame2'),
      'image2': await MultipartFile.fromFile(paths[2], filename: 'Frame3'),
      'image3': await MultipartFile.fromFile(paths[3], filename: 'Frame4'),
      'image4': await MultipartFile.fromFile(paths[4], filename: 'Frame5'),
    });

    _service == CURRENCY_CHOICE
        ? response = await _dio.post(
            "http://blindassist.newtechhosting.net:5005/predict-currency",
            data: _formData)
        : _service == COLOR_CHOICE
            ? response = await _dio.post(
                "http://blindassist.newtechhosting.net:5005/detect-color",
                data: _formData)
            : response = await _dio.post(
                "http://blindassist.newtechhosting.net:5005/detect-text",
                data: _formData);

    return (response.statusCode);
  }
}

class ResponseScreen extends StatefulWidget {
  final String service;

  var snapshot;
  final Response response;

  ResponseScreen(this.service, this.snapshot, this.response);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return ResponseState();
  }
}

class ResponseState extends State<ResponseScreen> {
  final String voice_arabic = "ar-XA-Standard-D";
  final String voice_english = "en-US-Standard-F";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await say_response();
      var arg = ScreenArgument("Result Screen", "passed");

      if (widget.service != OCR_CHOICE) {
        Future.delayed(Duration(seconds: 3), () {
          navigatetoInputScreen(arg);
        });
      } else {
        print("words number :" + widget.response.data["words"].toString());
        double numwords = (widget.response.data["words"] * 0.5);

        Future.delayed(Duration(seconds: numwords.toInt()), () {
          navigatetoInputScreen(arg);
        });
      }
    });
  }

  Future play_audio(String path) async {
    await AudioPlayer().play(path, isLocal: true);
  }

  Future navigatetoInputScreen(ScreenArgument arg) async {
    await Navigator.of(context)
        .pushReplacementNamed(USER_INPUT_SCREEN, arguments: arg);
  }

  Future synthesizeText(String text, String name) async {
    final String audioContent = await TextToSpeechAPI().synthesizeText(
        text,
        name == "en" ? voice_english : voice_arabic,
        name == 'en' ? "en-US" : "ar-XA");
    if (audioContent == null) return;
    final bytes = Base64Decoder().convert(audioContent, 0, audioContent.length);
    final dir = await getTemporaryDirectory(); // to be modified

    final file = File('${dir.path}/result_speech.mp3'); // to be modified
    await file.writeAsBytes(bytes);

    await play_audio(file.path);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    // add post method after build method

    return Align(
      alignment: Alignment.center,
      child: Card(
        elevation: 5,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: <Widget>[
            ListTile(
              leading: widget.service == CURRENCY_CHOICE
                  ? FaIcon(FontAwesomeIcons.moneyBillWave)
                  : widget.service == COLOR_CHOICE
                      ? FaIcon(FontAwesomeIcons.palette)
                      : FaIcon(FontAwesomeIcons.fileCode),
              title: widget.service == CURRENCY_CHOICE
                  ? Text(
                      "Currency",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    )
                  : widget.service == COLOR_CHOICE
                      ? Text(
                          "Color",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        )
                      : Text(
                          "Text Extraction",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
            ),
            widget.service == CURRENCY_CHOICE
                ? Image.asset("assets/images/currency_image.jpg")
                : widget.service == COLOR_CHOICE
                    ? Image.asset("assets/images/color_image.jpg")
                    : Image.asset("assets/images/ocr_image.jpg"),
            Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: SingleChildScrollView(
                  child: widget.snapshot.data == 200
                      ? widget.service == CURRENCY_CHOICE
                          ? Text(widget.response.data["value"])
                          : widget.service == COLOR_CHOICE
                              ? Text(widget.response.data["color"],
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15))
                              : Text(widget.response.data["extracted"],
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15))
                      : Text("[API Error] " + widget.response.statusMessage,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15))),
            )
          ],
        ),
      ),
    );
  }

  Future say_response() async {
    if (widget.snapshot.data != 200) return;

    widget.service == CURRENCY_CHOICE
        ? await synthesizeText(widget.response.data["value"], voice_arabic)
        : widget.service == COLOR_CHOICE
            ? await synthesizeText(widget.response.data["color"], voice_arabic)
            : await synthesizeText(widget.response.data["extracted"],
                widget.response.data["lang"]);
  }
}
