import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart' as Hash;
import 'dart:math' as Math;
class AppConstant{

}
class CommonFunc {
  static bool pathIsVideo(String path){
    String processPath= path.toLowerCase();
    return processPath.endsWith(".webm")
        || processPath.endsWith(".mp4")
        || processPath.endsWith(".ts")
        || processPath.endsWith(".mkv")
    ;
  }
  static bool pathIsGif(String path){
    String processPath= path.toLowerCase();
    return processPath.endsWith(".gif")
    ;
  }

  static String buildPath(List<String> params){
    String? ret;
    bool lastParamEndWithSeparator= false;
    for(String aParam in params){
      if(ret== null){
        ret= aParam;
      }else{
        if(!lastParamEndWithSeparator){
          ret += Platform.pathSeparator;
        }
        ret += aParam;
      }
      lastParamEndWithSeparator= aParam.endsWith(Platform.pathSeparator);
    }

    return ret!;
  }

  static double getRotateValue(double rotateAngle){
    return rotateAngle  * Math.pi / 180;
  }
  static double getAngleValue(double rotate){
    return rotate  / Math.pi * 180;
  }

  static Future<bool> checkMd5File(String filePath, String toCheck1, String toCheck2) {
    Completer<bool> completer = new Completer<bool>();
    var file = File(filePath);
    if (file.existsSync()) {
      try {
        Hash.md5.bind(file.openRead()).first.then((value) {
          completer.complete(value.toString().toUpperCase()== (toCheck1+ toCheck2));
        });
      } catch (exception) {
        completer.complete(false);
      }
    } else {
      completer.complete(false);
    }
    return completer.future;
  }

  static Future<String> getMd5Hash(String filePath){
    Completer<String> completer = new Completer<String>();
    var file = File(filePath);
    if (file.existsSync()) {
      try {
        Hash.md5.bind(file.openRead()).first.then((value) {
          completer.complete(value.toString().toUpperCase());
        });
      } catch (exception) {
        completer.complete("");
      }
    } else {
      completer.complete("");
    }
    return completer.future;
  }
}
