import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:download_station/httpreq.dart';
import 'package:flutter/services.dart';
import 'package:download_station/util.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:io';
import 'package:charts_flutter/flutter.dart' as charts;

// import random function

class DownloadingPage extends StatefulWidget {
  const DownloadingPage({Key? key, required this.httpreqDSM}) : super(key: key);

  final DSM httpreqDSM;

  @override
  State<DownloadingPage> createState() => _DownloadingPageState();
}

class _DownloadingPageState extends State<DownloadingPage> with TickerProviderStateMixin {
  late Timer timer;
  bool canShowSnackBar = false;

  double sizedBoxHeight = 200.0;
  double maxSizedBoxHeight = 300.0;
  double minSizedBoxHeight = 100.0;

  final List<charts.Series<SpeedData, int>> _speedSeriesList = [];
  final List<SpeedData> _speedDataList = [];
  int _nextIndex = 0;

  late AnimationController animcontroller;

  //繼承httpreqDSM
  DSM get httpreqDSM => widget.httpreqDSM;

  @override
  void initState() {
    super.initState();
    animcontroller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _speedDataList.add(SpeedData(0, 0.0));

    // 创建一个速度数据系列
    _speedSeriesList.add(
      charts.Series<SpeedData, int>(
        id: 'Speed',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (data, _) => data.index,
        measureFn: (data, _) => data.speed,
        data: _speedDataList,
      ),
    );

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final itemList = Provider.of<downloadingItemList>(context, listen: false);

        //get task response code in index 0
        setState(() {
          httpreqDSM.gettasks().then((value) => {
                itemList.allupdate(httpreqDSM.downloadinglist),
              });
        });
        //random speed
        updateSpeedChart(httpreqDSM.nowDownloadTotalSpeed / 1024 / 1024);
      }
    });
  }

  void updateSpeedChart(double speed) {
    setState(() {
      // 将新的速度数据点添加到列表中
      _nextIndex++;
      //
      //_speedDataList.add(SpeedData(_nextIndex, speed));
      //replace _nextIndex with time second
      _speedDataList.add(SpeedData(_nextIndex, speed));

      // 如果数据点超过10个，则删除最旧的一个
      if (_speedDataList.length > 10) {
        _speedDataList.removeAt(0);
      }
    });
  }

  @override
  void dispose() {
    animcontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.offset > 0 && scrollController.offset <= 100) {
        animcontroller.animateTo(0.0);
        sizedBoxHeight = maxSizedBoxHeight - (scrollController.offset * (maxSizedBoxHeight - minSizedBoxHeight) / 100);
        setState(() {});
      } else if (scrollController.offset == 0) {
        animcontroller.animateTo(1.0);
        sizedBoxHeight = maxSizedBoxHeight;
        setState(() {});
      } else {
        animcontroller.animateTo(1.0);
        sizedBoxHeight = minSizedBoxHeight;
        setState(() {});
      }
    });

    return Scaffold(
        appBar: AppBar(
//        backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('下載管理器'),
          actions: <Widget>[
            // IconButton(
            //   icon: Icon(Icons.search),
            //   tooltip: 'Search',
            //   onPressed: () => debugPrint('Search button is pressed.'),
            // ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add',
              onPressed: () => showDialog(
                context: context,
                builder: (BuildContext context) {
                  return newTaskDialog(httpreqDSM: widget.httpreqDSM);
                },
              ),
            ),
          ],
        ),
        body: Consumer<downloadingItemList>(builder: (context, itemList, child) {
          return RefreshIndicator(
            onRefresh: () async {
              final itemList = Provider.of<downloadingItemList>(context, listen: false);
              httpreqDSM.gettasks();
              itemList.allupdate(httpreqDSM.downloadinglist);
            },
            child: Column(
              children: [
                Container(
                  child: Text(
                    '下載速度(MB/s)',
                  ),
                  padding: EdgeInsets.only(top: 10),
                ),
                Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    //light mode: Colors.green[200], dark mode: Colors.grey[800]
                    color: ThemeData.estimateBrightnessForColor(Theme.of(context).canvasColor) == Brightness.dark ? Color.fromARGB(26, 142, 142, 142) : Color.fromARGB(0, 189, 189, 189),
                    borderRadius: BorderRadius.circular(10.0), // 设置圆角半径为10.0
                    border: Border.all(
                      color: Colors.grey[300]!, // 设置边框颜色
                      width: 1.0, // 设置边框宽度
                    ),
                  ),
                  child: SizedBox(
                    height: sizedBoxHeight,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: _speedDataList.last.speed),
                      duration: Duration(milliseconds: 500),
                      builder: (context, value, child) {
                        return charts.LineChart(
                          _speedSeriesList,
                          animate: false,
                          behaviors: [],
                          defaultRenderer: charts.LineRendererConfig(
                            includeArea: true,
                            stacked: false,
                          ),
                          domainAxis: const charts.NumericAxisSpec(
                            tickProviderSpec: charts.BasicNumericTickProviderSpec(
                              zeroBound: false,
                              desiredTickCount: 10,
                            ),
                            renderSpec: charts.GridlineRendererSpec(
                              lineStyle: charts.LineStyleSpec(
                                color: charts.Color.transparent,
                              ),
                              labelStyle: charts.TextStyleSpec(color: charts.Color.transparent),
                            ),
                          ),
                          primaryMeasureAxis: charts.NumericAxisSpec(
                            tickProviderSpec: charts.BasicNumericTickProviderSpec(
                              zeroBound: false,
                              desiredTickCount: 5,
                            ),
                            renderSpec: charts.GridlineRendererSpec(
                              lineStyle: charts.LineStyleSpec(
                                color: charts.ColorUtil.fromDartColor(Colors.grey[300]!),
                              ),
                              labelStyle: charts.TextStyleSpec(
                                color: ThemeData.estimateBrightnessForColor(Theme.of(context).canvasColor) == Brightness.dark ? charts.ColorUtil.fromDartColor(Colors.white) : charts.ColorUtil.fromDartColor(Colors.black),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                //horizontal line
                Container(
                  margin: const EdgeInsets.only(left: 10, right: 10),
                  child: const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 0,
                    endIndent: 0,
                  ),
                ),

                Expanded(
                  child: httpreqDSM.downloadinglist.isEmpty
                      ? const Center(child: Text('無下載任務'))
                      : ListView.builder(
                          itemCount: itemList.items.length,
                          itemBuilder: (context, index) {
                            final item = itemList.items[index];
                            return GestureDetector(
                                onTap: Feedback.wrapForTap(() {
                                  HapticFeedback.vibrate();
                                  httpreqDSM.taskPauseResume(item);
                                }, context),
                                onLongPress: Feedback.wrapForTap(() {
                                  HapticFeedback.vibrate();
                                  showModalBottomSheet(
                                      context: context,
                                      builder: (context) => Container(
                                            child: Column(
                                              children: [
                                                ListTile(
                                                  title: const Text('刪除任務'),
                                                  onTap: () {
                                                    httpreqDSM.taskDelete(item);
                                                    Navigator.pop(context);
                                                    httpreqDSM.gettasks();
                                                    itemList.allupdate(httpreqDSM.downloadinglist);
                                                  },
                                                ),
                                              ],
                                            ),
                                          ));
                                }, context),
                                child: Card(
                                    color: ThemeData.estimateBrightnessForColor(Theme.of(context).canvasColor) == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                                    child: Container(
                                      margin: const EdgeInsets.all(8),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                  flex: 10,
                                                  child: Container(
                                                    child: Row(children: [getFileStatusIcon(item.status), const SizedBox(width: 5), Expanded(child: Text(item.title, overflow: TextOverflow.ellipsis))]),
                                                  )),
                                              Expanded(
                                                  flex: 1,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(5),
                                                    child: getFileIcon(item.title),
                                                  )),
                                            ],
                                          ),
                                          Stack(
                                            children: [
                                              SizedBox(
                                                height: 17,
                                                child: LinearProgressIndicator(
                                                  value: item.size > 0 ? ((item.downloadsize.toDouble() / item.size.toDouble()).toDouble()) : 0,
                                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.topLeft,
                                                child: Container(
                                                    margin: EdgeInsets.only(right: 5, left: 5),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text('${item.size > 0 ? ((item.downloadsize.toDouble() / item.size.toDouble() * 100).toDouble().toStringAsFixed(2)) : 0}% · ${item.size > 0 ? (item.speed > 0 ? getfileTranferTime(item.size, item.downloadsize, item.speed) : "∞:∞") : "mm:ss"}'),
                                                        Text('${item.downloadsize > 0 ? convertToReadableSize(item.downloadsize) : 0} / ${item.size > 0 ? convertToReadableSize(item.size) : 0} · ${item.speed > 0 ? convertToReadableSize(item.speed) : 0}/s')
                                                      ],
                                                    )),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    )));
                          }),
                ),
              ],
            ),
          );
        }));
  }
}

