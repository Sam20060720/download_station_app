// Home Page
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:download_station/pageLogin.dart';
import 'package:download_station/util.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:download_station/httpreq.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:io';

import 'package:download_station/navDownloading.dart';

const FAS = FlutterSecureStorage();

class pageHome extends StatelessWidget {
  const pageHome({super.key, required this.showAccount, required this.showAdress, required this.httpreqDSM});
  final String showAccount;
  final String showAdress;
  final DSM httpreqDSM;

  // 重寫
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => downloadingItemList()),
          ChangeNotifierProvider(create: (_) => finishItemList()),
        ],
        child: MaterialApp(
          theme: ThemeData(),
          darkTheme: ThemeData.dark(), // standard dark theme
          themeMode: ThemeMode.system,
          home: Scaffold(
            body: HomePageNavController(
              showAccount: showAccount,
              showAdress: showAdress,
              httpreqDSM: httpreqDSM,
            ),
          ),
        ));
  }
}

class HomePageNavController extends StatefulWidget {
  HomePageNavController({Key? key, required this.showAccount, required this.showAdress, required this.httpreqDSM}) : super(key: key);
  final String showAccount;
  final String showAdress;
  final DSM httpreqDSM;

  @override
  // ignore: library_private_types_in_public_api, no_logic_in_create_state
  _HomePageNavControllerState createState() => _HomePageNavControllerState(A: showAccount, T: showAdress, D: httpreqDSM);
}

class _HomePageNavControllerState extends State<HomePageNavController> {
  int _currentIndex = 0; //預設值
  String showAccount = "";
  String showAdress = "";
  DSM httpreqDSM = DSM();

  _HomePageNavControllerState({required String A, required String T, required DSM D}) {
    showAccount = A;
    showAdress = T;
    httpreqDSM = D;
  }

  late final pages = [
    DownloadingPage(
      httpreqDSM: httpreqDSM,
    ),
    DonePage(
      httpreqDSM: httpreqDSM,
    ),
    MorePage(showAccount: showAccount, showAdress: showAdress, httpreqDSM: httpreqDSM)
  ];

  @override
  void initState() {
    super.initState();
    httpreqDSM.gettasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.download),
            label: '下載中',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.download_done),
            label: '已完成',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: '更多',
          ),
        ],
        currentIndex: _currentIndex,
        selectedItemColor: Colors.amber[800],
        onTap: (index) {
          if (mounted) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
      ),
    );
  }
}

class DonePage extends StatefulWidget {
  const DonePage({Key? key, required this.httpreqDSM}) : super(key: key);

  final DSM httpreqDSM;

  @override
  State<DonePage> createState() => _DonePageState();
}

class _DonePageState extends State<DonePage> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        final itemList = Provider.of<finishItemList>(context, listen: false);
        httpreqDSM.gettasks();
        itemList.allupdate(httpreqDSM.finishedlist);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
              icon: Icon(Icons.clear_all),
              tooltip: 'Add',
              onPressed: () => widget.httpreqDSM.taskClean(),
            ),
          ],
        ),
        body: Consumer<finishItemList>(builder: (context, itemList, child) {
          return RefreshIndicator(
              onRefresh: () async {
                final itemList = Provider.of<finishItemList>(context, listen: false);
                httpreqDSM.gettasks();
                itemList.allupdate(httpreqDSM.finishedlist);
              },
              child: ListView.builder(
                  itemCount: itemList.items.length,
                  itemBuilder: (context, index) {
                    final item = itemList.items[index];
                    return GestureDetector(
                        onTap: Feedback.wrapForTap(() {
                          HapticFeedback.vibrate();
                        }, context),
                        onLongPress: Feedback.wrapForTap(() {
                          HapticFeedback.vibrate();
                          showModalBottomSheet(
                              context: context,
                              builder: (context) => Container(
                                    child: Column(
                                      children: [
                                        item.status == 'error'
                                            ? ListTile(
                                                title: const Text('刪除失敗任務'),
                                                onTap: () {
                                                  httpreqDSM.taskDelete(item);
                                                  Navigator.pop(context);
                                                  httpreqDSM.gettasks();
                                                  itemList.allupdate(httpreqDSM.downloadinglist);
                                                },
                                              )
                                            : const SizedBox(),
                                      ],
                                    ),
                                  ));
                        }, context),
                        child: Card(
                            child: Container(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      child: Row(children: [
                                        Row(children: [
                                          getFileStatusIcon(item.status),
                                          const SizedBox(width: 5),
                                        ]),
                                        Expanded(child: Text(item.title, overflow: TextOverflow.ellipsis))
                                      ]),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      child: getFileIcon(item.title),
                                    ),
                                  )
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
                                          children: [Text('${item.size > 0 ? ((item.downloadsize.toDouble() / item.size.toDouble() * 100).toDouble().toStringAsFixed(2)) : 0}%'), Text('${item.downloadsize > 0 ? convertToReadableSize(item.downloadsize) : 0} / ${item.size > 0 ? convertToReadableSize(item.size) : 0}')],
                                        )),
                                  ),
                                ],
                              )
                            ],
                          ),
                        )));
                  }));
        }));
  }
}

class MorePage extends StatelessWidget {
  const MorePage({super.key, required this.showAccount, required this.showAdress, required this.httpreqDSM});
  final String showAccount;
  final String showAdress;
  final DSM httpreqDSM;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size(100, 100), //width and height
          // The size the AppBar would prefer if there were no other constraints.
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.only(left: 20.0, right: 20.0),
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        showAccount,
                        style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        showAdress,
                        style: const TextStyle(fontSize: 15, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ]),
                  ),
                  Expanded(
                    flex: 1,
                    child: CircleAvatar(
                        backgroundColor: colorFor(showAccount),
                        radius: 30,
                        child: Text(
                          showAccount[0],
                          style: const TextStyle(color: Colors.white, fontSize: 25),
                        )),
                  )
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // const ListTile(
            //   leading: Icon(Icons.settings),
            //   title: Text('設定'),
            // ),
            const Divider(
              height: 5,
              thickness: 1,
              indent: 4,
              endIndent: 4,
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('登出'),
              onTap: () async {
                await FAS.delete(key: "SID").then((value) async => {
                      await FAS.delete(key: "Adress").then((value) => {
                            Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const pageLogin(isneedrunLogin: 0),
                                ), (r) {
                              return false;
                            })
                          })
                    });
              },
            ),
            const Divider(
              height: 5,
              thickness: 1,
              indent: 4,
              endIndent: 4,
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: Text('Download Station: ${httpreqDSM.dsmVersionString}'),
              onTap: () async {
                showMsgDialog(context, "關於", "Download Station: ${httpreqDSM.dsmVersionString}\nMade by: Sam07205");

                // ignore: use_build_context_synchronously
                // ignore: use_build_context_synchronously
              },
            ),
          ],
        ));
  }
}

class finishItemList with ChangeNotifier {
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
    if (getitems.length == 0) {
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

// newTask dialog
