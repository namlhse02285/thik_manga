import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as PathProvider;
import 'package:permission_handler/permission_handler.dart';

import 'com_cons.dart';

class MyStorage{
  static const String APP_SAVE_DIR = "hive";

  static void saveTest(String str) {
    PathProvider.getExternalStorageDirectories().then((listAppDir) {
      File allLinksFile = File("${listAppDir![0].path}/test.txt");
      allLinksFile.writeAsStringSync(str + "\n", mode: FileMode.writeOnly);
    });
  }

  static Future<void> init() async{
    List<Directory>? externalStorageDirectories = await PathProvider.getExternalStorageDirectories();
    if(externalStorageDirectories== null){
      throw("ExternalStorageDirectories was null!");
    }
    String appSaveDirFullPath= CommonFunc.buildPath([externalStorageDirectories[0].path, APP_SAVE_DIR]);
    Hive.init(appSaveDirFullPath);
    Hive.registerAdapter(SingleMangaAdapter());
    await Hive.openBox<String>(UserConfig.TABLE_CONFIG);
    await Hive.openBox<SingleManga>(ListManga.TABLE_LIST_MANGA);
    if (!await Permission.storage.request().isGranted) {
      await Permission.storage.request();
    }
  }

  static Future<String> getFirstFileFromDir(String dirPath) async {
    Completer<String> completer= new Completer();
    Directory(dirPath).list(recursive: true).toList().then((fileList) {
      fileList.sort((a, b) => a.path.compareTo(b.path));
      for(int i= 0; i< fileList.length; i++){
        if(!Directory(fileList[i].path).existsSync()){
          completer.complete(fileList[i].path);
          break;
        }
      }
    });
    return completer.future;
  }
}

class ListManga{
  static const String TABLE_LIST_MANGA = "list_manga";

  static int getCount(){
    Box<SingleManga> box= Hive.box<SingleManga>(ListManga.TABLE_LIST_MANGA);
    return box.length;
  }

  static void compact(){
    Hive.box<SingleManga>(ListManga.TABLE_LIST_MANGA).compact();
  }

  static void add(SingleManga one){
    Box<SingleManga> box= Hive.box<SingleManga>(ListManga.TABLE_LIST_MANGA);
    one._index= UserConfig.getInt(UserConfig.LAST_LIST_MANGA_INDEX);
    UserConfig.saveInt(UserConfig.LAST_LIST_MANGA_INDEX, UserConfig.getInt(UserConfig.LAST_LIST_MANGA_INDEX)+ 1);
    box.put(one.name, one).whenComplete(() {
      box.compact();
    });
  }

  static SingleManga get(int index){
    List<SingleManga> ret= Hive.box<SingleManga>(ListManga.TABLE_LIST_MANGA).values.toList();
    ret.sort((a, b) => b._lastUpdate.compareTo(a._lastUpdate));
    return ret[index];
  }

  static Future<void> remove(String name) async {
    await Hive.box<SingleManga>(ListManga.TABLE_LIST_MANGA).delete(name);
    await Hive.box<SingleManga>(ListManga.TABLE_LIST_MANGA).compact();
  }

  static bool containName(String name){
    return Hive.box<SingleManga>(ListManga.TABLE_LIST_MANGA).get(name)!= null;
  }

  static Future<String> copy(String fromRootDir) async {
    Completer<String> copyComplete= Completer<String>();
    PathProvider.getExternalStorageDirectories().then((listAppDir) {
      Directory(fromRootDir).list().toList().then((listFile) {
        int fileCount= listFile.length;
        for(int i= 0; i< listFile.length; i++){
          String newPath= listAppDir![0].path + "/copy"
              + listFile[i].path.substring(Directory(fromRootDir).parent.path.length);
          if(!File(newPath).parent.existsSync()){
            File(newPath).parent.createSync(recursive: true);
          }
          File(listFile[i].path).copy(newPath).then((newFile) {
            fileCount--;
            if(fileCount<= 0){
              copyComplete.complete("");
            }
          });
        }
      });
    });
    return copyComplete.future;
  }
}
@HiveType(typeId : 1)
class SingleManga extends HiveObject{
  SingleManga();
  static Future<String> create(String name, String lDirPath) async {
    Completer<String> completer= Completer<String>();
    SingleManga newManga= SingleManga();
    newManga.name= name;
    newManga.rootDir= lDirPath;
    MyStorage.getFirstFileFromDir(newManga.rootDir).then((firstFile) {
      newManga.lastPath= firstFile;
      ListManga.add(newManga);
      newManga.updateDateTime().whenComplete(() {
        completer.complete("");
      });
    });
    return completer.future;
  }

  Future<void> update({String? newName, String? rootPath}) async {
    if(newName!= null){
      name= newName;
    }
    if(rootPath!= null){
      rootDir= rootPath;
      MyStorage.getFirstFileFromDir(rootDir).then((firstFile) {
        lastPath= firstFile;
      });
    }
    await updateDateTime();
  }

  Future<void> updateDateTime() {
    Completer<void> completer= Completer<void>();
    DateTime now = DateTime.now();
    String dateTimeString=
        "${now.year.toString().padLeft(4, '0')}/"
        "${now.month.toString().padLeft(2, '0')}/"
        "${now.day.toString().padLeft(2, '0')} "
        "${now.hour.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')}:"
        "${now.second.toString().padLeft(2, '0')}";
    _lastUpdate= dateTimeString;
    save().whenComplete(() {
      completer.complete(null);
    });
    return completer.future;
  }

