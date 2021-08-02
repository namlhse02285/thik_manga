import 'package:flutter/material.dart';

class WidgetHelper{
  static const TextStyle DEFAULT_TEXT_STYLE = TextStyle(
    color: Colors.black,
    fontSize: 20,
    height: 1.25,
  );

  static RichText simpleRichText(String txt, [TextStyle style= DEFAULT_TEXT_STYLE]){
    return RichText(text: TextSpan(style: style, text: txt));
  }

  static Widget simpleToastWidget(String msg){
    return Container(
      color: Colors.black54,
        child: RichText(text: TextSpan(style:
            DEFAULT_TEXT_STYLE.copyWith(color: Colors.white), text: msg)),
    );
  }

  static Widget getCommonButton(String txt, Function() onPress, {bool highLight= false, double fontSize= 12}) {
    return ElevatedButton(
      child: Text(txt,
        overflow: TextOverflow.fade,
        softWrap: true,
      ),
      style: ElevatedButton.styleFrom(
        primary: highLight ? Colors.lightBlueAccent : Colors.white,
        onPrimary: Colors.black,
        textStyle: TextStyle(
          fontSize: fontSize,
        ),
      ),
      onPressed: onPress,
    );
  }
}