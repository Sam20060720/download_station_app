// Login Page
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:download_station/pageHome.dart';
import 'package:download_station/util.dart';
import 'package:download_station/httpreq.dart';
import 'package:download_station/loading_screen.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:download_station/util.dart';
import 'dart:convert';
import 'package:internet_connection_checker/internet_connection_checker.dart';

const FAS = FlutterSecureStorage();
DSM httpreqDSM = DSM();
LoadingScreen loadsc = LoadingScreen();

class pageLogin extends StatefulWidget {
  const pageLogin({Key? key, required this.isneedrunLogin}) : super(key: key);
  final int isneedrunLogin;
  @override
  _pageLoginState createState() => _pageLoginState();
}

class _pageLoginState extends State<pageLogin> {
  final _formKey = GlobalKey<FormState>();
  final _adressController = TextEditingController();
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _useQuickConnect = false;
  late InAppWebViewController webView;
  var orginput = "";

  @override
  void dispose() {
    _adressController.dispose();
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      if (widget.isneedrunLogin == 1) {
        bool ckconresult = await InternetConnectionChecker().hasConnection;
        if (ckconresult == false) {
          showMsgDialog(context, '登入失敗', '請檢查網路連線');
          setState(() async {
            if ((await FAS.read(key: "isquickconnect") ?? "false") == 'true') {
              _adressController.text = await FAS.read(key: "QCID") ?? "";
            } else {
              _adressController.text = await FAS.read(key: "Adress") ?? "";
            }
            _accountController.text = (await FAS.read(key: "Account") ?? "");
            _passwordController.text = await FAS.read(key: "Password") ?? "";
          });
          return;
        } else if ((await tryLogin(context, 1, "", "", "", false, '')) == "QcReLogin") {
          print("QcReLogin");
          setState(() async {
            if ((await FAS.read(key: "isquickconnect") ?? "false") == 'true') {
              _adressController.text = await FAS.read(key: "QCID") ?? "";
            } else {
              _adressController.text = await FAS.read(key: "Adress") ?? "";
            }
            _accountController.text = (await FAS.read(key: "Account") ?? "");
            _passwordController.text = await FAS.read(key: "Password") ?? "";
          });
        }

        //showMsgDialog(context, "登入失敗", "QuickConnect登入授權過期");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            margin: const EdgeInsets.all(20),
            child: _useQuickConnect
                ? InAppWebView(
                    initialUrlRequest: URLRequest(url: Uri.parse(_adressController.text)),
                    onWebViewCreated: (InAppWebViewController controller) {
                      webView = controller;
                    },
                    onLoadStop: (controller, url) async {
                      setState(() {});
                      if (mounted) {
                        var isdec = false;
                        try {
                          var content = await controller.evaluateJavascript(source: "document.querySelector('pre').innerHTML;");
                          var message = await controller.evaluateJavascript(source: "document.getElementsByClassName('error-container')​");
                          try {
                            var decodedJSON = json.decode(content ?? "{") as Map<String, dynamic>;
                            if (decodedJSON['success'] == true) {
                              isdec = true;
                              _useQuickConnect = true;

                              await FAS.write(key: 'isquickconnect', value: 'true');

                              // ignore: use_build_context_synchronously

                              tryLogin(context, 0, url.toString().contains('https') ? 'https://${Uri.parse(url.toString()).host}' : 'http://${Uri.parse(url.toString()).host}', _accountController.text, _passwordController.text, true, orginput);
                              setState(() {
                                orginput = orginput.replaceAll('.quickconnect.to', '');
                                FAS.write(key: 'QCID', value: orginput);
                                _useQuickConnect = false;
                              });
                            } else {
                              isdec = true;
                              setState(() {
                                _useQuickConnect = false;
                              });

                              showMsgDialog(context, '登入失敗', '錯誤的帳號或密碼');

                              _adressController.text = orginput;
                              _passwordController.text = "";
                            }
                            // ignore: empty_catches
                          } on FormatException catch (e) {
                            print('message: $message');
                            if (url.toString().contains('error')) {
                              //delay 1 sec to show dialog
                              setState(() {
                                _useQuickConnect = false;
                              });
                              showMsgDialog(context, '登入失敗', '錯誤的QuickConnect ID');
                              _adressController.text = orginput;
                              _passwordController.text = "";
                            }
                          }
                          // ignore: empty_catches
                        } catch (e) {}
                      }
                    },
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20), // Image border
                            child: SizedBox.fromSize(
                              size: const Size.fromRadius(48), // Image radius
                              child: Image.asset('assets/images/icon.png', fit: BoxFit.cover),
                            ),
                          )),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: <Widget>[
                            TextFormField(
                              controller: _adressController,
                              decoration: const InputDecoration(
                                hintText: 'QuickConnect ID  IP:PORT  example.com',
                              ),
                            ),
                            TextFormField(
                              autofillHints: const [AutofillHints.username],
                              controller: _accountController,
                              decoration: const InputDecoration(
                                hintText: '帳號',
                              ),
                            ),
                            TextFormField(
                              autofillHints: const [AutofillHints.password],
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                hintText: '密碼',
                              ),
                            ),
                            Container(
                                margin: const EdgeInsets.only(top: 20),
                                child: OutlinedButton(
                                  onPressed: () async {
                                    bool ckconresult = await InternetConnectionChecker().hasConnection;
                                    if (ckconresult == false) {
                                      showMsgDialog(context, '登入失敗', '請檢查網路連線');
                                      return;
                                    }

                                    if (_adressController.text.isEmpty || _accountController.text.isEmpty || _passwordController.text.isEmpty) {
                                      showMsgDialog(context, '登入失敗', '請輸入完整資訊');
                                      return;
                                    }
                                    orginput = _adressController.text;

                                    if (_adressController.text.contains('.') == false) {
                                      _adressController.text = 'https://${_adressController.text}.quickconnect.to/webapi/auth.cgi?api=SYNO.API.Auth&version=3&method=login&account=${_accountController.text}&passwd=${_passwordController.text}&session=DownloadStation&format=sid';
                                      FAS.write(key: 'isquickconnect', value: 'true');
                                      setState(() {
                                        _useQuickConnect = true;
                                      });
                                    } else if (_adressController.text.contains('.quickconnect.to')) {
                                      var tmpurl = Uri.parse(_adressController.text).host;
                                      await FAS.write(key: 'isquickconnect', value: 'true');
                                      _adressController.text = 'https://${_adressController.text}/webapi/auth.cgi?api=SYNO.API.Auth&version=3&method=login&account=${_accountController.text}&passwd=${_passwordController.text}&session=DownloadStation&format=sid';
                                      setState(() {
                                        _useQuickConnect = true;
                                      });
                                    } else {
                                      if (_adressController.text.contains('https://') == false && _adressController.text.contains('http://') == false) {
                                        _adressController.text = 'http://' + _adressController.text;
                                      }
                                      await FAS.write(key: 'isquickconnect', value: 'false');
                                      tryLogin(context, 0, _adressController.text, _accountController.text, _passwordController.text, false, '');
                                      _useQuickConnect = false;
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18.0),
                                    ),
                                    side: const BorderSide(width: 2, color: Colors.grey),
                                  ),
                                  child: const Text('登入', style: TextStyle(fontSize: 20)),
                                )),
                          ],
                        ),
                      )
                    ],
                  )));
  }
}