  Future<String> getFirstChapImage(){
    Completer<String> completer= Completer<String>();
    MyStorage.getFirstFileFromDir(rootDir).then((firstFile) {
      completer.complete(firstFile);
    });
    return completer.future;
  }

  Future<String> getInfoStr(){
    Completer<String> completer= Completer<String>();
    String ret= name;
    Directory(rootDir).parent.list(recursive: false).toList().then((folderList) {
      folderList.sort((a, b) => a.path.compareTo(b.path));
      for(int i= 0; i< folderList.length; i++){
        if(folderList[i].path== rootDir){
          ret+= "\nChap: "+ (i+ 1).toString()+ " / "+ folderList.length.toString();
          break;
        }
      }
      Directory(rootDir).list(recursive: true).toList().then((fileList) {
        fileList.sort((a, b) => a.path.compareTo(b.path));
        for(int i= 0; i< fileList.length; i++){
          if(fileList[i].path== lastPath){
            ret+= " | Page: "+ (i+ 1).toString()+ " / "+ fileList.length.toString();
            break;
          }
        }
        ret+= "\n\n"+ lastPath;
        completer.complete(ret);
      });
    });
    return completer.future;
  }

  @HiveField(0)
  int _index= -1;

  @HiveField(1)
  String lastPath= "";

  @HiveField(2)
  String rootDir= "";

  @HiveField(3)
  String name= "";

  @HiveField(4)
  String _lastUpdate= "";

}
class SingleMangaAdapter extends TypeAdapter<SingleManga> {
  @override
  final int typeId = 1;

  @override
  SingleManga read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SingleManga()
      .._index = fields[0] as int
      ..lastPath = fields[1] as String
      ..rootDir = fields[2] as String
      ..name = fields[3] as String
      .._lastUpdate = fields[4] as String
    ;
  }

  @override
  void write(BinaryWriter writer, SingleManga obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj._index)
      ..writeByte(1)
      ..write(obj.lastPath)
      ..writeByte(2)
      ..write(obj.rootDir)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj._lastUpdate)
    ;
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SingleMangaAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}

class UserConfig{
  static const String TABLE_CONFIG = "config";

  static const String LAST_PICKED_FOLDER = "LAST_PICKED_FOLDER";
  static const String AUTO_DELAY = "AUTO_DELAY";
  static const String RUN_MODE = "RUN_MODE";
  static const String FILL_MODE = "FILL_MODE";
  static const String ORIENTATION = "ORIENTATION";
  static const String LAST_LIST_MANGA_INDEX = "LAST_LIST_MANGA_INDEX";
  static const String IS_READ_RIGHT_TO_LEFT = "IS_READ_RIGHT_TO_LEFT";
  static const String IS_USE_BROWSER = "IS_USE_BROWSER";
  static const String LAST_PROFILE_NAME = "LAST_PROFILE_NAME";

  static void _loadDefault(){
    Box<String> userConfigBox= Hive.box<String>(TABLE_CONFIG);
    userConfigBox.put(LAST_PICKED_FOLDER, "");
    userConfigBox.put(AUTO_DELAY, "4000");
    userConfigBox.put(RUN_MODE, "0");
    userConfigBox.put(FILL_MODE, "0");
    userConfigBox.put(ORIENTATION, "0");
    userConfigBox.put(LAST_LIST_MANGA_INDEX, "0");
    userConfigBox.put(IS_READ_RIGHT_TO_LEFT, "0");
    userConfigBox.put(IS_USE_BROWSER, "0");
    userConfigBox.put(LAST_PROFILE_NAME, "");
  }

  static void save(String propertyName, String value){
    Hive.box<String>(TABLE_CONFIG).put(propertyName, value).whenComplete(() {
      Hive.box<String>(TABLE_CONFIG).compact();
    });
  }

  static String get(String propertyName){
    Box<String> userConfigBox= Hive.box<String>(TABLE_CONFIG);
    if(userConfigBox.isEmpty){_loadDefault();}
    String? ret= Hive.box<String>(TABLE_CONFIG).get(propertyName);
    if(ret== null){
      _loadDefault();
    }
    return ret== null ? "" : ret;
  }

  static void saveDouble(String propertyName, double? value){
    Hive.box<String>(TABLE_CONFIG).put(propertyName, value== null ? "" : value.toString()).whenComplete(() {
      Hive.box<String>(TABLE_CONFIG).compact();
    });
  }
  static double getDouble(String propertyName){
    String value= get(propertyName);
    return value.length== 0 ? 0 : double.tryParse(value)!;
  }

  static void saveInt(String propertyName, int? value){
    Hive.box<String>(TABLE_CONFIG).put(propertyName, value== null ? "" : value.toString()).whenComplete(() {
      Hive.box<String>(TABLE_CONFIG).compact();
    });
  }
  static int getInt(String propertyName){
    String value= get(propertyName);
    return value.length== 0 ? 0 : double.tryParse(value)!.toInt();
  }

  static void saveBool(String propertyName, bool? value){
    Hive.box<String>(TABLE_CONFIG).put(propertyName, value== null || !value ? "0" : "1").whenComplete(() {
      Hive.box<String>(TABLE_CONFIG).compact();
    });
  }
  static bool getBool(String propertyName){
    return get(propertyName)== "1";
  }

  static ValueListenable getListener(String? key){
    if(key== null){
      return Hive.box<String>(TABLE_CONFIG).listenable();
    }
    return Hive.box<String>(TABLE_CONFIG).listenable(keys: <String>[]..add(key));
  }
}