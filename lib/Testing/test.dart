import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:circular_countdown/circular_countdown.dart';

void main() {
  runApp(
      MaterialApp(
        title: '',
        home: Scaffold(
          appBar: AppBar(
            title: Text('Example app'),
          ),
          body:Align(
            alignment: Alignment.bottomCenter,
            child: TestScreen(),
          ) ,
        ),
      )
  );
}

class TestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return
      Container(
      color: Colors.blue,
      child: Column(
        children: <Widget>[
          Align(
           // alignment: Alignment.bott,
            child: Material(
              color: Colors.orange,
              child:Center(
                child: InkWell (
                    child: TimeCircularCountdown(
                      unit: CountdownUnit.second,
                      countdownTotal: 10,
                      onUpdated: (unit, remaining) => print('updated'),
                      onFinished: () => print('finished'),
                    )
                ),
              )
            ),
          )
        ],
      ),
    );
  }
}
