import 'dart:async';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:convert';

class downloadItem {
  String id;
  String title;
  String status;
  int size;
  int downloadsize;
  int speed;
  String path;
  String url;
  String type;
  int createdTime;
  int completedTime;
  int errorDetail;

  downloadItem(this.id, this.title, this.status, this.size, this.downloadsize, this.speed, this.path, this.url, this.type, this.createdTime, this.completedTime, this.errorDetail);
}

class DSM {
  String address = "";
  String sid = "";
  bool dsmIsmanager = false;
  int dsmVersion = 0;
  String dsmVersionString = "";
  bool isquickconnect = false;
  String qcport = '5001';

  int nowDownloadTotalSpeed = 0;
  int nowUploadTotalSpeed = 0;

  List<downloadItem> downloadinglist = [];
  List<downloadItem> finishedlist = [];
  int downloadingcount = 0;
  int finishcount = 0;

  Dio dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  DSM();
  DSM.fromAddress(String add) {
    address = add;
  }
  DSM.fromPort(String port) {
    qcport = port;
  }
  DSM.fromAddressAndPort(String add, String port) {
    address = add;
    qcport = port;
  }

  Future<List<Object>> login(String account, String passwd) async {
    try {
      var response = await dio.get(isquickconnect ? "$address:$qcport/webapi/auth.cgi" : "$address/webapi/auth.cgi", queryParameters: {
        "api": "SYNO.API.Auth",
        "version": "3",
        "method": "login",
        "account": account,
        "passwd": passwd,
        "session": "DownloadStation",
        "format": "sid",
      });
      //print full url
      //print(response.requestOptions.uri);

      if (response.data["success"] == true) {
        sid = response.data["data"]["sid"];
        checksid(sid);
        return [0, sid];
      } else {
        return [1, "帳號或密碼錯誤"];
      }
    } on DioError catch (_) {
      print(_);
      return [1, "錯誤的伺服器位址"];
    } on TimeoutException catch (_) {
      print(_);
      return [1, "連線逾時"];
    }
  }

  // /webapi/DownloadStation/info.cgi?api=SYNO.DownloadStation.Info&version=1&method=getinfo
  Future<int> checksid(String csid) async {
    try {
      var response = await dio.get(isquickconnect ? "$address:$qcport/webapi/DownloadStation/info.cgi" : "$address/webapi/DownloadStation/info.cgi", queryParameters: {"api": "SYNO.DownloadStation.Info", "version": "2", "method": "getinfo", "_sid": csid, "session": "dwm"});
      Map<String, dynamic> responseData = jsonDecode(response.data);

      if (responseData["success"] == true) {
        sid = csid;
        dsmIsmanager = responseData["data"]["is_manager"];
        dsmVersion = responseData["data"]["version"];
        dsmVersionString = responseData["data"]["version_string"];
        return 0;
      } else {
        print(responseData);
        return 1;
      }
    } on DioError catch (e) {
      print(e);
      if (e.response?.statusCode == 403) {}
      return 2;
    } on TimeoutException catch (e) {
      print(e);
      return 3;
    }
  }