class downloadingItemList with ChangeNotifier {
  List<downloadItem> _items = [];

  List<downloadItem> get items => _items;

  void addItem(downloadItem item) {
    _items.add(item);
    notifyListeners();
  }

  void updateItem(downloadItem item) {
    _items.removeWhere((element) => element.id == item.id);
    _items.add(item);
    notifyListeners();
  }

  void allupdate(List<downloadItem> getitems) {
    if (getitems.isEmpty) {
      _items = getitems;
      notifyListeners();
    } else if (getitems.length != _items.length) {
      _items = getitems;
      notifyListeners();
    } else {
      for (int i = 0; i < getitems.length; i++) {
        if (getitems[i].id != _items[i].id) {
          _items = getitems;
          notifyListeners();
          break;
        }
      }
      for (int i = 0; i < getitems.length; i++) {
        _items[i].downloadsize = getitems[i].downloadsize;
        _items[i].speed = getitems[i].speed;
        _items[i].status = getitems[i].status;
        notifyListeners();
      }
    }
  }
}

// ignore: camel_case_types
class newTaskDialog extends StatefulWidget {
  const newTaskDialog({super.key, required this.httpreqDSM});
  final DSM httpreqDSM;

  @override
  _newTaskDialogState createState() => _newTaskDialogState();
}

