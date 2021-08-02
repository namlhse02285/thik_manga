import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:thik_manga/storage_helper.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as FilePath;
import 'package:fluttertoast/fluttertoast.dart' as FToast;

import 'com_cons.dart';
import 'widget_helper.dart';

class MangaReader extends StatefulWidget {
  static final int READ_MODE_VIEW= 0;
  static final int READ_MODE_AUTO= 1;

  MangaReader({Key? key, required this.singleManga, required this.readMode}) : super(key: key);
  final SingleManga singleManga;
  final int readMode;

  @override
  _MangaReaderState createState() => _MangaReaderState();
}

class _MangaReaderState extends State<MangaReader> {
  VideoPlayerController? _videoController;
  late List<FileSystemEntity> _listChapter;
  late List<FileSystemEntity> _listImage;
  late int _chapterIndex;
  late int _imageIndex;
  Widget _imageInside= Container();
  ValueNotifier<bool> _imageChanged= ValueNotifier<bool>(true);
  InAppWebViewController? _webViewController;
  late FToast.FToast _fToast;

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIOverlays([]);
    if(UserConfig.getInt(UserConfig.ORIENTATION)== 1){
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }else if(UserConfig.getInt(UserConfig.ORIENTATION)== 2){
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }else if(UserConfig.getInt(UserConfig.ORIENTATION)== 0){
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    _listChapter= Directory(widget.singleManga.rootDir).parent.listSync(recursive: false)
      ..sort((a, b) => a.path.compareTo(b.path));
    _listImage= Directory(widget.singleManga.rootDir).listSync(recursive: true)
      ..sort((a, b) => a.path.compareTo(b.path));
    for(int i= 0; i< _listChapter.length; i++){
      if(_listChapter[i].path== widget.singleManga.rootDir){
        _chapterIndex= i;
        break;
      }
    }
    for(int i= 0; i< _listImage.length; i++){
      if(_listImage[i].path== widget.singleManga.lastPath){
        _imageIndex= i;
        break;
      }
    }
    super.initState();
    _fToast= FToast.FToast();
    _fToast.init(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _switchImage(toast: false);
  }

  void _switchChapter({int? delta, int? chapter}){
    if(delta!= null){
      if(_chapterIndex+ delta< _listChapter.length){
        if(_chapterIndex+ delta>= 0){
          _chapterIndex+= delta;
        }else{
          _chapterIndex= _listChapter.length- 1;
        }
      }else{
        _chapterIndex= 0;
      }
    } else if(chapter!= null){
      _chapterIndex= chapter< _listChapter.length && chapter>= 0 ? chapter : 0;
    }

    widget.singleManga.rootDir= _listChapter[_chapterIndex].path;
    _listImage= Directory(widget.singleManga.rootDir).listSync(recursive: true)
      ..sort((a, b) => a.path.compareTo(b.path));
    _switchImage(toast: false, page: 0);

    String msg= "Chap: "+ (_chapterIndex+ 1).toString() + " / " + _listChapter.length.toString();
    _fToast.removeCustomToast();
    _fToast.removeQueuedCustomToasts();
    _fToast.showToast(child: WidgetHelper.simpleToastWidget(msg));
  }

  void _switchImage({int? delta, int? page, bool toast= true}){
    if(delta!= null){
      if(_imageIndex+ delta< _listImage.length){
        if(_imageIndex+ delta>= 0){
          _imageIndex+= delta;
        }else{
          _imageIndex= _listImage.length- 1;
        }
      }else{
        _imageIndex= 0;
      }
    } else if(page!= null){
      _imageIndex= page< _listImage.length && page>= 0 ? page : 0;
    }

    widget.singleManga.lastPath= _listImage[_imageIndex].path;
    if(UserConfig.getBool(UserConfig.IS_USE_BROWSER)){
      if(_webViewController== null){
        _imageInside= InAppWebView(
          initialUrlRequest: URLRequest(url: Uri.parse("file://"+ widget.singleManga.lastPath)),
          onWebViewCreated: (controller) {
            _webViewController = controller;
          },
          initialOptions: InAppWebViewGroupOptions(
            crossPlatform: InAppWebViewOptions(
              allowUniversalAccessFromFileURLs: true,
            ),
            android: AndroidInAppWebViewOptions(
              loadsImagesAutomatically: true,
              allowContentAccess: true,
              allowFileAccess: true,
            ),
          ),
        );
      }else{
        _webViewController!.loadUrl(urlRequest: URLRequest(url: Uri.parse("file://"+ widget.singleManga.lastPath)));
      }
      handlePostImageChange(toast);
      return;
    }
    if(CommonFunc.pathIsVideo(widget.singleManga.lastPath)){
      if(_videoController!= null ){
        _imageInside= Container();
        _imageChanged.value= !_imageChanged.value;
        Future.delayed(Duration(milliseconds: 100)).whenComplete(() {
          _videoController!.pause().whenComplete(() {
            _videoController!.dispose().whenComplete(() {
              _playVideo();
            });
          });
        });
      }else{
        _playVideo();
      }
      handlePostImageChange(toast);
      return;
    }
    if(UserConfig.getInt(UserConfig.FILL_MODE)== 1){
      _imageInside= PhotoView(
        imageProvider: FileImage(File(widget.singleManga.lastPath),),
        backgroundDecoration: BoxDecoration(color: Colors.white),
        basePosition: Alignment.center,
        initialScale: PhotoViewComputedScale.contained,
        minScale: PhotoViewComputedScale.contained,
        enableRotation: false,
      );
    }else if(UserConfig.getInt(UserConfig.FILL_MODE)== 2){
      _imageInside= PhotoView(
        key: GlobalKey(),
        imageProvider: FileImage(File(widget.singleManga.lastPath),),
        backgroundDecoration: BoxDecoration(color: Colors.white),
        basePosition: Alignment.topCenter,
        initialScale: PhotoViewComputedScale.covered,
        minScale: PhotoViewComputedScale.covered,
        enableRotation: false,
      );
    }else if(UserConfig.getInt(UserConfig.FILL_MODE)== 0){
      _imageInside= OrientationBuilder(
        builder: (context, orientation) {
          if(orientation == Orientation.portrait){
            return PhotoView(
              imageProvider: FileImage(File(widget.singleManga.lastPath),),
              backgroundDecoration: BoxDecoration(color: Colors.white),
              basePosition: Alignment.center,
              initialScale: PhotoViewComputedScale.contained,
              minScale: PhotoViewComputedScale.contained,
              enableRotation: false,
            );
          }else{
            return PhotoView(
              key: GlobalKey(),
              imageProvider: FileImage(File(widget.singleManga.lastPath),),
              backgroundDecoration: BoxDecoration(color: Colors.white),
              basePosition: Alignment.topCenter,
              initialScale: PhotoViewComputedScale.covered,
              minScale: PhotoViewComputedScale.covered,
              enableRotation: false,
            );
          }
        },
      );
    }
    precacheImage(FileImage(File(widget.singleManga.lastPath)), context).whenComplete(() {
      _imageChanged.value= !_imageChanged.value;
    });
    handlePostImageChange(toast);
  }

  void handlePostImageChange(bool toast) {
    if(toast){
      String msg= "Page: "+ (_imageIndex+ 1).toString() + " / " + _listImage.length.toString();
      _fToast.removeCustomToast();
      _fToast.removeQueuedCustomToasts();
      _fToast.showToast(child: WidgetHelper.simpleToastWidget(msg));
    }
    if(widget.readMode== MangaReader.READ_MODE_AUTO){
      final String currentProcessImage= "$_chapterIndex-$_imageIndex";
      Future.delayed(Duration(milliseconds: UserConfig.getInt(UserConfig.AUTO_DELAY))).whenComplete(() {
        if(currentProcessImage== "$_chapterIndex-$_imageIndex"){
          _switchImage(delta: 1);
        }
      });
    }
  }

  void _playVideo(){
    _videoController= VideoPlayerController.file(File(widget.singleManga.lastPath));
    _videoController!.setLooping(true);
    _videoController!.initialize().whenComplete(() {
      _imageInside= AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
      _imageChanged.value= !_imageChanged.value;
      _videoController!.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Stack(
        children: [
          ValueListenableBuilder(
            valueListenable: _imageChanged,
            builder: (context, value, child) {
              return Center(child: _imageInside);
            },
          ),
          Row(
            children: [
              SizedBox(
                width: 70,
                child: Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: (){
                          _switchImage(delta: UserConfig.getBool(UserConfig.IS_READ_RIGHT_TO_LEFT) ?  1 : -1);
                        },
                        onLongPress: (){
                          showDialog(
                            context: context,
                            builder: (lContext) {
                              double fontSize= 15;
                              ValueNotifier<int> jumpToIndex= ValueNotifier<int>(_imageIndex);
                              Function(int) deltaChangeIndex= (delta){
                                jumpToIndex.value+= delta;
                                if(jumpToIndex.value >= _listImage.length || jumpToIndex.value < 0){
                                  jumpToIndex.value= 0;
                                }
                              };
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: EdgeInsets.only(left: 30, right: 30),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      WidgetHelper.getCommonButton(
                                        "-100", (){deltaChangeIndex(-100);}, fontSize: fontSize),
                                      WidgetHelper.getCommonButton(
                                        "-10", (){deltaChangeIndex(-10);}, fontSize: fontSize),
                                      WidgetHelper.getCommonButton(
                                        "-1", (){deltaChangeIndex(-1);}, fontSize: fontSize),
                                      ValueListenableBuilder(valueListenable: jumpToIndex, builder: (context, value, child) {
                                        return WidgetHelper.getCommonButton(
                                            "${(value as int)+ 1}/${_listImage.length}: ${FilePath.basename(_listImage[value].path)}", () {
                                          _switchImage(page: value);
                                          Navigator.pop(lContext);
                                        }, highLight: true, fontSize: 15);
                                      },),
                                      WidgetHelper.getCommonButton(
                                        "+1", (){deltaChangeIndex(1);}, fontSize: fontSize),
                                      WidgetHelper.getCommonButton(
                                        "+10", (){deltaChangeIndex(10);}, fontSize: fontSize),
                                      WidgetHelper.getCommonButton(
                                        "+100", (){deltaChangeIndex(100);}, fontSize: fontSize),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      height: 70,
                      child: GestureDetector(
                        onTap: (){
                          _switchChapter(delta: UserConfig.getBool(UserConfig.IS_READ_RIGHT_TO_LEFT) ?  1 : -1);
                        },
                        onLongPress: (){
                          showDialog(
                            context: context,
                            builder: (lContext) {
                              double fontSize= 15;
                              ValueNotifier<int> jumpToIndex= ValueNotifier<int>(_chapterIndex);
                              Function(int) deltaChangeIndex= (delta){
                                jumpToIndex.value+= delta;
                                if(jumpToIndex.value >= _listChapter.length || jumpToIndex.value < 0){
                                  jumpToIndex.value= 0;
                                }
                              };
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: EdgeInsets.only(left: 30, right: 30),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      WidgetHelper.getCommonButton(
                                          "-100", (){deltaChangeIndex(-100);}, fontSize: fontSize),
                                      WidgetHelper.getCommonButton(
                                          "-10", (){deltaChangeIndex(-10);}, fontSize: fontSize),
                                      WidgetHelper.getCommonButton(
                                          "-1", (){deltaChangeIndex(-1);}, fontSize: fontSize),
                                      ValueListenableBuilder(valueListenable: jumpToIndex, builder: (context, value, child) {
                                        return WidgetHelper.getCommonButton(
                                            "${(value as int)+ 1}/${_listChapter.length}: ${FilePath.basename(_listChapter[value].path)}", () {
                                          _switchImage(page: value);
                                          Navigator.pop(lContext);
                                        }, highLight: true, fontSize: 15);
                                      },),
                                      WidgetHelper.getCommonButton(
                                          "+1", (){deltaChangeIndex(1);}, fontSize: fontSize),
                                      WidgetHelper.getCommonButton(
                                          "+10", (){deltaChangeIndex(10);}, fontSize: fontSize),
                                      WidgetHelper.getCommonButton(
                                          "+100", (){deltaChangeIndex(100);}, fontSize: fontSize),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Spacer(),
                    SizedBox(
                      height: 70,
                      child: GestureDetector(
                        onTap: (){
                          ListManga.compact();
                          if(_videoController!= null){
                            _imageInside= Container();
                            _imageChanged.value= !_imageChanged.value;
                            Future.delayed(Duration(milliseconds: 100)).whenComplete(() {
                              _videoController!.dispose().whenComplete(() {
                                Navigator.pop(context);
                              });
                            });
                          }else{
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 70,
                child: Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: (){
                          _switchImage(delta: UserConfig.getBool(UserConfig.IS_READ_RIGHT_TO_LEFT) ?  -1 : 1);
                        },
                        onLongPress: (){
                          _switchImage(delta: UserConfig.getBool(UserConfig.IS_READ_RIGHT_TO_LEFT) ? -10 : 10);
                        },
                      ),
                    ),
                    SizedBox(
                      height: 70,
                      child: GestureDetector(
                        onTap: (){
                          _switchChapter(delta: UserConfig.getBool(UserConfig.IS_READ_RIGHT_TO_LEFT) ?  -1 : 1);
                        },
                        onLongPress: (){
                          _switchChapter(delta: UserConfig.getBool(UserConfig.IS_READ_RIGHT_TO_LEFT) ? -10 : 10);
                        },
                      ),
                    ),

                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