  //get tasks
  // 192.168.50.50:5000/webapi/DownloadStation/task.cgi?api=SYNO.DownloadStation.Task&version=1&method=list&limit=-1&additional=detail&_sid=,file
  Future<List<Object>> gettasks() async {
    try {
      var response = await dio.get(isquickconnect ? "$address:$qcport/webapi/DownloadStation/task.cgi" : "$address/webapi/DownloadStation/task.cgi", queryParameters: {
        "api": "SYNO.DownloadStation.Task",
        "version": "3",
        "method": "list",
        "limit": "-1",
        "additional": "detail,file,transfer,peer,tracker",
        "_sid": sid,
        "session": "DownloadStation",
      });
      Map<String, dynamic> responseData = jsonDecode(response.data);

      if (responseData["success"] == true) {
        //update list
        downloadinglist.clear();
        finishedlist.clear();
        nowDownloadTotalSpeed = 0;
        for (var i = 0; i < responseData["data"]["tasks"].length; i++) {
          if (responseData["data"]["tasks"][i]["status"] == "downloading" || responseData["data"]["tasks"][i]["status"] == "waiting" || responseData["data"]["tasks"][i]["status"] == "paused") {
            downloadinglist.add(downloadItem(responseData["data"]["tasks"][i]['id'], responseData["data"]["tasks"][i]['title'], responseData["data"]["tasks"][i]['status'], responseData["data"]["tasks"][i]['size'], responseData["data"]["tasks"][i]['additional']['transfer']['size_downloaded'], responseData["data"]["tasks"][i]['additional']['transfer']['speed_download'],
                responseData["data"]["tasks"][i]['additional']['detail']['destination'], responseData["data"]["tasks"][i]['additional']['detail']['uri'], responseData["data"]["tasks"][i]['type'], responseData["data"]["tasks"][i]['additional']['detail']['create_time'], responseData["data"]["tasks"][i]['additional']['detail']['completed_time'], 0));
            if (responseData["data"]["tasks"][i]['additional']['transfer']['speed_download'] != null) {
              nowDownloadTotalSpeed += responseData["data"]["tasks"][i]['additional']['transfer']['speed_download'] as int;
            }
          } else {
            finishedlist.add(downloadItem(responseData["data"]["tasks"][i]['id'], responseData["data"]["tasks"][i]['title'], responseData["data"]["tasks"][i]['status'], responseData["data"]["tasks"][i]['size'], responseData["data"]["tasks"][i]['additional']['transfer']['size_downloaded'], responseData["data"]["tasks"][i]['additional']['transfer']['speed_download'],
                responseData["data"]["tasks"][i]['additional']['detail']['destination'], responseData["data"]["tasks"][i]['additional']['detail']['uri'], responseData["data"]["tasks"][i]['type'], responseData["data"]["tasks"][i]['additional']['detail']['create_time'], responseData["data"]["tasks"][i]['additional']['detail']['completed_time'], 0));
          }
        }
        downloadingcount = downloadinglist.length;
        finishcount = finishedlist.length;
        return [0, responseData["data"]["tasks"]];
      } else {
        return [1, "fail"];
      }
    } on DioError catch (e) {
      if (e.response?.statusCode == 403) {}
      return [2, "fail"];
    }
  }

  // /webapi/DownloadStation/task.cgi?api=SYNO.DownloadStation.Task&version=1&method=pause&id=dbid_001,dbid_00
  void taskPauseResume(downloadItem item) async {
    try {
      var response = await dio.get(isquickconnect ? "$address:$qcport/webapi/DownloadStation/task.cgi" : "$address/webapi/DownloadStation/task.cgi", queryParameters: {
        "api": "SYNO.DownloadStation.Task",
        "version": "1",
        "method": item.status == "paused" ? "resume" : "pause",
        "id": item.id,
        "_sid": sid,
        "session": "DownloadStation",
      });
      Map<String, dynamic> responseData = jsonDecode(response.data);
      if (responseData["success"] == true) {
        //update list
        gettasks();
      }
    } on DioError catch (e) {
      if (e.response?.statusCode == 403) {}
    }
  }

  // /webapi/DownloadStation/task.cgi?api=SYNO.DownloadStation.Task&version=1&method=delete&id=dbid_001,dbid_002&force_complete=true
  void taskDelete(downloadItem item) async {
    try {
      var response = await dio.get(isquickconnect ? "$address:$qcport/webapi/DownloadStation/task.cgi" : "$address/webapi/DownloadStation/task.cgi", queryParameters: {
        "api": "SYNO.DownloadStation.Task",
        "version": "1",
        "method": "delete",
        "id": item.id,
        "force_complete": "true",
        "_sid": sid,
        "session": "DownloadStation",
      });
      Map<String, dynamic> responseData = jsonDecode(response.data);
      if (responseData["success"] == true) {
        //update list
        gettasks();
      }
    } on DioError catch (e) {
      if (e.response?.statusCode == 403) {}
    }
  }