class _newTaskDialogState extends State<newTaskDialog> {
  // url file unzip_password destination
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _fileController = TextEditingController();
  final _unzip_passwordController = TextEditingController();
  final _destinationController = TextEditingController();
  int _radioValue = 0;
  File _file = File('');

  @override
  void dispose() {
    _urlController.dispose();
    _fileController.dispose();
    _unzip_passwordController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新增下載任務'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListBody(
              children: <Widget>[
                RadioListTile(
                  value: 0,
                  groupValue: _radioValue,
                  onChanged: ((value) => {
                        setState(() {
                          _radioValue = value as int;
                        }),
                        _urlController.text = "",
                        _fileController.text = "",
                      }),
                  title: Text("輸入網址"),
                ),
                RadioListTile(
                  value: 1,
                  groupValue: _radioValue,
                  onChanged: ((value) => {
                        setState(() {
                          _radioValue = value as int;
                        }),
                        _urlController.text = "",
                        _fileController.text = "",
                      }),
                  title: Text("打開檔案"),
                )
              ],
            ),
            _radioValue == 0
                ? TextFormField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: '網址',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '請輸入網址';
                      }
                      return null;
                    },
                  )
                : ElevatedButton(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles();

                      if (result != null) {
                        _file = File(result.files.single.path!);
                        print(_file.path);
                        _fileController.text = result.files.single.name;
                      } else {
                        // User canceled the picker
                      }
                    },
                    child: Text("選擇檔案"),
                  ),
            _radioValue == 1
                ? TextFormField(
                    enabled: false,
                    controller: _fileController,
                    decoration: const InputDecoration(
                      labelText: '檔案名稱',
                    ),
                  )
                : Container(),
            TextFormField(
              controller: _unzip_passwordController,
              decoration: const InputDecoration(
                labelText: '解壓密碼',
                hintText: '請輸入解壓密碼',
              ),
            ),
            TextFormField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: '下載路徑',
                hintText: '請輸入下載路徑',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '請輸入下載路徑';
                }
                return null;
              },
            ),
          ],
        )),
        //at scroll
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () async {
            // await widget.httpreqDSM.newTask(
            //     url: _urlController.text,
            //     file: _fileController.text,
            //     unzip_password: _unzip_passwordController.text,
            //     destination: _destinationController.text);
            if (_radioValue == 1) {
              if (_file.path == "") {
                showMsgDialog(context, "請選擇檔案", "請選擇檔案");
                return;
              }
              // widget.httpreqDSM.taskCreateBT(_file, _fileController.text, _destinationController.text.split('.').last, 'BT');
            } else {
              if (_urlController.text == "") {
                showMsgDialog(context, "請輸入網址", "請輸入網址");
                return;
              }
              widget.httpreqDSM.taskCreate(_urlController.text, _unzip_passwordController.text, _destinationController.text);
            }
            Navigator.pop(context);
          },
          child: const Text('確定'),
        ),
      ],
    );
  }
}

class SpeedData {
  final int index;
  final double speed;

  SpeedData(this.index, this.speed) {
    index;
  }
}