Future<String> tryLogin(BuildContext context, int isauto, String adre, String acc, String passwd, bool isqc, String qcid) async {
  // show the loading dialog
  // if not quickconnect

  // ignore: use_build_context_synchronously
  loadsc.show(context: context, text: 'Loading...');

  if (isauto == 0) {
    httpreqDSM.setAdress(adre);
    httpreqDSM.setisQC(isqc);
    httpreqDSM.login(acc, passwd).then((status) async => {
          if (status[0] == 0)
            {
              await FAS.write(key: "Adress", value: adre).then((value) async => {
                    await FAS.write(key: "SID", value: status[1] as String).then((value) async => {
                          await FAS.write(key: "Account", value: acc).then((value) async => {
                                await FAS.write(key: "Password", value: passwd).then((value) async => {
                                      await FAS.write(key: "isquickconnect", value: isqc ? 'true' : 'false').then((value) async => {
                                            loadsc.hide(),
                                            Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) => pageHome(
                                                        showAccount: acc,
                                                        showAdress: isqc ? '${qcid}' : adre,
                                                        httpreqDSM: httpreqDSM,
                                                      )),
                                              (r) {
                                                return false;
                                              },
                                            )
                                          })
                                    })
                              })
                        })
                  })
            }
          else
            {
              loadsc.hide(),
              showMsgDialog(context, "登入失敗", status[1] as String),
            }
        });
  } else {
    String? sid = await FAS.read(key: "SID");
    String? adress = await FAS.read(key: "Adress");
    String? account = await FAS.read(key: "Account");
    String? isquickconnect = await FAS.read(key: "isquickconnect");
    String? qcid = await FAS.read(key: "QCID");

    if (sid != null && adress != null && account != null && isquickconnect != null && sid != '' && adress != '' && account != '' && isquickconnect != '') {
      httpreqDSM.setAdress(adress);
      httpreqDSM.setisQC(isquickconnect == 'true');
      int sidstat = await httpreqDSM.checksid(sid);
      print("sidstat: $sidstat, sid: $sid");
      if (sidstat == 0) {
        loadsc.hide();
        // ignore: use_build_context_synchronously
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => pageHome(
                      showAccount: account,
                      showAdress: isquickconnect == 'true' ? '$qcid.quickconnect.to' : adress,
                      httpreqDSM: httpreqDSM,
                    )), (r) {
          return false;
        });
      } else {
        loadsc.hide();
        if (sidstat == 3) {
          if (isquickconnect == 'true') {
            showMsgDialog(context, "登入失敗", "QuickConnect登入逾時 (Timeout)");
            return 'QcReLogin';
          } else {
            showMsgDialog(context, "登入失敗", "登入逾時");
            return '';
          }
        }
        if (isquickconnect == 'true') {
          showMsgDialog(context, "登入失敗", "QuickConnect登入授權過期 (Session expired)");
          FAS.write(key: "SID", value: '');
          FAS.write(key: "Password", value: '');
          return 'QcReLogin';
        } else {
          showMsgDialog(context, "登入失敗", "登入授權過期 (Session expired)");
          FAS.write(key: "Password", value: '');
          FAS.write(key: "SID", value: '');
        }
      }
    } else {
      loadsc.hide();
    }
  }
  return '';
}
