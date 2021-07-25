import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_video_recorder_app/constant/Constant.dart';
import 'package:flutter_video_recorder_app/utility/ScreenArgument.dart';
import 'package:flutter_video_recorder_app/utility/Text_to_speech.dart';
import 'package:flutter_video_recorder_app/utility/speechtotext.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';

class UserInputScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return UserInputState();
  }
}

class UserInputState extends State<UserInputScreen> {
  // response from speech to text
  bool recognizing = false;
  bool button_enabled = false;

  // Currency , Color , OCR chosen service indicator
  var list = [false, false, false];

  AudioRecognize audioRecognize = AudioRecognize(USER_INPUT_SCREEN);
  final String voice_name = "ar-XA-Standard-D";


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // play welcome audio and then enabling button for input from user
    // delete video recorded

    clear_cache();

    deleteFile();

    var framesDeleted = deleteDirectory(
        "/data/data/com.aeologic.fluttervideorecorderapp/app_ExportImage");
    if (framesDeleted)
      print(
          "Disposing ResultScreen : video recorded and the exported frames are deleted");

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      init();
    });
  }

  bool deleteDirectory(String dirpath) {
    final dir = Directory(dirpath);
    bool exists = dir.existsSync();
    if (exists) {
      dir.deleteSync(recursive: true);
      return true;
    }
    return false;
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    print('path $path');
    return File('$path/Videos/recorded.mp4');
  }

  Future<int> deleteFile() async {
    try {
      final file = await _localFile;

      await file.delete();
      return 1;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Input Screen

    return Scaffold(
        appBar: AppBar(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(30),
              )),
          leading: Padding(
              padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
              child: FittedBox(
                child: Image.asset('assets/images/eye.png',
                    fit: BoxFit.cover),
                alignment: Alignment.center,
              )),
          centerTitle: true,
          title: Text(
            "The Eye",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.deepPurple,
        ),
        body: Container(
          decoration: BoxDecoration(color: Colors.white),
          child: Column(
            children: <Widget>[
              //home screen
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white),
                    width: MediaQuery
                        .of(context)
                        .size
                        .width,
                    height: (MediaQuery
                        .of(context)
                        .size
                        .height - 80) * 0.65,
                    child: HomeScreen(),
                  ),
                ),
              ),
              Expanded(
                  child: Container(
                      width: MediaQuery
                          .of(context)
                          .size
                          .width,
                      height: (MediaQuery
                          .of(context)
                          .size
                          .height - 80) * 0.35,
                      child: ElevatedButton(

                          style: ButtonStyle(
                              backgroundColor: button_enabled
                                  ? recognizing
                                  ? MaterialStateProperty.all(Colors.green)
                                  : MaterialStateProperty.all(Colors.blue)
                                  : MaterialStateProperty.all(Colors.grey)),
                          onPressed: button_enabled
                              ? recognizing
                              ? stop_recording
                              : record_audio
                              : null,
                          child: Icon(
                            recognizing ? Icons.mic_none : Icons.mic,
                            color: Colors.white,
                            size: 50,
                          ))))
            ],
          ),
        ));
  }

  void record_audio() {
    //Start mic streaming and play audio of chosen choice just after Stream closed
    audioRecognize.streamingRecognize();
    setState(() {
      recognizing = true;
    });
  }

  String getChoice_audio_path(String responsetext) {
    return responsetext == 'العمله.'
        ? CURRENCY_CHOICE
        : responsetext == 'اللون.'
        ? COLOR_CHOICE
        : responsetext == 'مساعده.'
        ? HELP_COMMAND
        : responsetext == 'فحص الكلام.' ? OCR_CHOICE : '';
  }

  Future play_instructions() async {
    play_audio(CURRENCY_HELP_COMMAND);
    Future.delayed(Duration(seconds: 4), () {
      play_audio(COLOR_HELP_COMMAND);
    });
    Future.delayed(Duration(seconds: 8), () {
      play_audio(OCR_HELP_COMMAND);
    });
    Future.delayed(Duration(seconds: 12), () {
      play_audio(BELL_INSTRUCTIONS);
    });
  }

  Future play_audio(String path) async {
    AudioCache audioCache = AudioCache();
    await audioCache.play('$path');
  }

  void stop_recording() async {
    await audioRecognize.stopRecording();
    setState(() {
      recognizing = false;
    });

    // informing user with the chosen service
    String text = audioRecognize.getText();
    String path = getChoice_audio_path(text);

    if (path == '') {
      var snackbar = SnackBar(content: Text("لم أسمع"),);
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
      await play_audio(WAVENET);
      return;
    }

    // mark chosen service
    path == CURRENCY_CHOICE ? list[0] = true : path == COLOR_CHOICE ?
    list[1] = true : path == OCR_CHOICE ? list[2] = true : null;

    // help command >> play instructions else play service choice and navigate
    if (path == HELP_COMMAND) {
      await startTimer(0, () {
        setState(() {
          button_enabled = false;
        });
      });

      await play_instructions();

      await startTimer(16, () {
        setState(() {
          button_enabled = true;
        });
      });
    }
    else
      await play_audio(path);

    if (path != HELP_COMMAND && path != '') {
      ScreenArgument choice = check_marked_service();
      navigatetoVideoScreen(choice);
    } else {
      // do nothing
    }
  }

  void synthesizeText(String text, String name) async {
    final String audioContent =
    await TextToSpeechAPI().synthesizeText(text, name, "ar-XA");
    if (audioContent == null) return;
    final bytes = Base64Decoder().convert(audioContent, 0, audioContent.length);
    final dir = await getTemporaryDirectory(); // to be modified

    final file = File('${dir.path}/result_speech.mp3'); // to be modified
    await file.writeAsBytes(bytes);

    var snackbar = SnackBar(content: Text(file.path),);
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
    await play_audio(file.path);
  }

  ScreenArgument check_marked_service() {
    // check marked service and return constant indicator related to it
    if (list[0])
      return ScreenArgument(CURRENCY_CHOICE, "");
    else if (list[1])
      return ScreenArgument(COLOR_CHOICE, "");
    else if (list[2])
      return ScreenArgument(OCR_CHOICE, "");
    else {
      var snack = SnackBar(
          content: Text("(Screen Argument) Error service Choice"));
      ScaffoldMessenger.of(context).showSnackBar(snack);
      return ScreenArgument("", "");
    }
  }

  // be used after receiving text transcribed from server (Speech to text)
  Future navigatetoVideoScreen(ScreenArgument choice) async {
    await Navigator.of(context).pushNamed(CAMERA_SCREEN, arguments: choice);
  }

  void init() async {
    var args = ModalRoute
        .of(context)
        .settings
        .arguments as ScreenArgument;
    if (args != null)
      // message passed from result screen
      // then run instructions for repetition
      await startspeech();
    else
      await start_welcome();
  }

  Future start_welcome() async {
    // play welcome audio
    // setState with enabling button
    await play_audio(WELCOME);

    Future.delayed(Duration(seconds: 7), () {
      play_audio(MIC_INSTRUCTIONS);
    });

    startTimer(
        13,
            () =>
            setState(() {
              button_enabled = true;
            }));
  }

  Future startspeech() async {
    startTimer(0, () {
      setState(() {
        button_enabled = false;
      });
    });
    await play_instructions();

    startTimer(12, () {
      setState(() {
        button_enabled = true;
      });
    });
  }

  Future<void> _deleteCacheDir() async {
    final cacheDir = await getTemporaryDirectory();

    if (cacheDir.existsSync()) {
      cacheDir.deleteSync(recursive: true);
      print("[UserInputScreen] Application cache deleted");
    }
  }

  void clear_cache() async {
    await _deleteCacheDir();
  }

}


