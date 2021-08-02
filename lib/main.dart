import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thik_manga/com_cons.dart';
import 'package:fluttertoast/fluttertoast.dart' as FToast;

import 'route_read.dart';
import 'storage_helper.dart';
import 'widget_helper.dart';

void main() {
  //Let device allow app to set Orientation
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).whenComplete(() {
    MyStorage.init().whenComplete(() {
      runApp(MyApp());
    });
  });
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Material(
        child: SafeArea(child: Config()),
      ),
    );
  }
}

class Config extends StatefulWidget {
  @override
  _ConfigState createState() => _ConfigState();
}

class _ConfigState extends State<Config> {
  FocusNode _focusNode = FocusNode();
  TextEditingController _textEditingController = TextEditingController(
      text: UserConfig.get(UserConfig.LAST_PROFILE_NAME));
  ScrollController _scrollController= ScrollController();

  void onRunModeChange(int? value){
    if(value!= null){
      UserConfig.saveInt(UserConfig.RUN_MODE, value);
    }
  }
  void onFillModeChange(int? value){
    if(value!= null){
      UserConfig.saveInt(UserConfig.FILL_MODE, value);
    }
  }
  void onOrientModeChange(int? value){
    if(value!= null){
      UserConfig.saveInt(UserConfig.ORIENTATION, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            ValueListenableBuilder(
              valueListenable: UserConfig.getListener(null),
              builder: (context, value, child) {
                return Column(
                  children: [
                    WidgetHelper.simpleRichText("Auto delay: "+ UserConfig.getDouble(UserConfig.AUTO_DELAY).toString()),
                    Slider(
                        min: 500,
                        max: 8000,
                        divisions: 100,
                        value: UserConfig.getDouble(UserConfig.AUTO_DELAY),
                        onChanged: (double newValue){
                          UserConfig.saveDouble(UserConfig.AUTO_DELAY, newValue);
                        }
                    ),
                    Row(
                      children: [
                        Checkbox(
                            value: UserConfig.getBool(UserConfig.IS_READ_RIGHT_TO_LEFT),
                            onChanged: (value){
                              UserConfig.saveBool(UserConfig.IS_READ_RIGHT_TO_LEFT, value);
                            }
                        ),
                        WidgetHelper.simpleRichText("Read right to left?"),
                      ],
                    ),
                    Row(
                      children: [
                        Checkbox(
                            value: UserConfig.getBool(UserConfig.IS_USE_BROWSER),
                            onChanged: (value){
                              UserConfig.saveBool(UserConfig.IS_USE_BROWSER, value);
                            }
                        ),
                        WidgetHelper.simpleRichText("Use browser?"),
                      ],
                    ),
                    Row(children: [
                      WidgetHelper.simpleRichText("Run mode: "),

                      Radio(
                        value: MangaReader.READ_MODE_VIEW,
                        groupValue: UserConfig.getInt(UserConfig.RUN_MODE),
                        onChanged: (int? value){
                          onRunModeChange(value);
                        },
                      ),
                      WidgetHelper.simpleRichText("View"),

                      Radio(
                        value: MangaReader.READ_MODE_AUTO,
                        groupValue: UserConfig.getInt(UserConfig.RUN_MODE),
                        onChanged: (int? value){
                          onRunModeChange(value);
                        },
                      ),
                      WidgetHelper.simpleRichText("Auto"),
                    ],),
                    Row(children: [
                      WidgetHelper.simpleRichText("Fill mode: "),

                      Radio(
                        value: 0,
                        groupValue: UserConfig.getInt(UserConfig.FILL_MODE),
                        onChanged: (int? value){
                          onFillModeChange(value);
                        },
                      ),
                      WidgetHelper.simpleRichText("Auto"),

                      Radio(
                        value: 1,
                        groupValue: UserConfig.getInt(UserConfig.FILL_MODE),
                        onChanged: (int? value){
                          onFillModeChange(value);
                        },
                      ),
                      WidgetHelper.simpleRichText("Fit"),

                      Radio(
                        value: 2,
                        groupValue: UserConfig.getInt(UserConfig.FILL_MODE),
                        onChanged: (int? value){
                          onFillModeChange(value);
                        },
                      ),
                      WidgetHelper.simpleRichText("Fill"),
                    ],),
                    Row(children: [
                      WidgetHelper.simpleRichText("Orient: "),

                      Radio(
                        value: 0,
                        groupValue: UserConfig.getInt(UserConfig.ORIENTATION),
                        onChanged: (int? value){
                          onOrientModeChange(value);
                        },
                      ),
                      WidgetHelper.simpleRichText("Auto"),

                      Radio(
                        value: 1,
                        groupValue: UserConfig.getInt(UserConfig.ORIENTATION),
                        onChanged: (int? value){
                          onOrientModeChange(value);
                        },
                      ),
                      WidgetHelper.simpleRichText("|"),

                      Radio(
                        value: 2,
                        groupValue: UserConfig.getInt(UserConfig.ORIENTATION),
                        onChanged: (int? value){
                          onOrientModeChange(value);
                        },
                      ),
                      WidgetHelper.simpleRichText("ー"),
                    ],),
                  ],
                );
              },
            ),
            Row(
              children: [
                ElevatedButton(
                  child: WidgetHelper.simpleRichText("Permission"),
                  onPressed: (){
                    FilePicker.platform.getDirectoryPath().then((dirPath) {
                      if(dirPath != null) {}
                    });
                  },
                ),
                ElevatedButton(
                  child: WidgetHelper.simpleRichText("Add"),
                  onPressed: (){
                    if(_textEditingController.text.length== 0
                        || ListManga.containName(_textEditingController.text)){
                      FToast.Fluttertoast.showToast(msg: "Name not available");
                    }else{
                      _focusNode.unfocus();
                      FilePicker.platform.getDirectoryPath().then((dirPath) {
                        if(dirPath != null) {
                          SingleManga.create(_textEditingController.text, dirPath).whenComplete(() {
                            setState(() {});
                          });
                        }
                      });
                    }
                  },
                ),
                SizedBox(
                  width: 150,
                  child: EditableText(
                    controller: _textEditingController,
                    focusNode: _focusNode,
                    style: WidgetHelper.DEFAULT_TEXT_STYLE,
                    cursorColor: Colors.green,
                    backgroundCursorColor: Colors.amber,
                    onChanged: (value) {
                      UserConfig.save(UserConfig.LAST_PROFILE_NAME, value);
                    },
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                itemExtent: 140,
                controller: _scrollController,
                itemCount: ListManga.getCount(),
                itemBuilder: (BuildContext context, int index) {
                  SingleManga singleManga= ListManga.get(index);
                  return Row(
                    children: [
                      GestureDetector(
                        onTap: (){
                          Navigator.push(context,
                            MaterialPageRoute(builder: (context) => MangaReader(
                              singleManga: singleManga,
                              readMode: UserConfig.getInt(UserConfig.RUN_MODE),
                            )),
                          ).whenComplete(() {
                            SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
                            SystemChrome.setPreferredOrientations([
                              DeviceOrientation.portraitUp,
                              DeviceOrientation.portraitDown,
                            ]);
                            singleManga.updateDateTime().whenComplete(() {
                              _scrollController.jumpTo(0);
                              setState(() {});
                            });
                          });
                        },
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            color: Colors.transparent,
                            child: FutureBuilder<String>(
                              future: singleManga.getFirstChapImage(),
                              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                                switch (snapshot.connectionState) {
                                  case ConnectionState.none: return Container();
                                  case ConnectionState.waiting: return Container();
                                  default:
                                    if (snapshot.hasError)
                                      return new Text('Error: ${snapshot.error}');
                                    else
                                      return CommonFunc.pathIsVideo(snapshot.data!)
                                          ? Center(child: Icon(Icons.video_collection_rounded))
                                          : Image(
                                        image: FileImage(File(snapshot.data!)),
                                        fit: BoxFit.contain,
                                      );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(color: Colors.transparent,),
                            if(!CommonFunc.pathIsVideo(singleManga.lastPath)) Image(
                              image: FileImage(File(singleManga.lastPath)),
                              fit: BoxFit.cover,
                            ),
                            Container(color: Colors.black54,),
                            FutureBuilder<String>(
                              future: singleManga.getInfoStr(),
                              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                                switch (snapshot.connectionState) {
                                  case ConnectionState.none: return Container();
                                  case ConnectionState.waiting: return Container();
                                  default:
                                    if (snapshot.hasError)
                                      return WidgetHelper.simpleRichText(snapshot.error.toString());
                                    else{
                                      final AlertDialog dialog = AlertDialog(
                                        title: Text("Profile: "+ singleManga.name),
                                        content: Wrap(
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                ListManga.copy(singleManga.rootDir).whenComplete(() {
                                                  showDialog<void>(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: Text("Copy done!"),
                                                    )
                                                  );
                                                });
                                              },
                                              child: WidgetHelper.simpleRichText("Copy"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                FilePicker.platform.getDirectoryPath().then((dirPath) {
                                                  if(dirPath != null) {
                                                    singleManga.update(rootPath: dirPath).whenComplete(() {
                                                      setState(() {});
                                                    });
                                                  }
                                                });
                                              },
                                              child: WidgetHelper.simpleRichText("Change path"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                ListManga.remove(singleManga.name).whenComplete(() {
                                                  setState(() {});
                                                });
                                              },
                                              child: WidgetHelper.simpleRichText("Delete"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                List<FileSystemEntity> listChapter = Directory(singleManga.rootDir).parent.listSync(recursive: false);
                                                String testContent= "";
                                                for(FileSystemEntity aDir in listChapter){
                                                  testContent+= "https://nhentai.net/g"+ aDir.path.substring(aDir.path.lastIndexOf("/")) + "\r\n";
                                                }
                                                MyStorage.saveTest(testContent);
                                                Navigator.pop(context);
                                              },
                                              child: WidgetHelper.simpleRichText("Test"),
                                            ),
                                          ],
                                        ),
                                        actions: [],
                                      );
                                      return GestureDetector(
                                        child: Container(
                                          color: Colors.transparent,
                                          child: WidgetHelper.simpleRichText(snapshot.data!,
                                              WidgetHelper.DEFAULT_TEXT_STYLE.copyWith(color: Colors.white, fontSize: 16)),
                                        ),
                                        onTap: (){
                                          showDialog<void>(context: context, builder: (context) => dialog);
                                        },
                                      );
                                    }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
