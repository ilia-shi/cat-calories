import 'package:flutter/material.dart';

class CalculatorWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onPressed;

  const CalculatorWidget({
    Key? key,
    required this.controller,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Column(
      children: <Widget>[
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: _isPortrait ? 3 : 5,
          childAspectRatio: _isPortrait ? 2.5 : 4.0,
          children: <Widget>[
            CalculatorKeyWidget(Text('-', style: TextStyle(fontSize: 18.0)),
                () {
              controller.text += '-';
            }),
            CalculatorKeyWidget(Text('/', style: TextStyle(fontSize: 18.0)),
                () {
              controller.text += '/';
            }),
            CalculatorKeyWidget(Text('C', style: TextStyle(fontSize: 18.0)),
                () {
              controller.text = '';
            }),
            CalculatorKeyWidget(Text('+', style: TextStyle(fontSize: 18.0)),
                () {
              controller.text += '+';
            }),
            CalculatorKeyWidget(Text('*', style: TextStyle(fontSize: 18.0)),
                () {
              controller.text += '*';
            }),
            CalculatorKeyWidget(Icon(Icons.backspace), () {
              if (controller.text == null || controller.text.length == 0) {
                return;
              }

              controller.text =
                  controller.text.substring(0, controller.text.length - 1);
            }),
            CalculatorKeyWidget(Text('1', style: TextStyle(fontSize: 18.0)),
                () {
              controller.text += '1';
            }),
            CalculatorKeyWidget(Text('2', style: TextStyle(fontSize: 18.0)),
                () {
              controller.text += '2';
            }),
            CalculatorKeyWidget(Text('3', style: TextStyle(fontSize: 18.0)),
                () {
              controller.text += '3';
            }),
            CalculatorKeyWidget(Text('4', style: TextStyle(fontSize: 18.0)),
                () {
              controller.text += '4';
            }),
            CalculatorKeyWidget(Text('5', style: TextStyle(fontSize: 18.0)),
                () {
              controller.text += '5';
            }),
            CalculatorKeyWidget(Text('6', style: TextStyle(fontSize: 18.0)),
                () {
              controller.text += '6';
            }),
            CalculatorKeyWidget(Text('7', style: TextStyle(fontSize: 18.0)),
                () {
              controller.text += '7';
            }),
            CalculatorKeyWidget(Text('8', style: TextStyle(fontSize: 18.0)),
                () {
              controller.text += '8';
            }),
            CalculatorKeyWidget(Text('9', style: TextStyle(fontSize: 18.0)),
                () {
              controller.text += '9';
            }),
            CalculatorKeyWidget(Text('0', style: TextStyle(fontSize: 18.0)),
                () {
              controller.text += '0';
            }),
            CalculatorKeyWidget(Text('.', style: TextStyle(fontSize: 18.0)),
                () {
              controller.text += '.';
            }),
            CalculatorKeyWidget(Text('OK', style: TextStyle(fontSize: 18.0)),
                () {
              onPressed();
            }),
          ],
        ),
      ],
    );
  }
}

class CalculatorKeyWidget extends StatelessWidget {
  const CalculatorKeyWidget(this.child, this.onTap);

  final Widget child;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    return GridTile(
      child: InkResponse(
        child: Center(child: child),
        enableFeedback: true,
        onTap: () => onTap(),
      ),
    );
  }
}