Future<Timer> startTimer(var duration, void Function() handle) async {
  return Timer(Duration(seconds: duration), handle);
}


class HomeScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomeScreen_state();
  }
}

class HomeScreen_state extends State<HomeScreen> {
  // play welcome audio
  @override
  Widget build(BuildContext context) {
    // Home Screen holds Presenting Services
    return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: Colors.white60,
            boxShadow: [new BoxShadow(blurRadius: 80.0)]),
        child: ListView(
          padding: EdgeInsets.all(10),
          children: <Widget>[
            Container(
                width: 50,
                height: 80,
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.all(Radius.elliptical(15.0, 15.0))),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 10,
                            child: FaIcon(
                              FontAwesomeIcons.moneyBill,
                              color: Colors.blue,
                              size: 30,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 30.0, top: 8.0),
                          child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SizedBox(
                                width: 200,
                                height: 40,
                                child: Text(
                                  "تحديد مختلف العملات المصرية",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textDirection: TextDirection.ltr,

                                ),
                              )),
                        ),
                      ]),
                )),
            Container(
              width: 50,
              height: 80,
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.all(Radius.elliptical(15.0, 15.0))),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 10,
                          child: FaIcon(
                            FontAwesomeIcons.palette,
                            color: Colors.blue,
                            size: 30,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 25.0, top: 8.0),
                        child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SizedBox(
                              width: 200,
                              height: 30,
                              child: Text(
                                "تحديد اللون",
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textDirection: TextDirection.ltr,

                              ),
                            )),
                      ),
                    ]),
              ),
            ),
            Container(
              width: 50,
              height: 80,
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.all(Radius.elliptical(15.0, 15.0))),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 10,
                          child: FaIcon(
                            FontAwesomeIcons.fileCode,
                            color: Colors.blue,
                            size: 30,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 25.0, top: 8.0),
                        child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SizedBox(
                              width: 200,
                              height: 30,
                              child: Text(
                                "استخراج الكلام من الصور",
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textDirection: TextDirection.ltr,

                              ),
                            )),
                      ),
                    ]),
              ),
            ),
            Container(
              width: 50,
              height: 80,
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.all(Radius.elliptical(15.0, 15.0))),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 10,
                          child: FaIcon(
                            FontAwesomeIcons.lightbulb,
                            color: Colors.yellow,
                            size: 30,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0, top: 8.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Column(children: [
                            SizedBox(
                              height: 30,
                              width: 220,
                              child: Center(
                                child: Text(
                                  "يرن الجرس عند بدء التسجيل",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textDirection: TextDirection.ltr,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 60,
                              width: 220,
                              child: Center(
                                child: Text(
                                  "إضغظ في اسفل الشاشة عند بدء التسجيل",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textDirection: TextDirection.ltr,
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ]),
              ),
            )
          ],
        ));
  }

  @override
  void initState() {
    super.initState();
  }
}