  //api=SYNO.DownloadStation.Task&version=1&method=create&uri=ftps://192.0.0.1:2 1/test/test.zip&file=&username=admin&password=123
  // {'file': (data['name']+'.'+data['type'], filedata)}
  void taskCreateBT(File file, String destination) async {
    try {
      // Dio dio = Dio();
      // Response response = await dio.post(
      //   isquickconnect ? "$address:$qcport/webapi/DownloadStation/task.cgi" : "$address/webapi/DownloadStation/task.cgi",
      //   queryParameters: {
      //     'api': 'SYNO.DownloadStation.Task',
      //     'version': '1',
      //     'method': 'create',
      //     '_sid': sid,
      //     'session': 'DownloadStation',
      //     'destination': '',
      //     'file': MultipartFile.fromFile(file.path),
      //   },
      // );
      // String tempadd = (isquickconnect ? '$address:$qcport/webapi/entry.cgi/SYNO.DownloadStation2.Task' : '$address/webapi/entry.cgi/SYNO.DownloadStation2.Task').replaceAll("http://", "").replaceAll("https://", "");

      print(isquickconnect ? '$address:$qcport/webapi/entry.cgi/SYNO.DownloadStation2.Task' : '$address/webapi/entry.cgi/SYNO.DownloadStation2.Task');

      // final uri = Uri.parse(isquickconnect ? '$address:$qcport/webapi/entry.cgi/SYNO.DownloadStation2.Task' : '$address/webapi/entry.cgi/SYNO.DownloadStation2.Task');
      // final url = Uri.http(uri as String);

      String uri_ = "http://sam07205.synology.me:5000/webapi/entry.cgi/SYNO.DownloadStation2.Task";
      final fileLength = await file.length();
      final payload = BTTaskPayload(
        api: "SYNO.DownloadStation2.Task",
        version: 2,
        destination: destination,
        size: fileLength.toString(),
      ).toJson();
      final filename = file.path.split('/').last;

      final dio = Dio();

      final formData = FormData.fromMap({
        "api": "SYNO.DownloadStation2.Task",
        "method": "create",
        "version": 2,
        "type": '"file"',
        "file": '["torrent"]',
        "destination": destination,
        "create_list": "false",
        "mtime": DateTime.now(),
        "size": fileLength.toString(),
        "sid": sid,
        "session": "DownloadStation",
        'torrent': await MultipartFile.fromFile(
          file.path,
          filename: filename,
          contentType: MediaType.parse('application/octet-stream'),
        ),
      });
      

      // final response = await dio.post(url.toString(), data: formData);
      final response = await dio.post(uri_.toString(), data: formData);

      print(response);
    } catch (e) {
      print(e);
    }
  }

  void taskCreate(String uri, String unzippassword, String destination) async {
    try {
      var response = await dio.get(isquickconnect ? "$address:$qcport/webapi/DownloadStation/task.cgi" : "$address/webapi/DownloadStation/task.cgi", queryParameters: {
        "api": "SYNO.DownloadStation.Task",
        "version": "1",
        "method": "create",
        "uri": uri,
        "unzip_password": unzippassword,
        "destination": destination,
        "_sid": sid,
        "session": "DownloadStation",
      });
      Map<String, dynamic> responseData = jsonDecode(response.data);
      if (responseData["success"] == true) {
        gettasks();
      }
    } on DioError catch (e) {
      if (e.response?.statusCode == 403) {}
    }
  }

  ///webapi/DownloadStation/btsearch.cgi?api=SYNO.DownloadStation.BTSearch&version=1&method=clean
  void taskClean() async {
    try {
      await dio.get(isquickconnect ? "$address:$qcport/webapi/entry.cgi" : "$address/webapi/entry.cgi", queryParameters: {
        "api": "SYNO.DownloadStation2.Task",
        "version": "2",
        "method": "delete_condition",
        "_sid": sid,
        "session": "DownloadStation",
      });
      gettasks();
    } on DioError catch (e) {
      if (e.response?.statusCode == 403) {}
    }
  }

  void setAdress(String newaddress) {
    address = newaddress;
  }

  void setisQC(bool newisQC) {
    isquickconnect = newisQC;
  }
}

class BTTaskPayload {
  final String api;
  final String method;
  final int version;
  final String type;
  final String file;
  final String destination;
  final String createList;
  final int mtime = 0;
  final String size;

  BTTaskPayload({
    required this.api,
    required this.version,
    required this.destination,
    this.method = "create",
    this.type = '"file"',
    this.file = '["torrent"]',
    this.createList = "false",
    required this.size,
  });

  Map<String, dynamic> toJson() {
    return {
      'api': api,
      'method': method,
      'version': version,
      'type': type,
      'file': file,
      'destination': destination,
      'create_list': createList,
      'mtime': mtime,
      'size': size,
    };
  }
}
