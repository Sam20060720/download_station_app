import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class downingItem with ChangeNotifier {
  String _name = '';
  String _size = '';
  String _status = '';
  String _speed = '';
  String _percent = '';
  String _id = '';

  String get name => _name;

  String get size => _size;

  String get status => _status;

  String get speed => _speed;

  String get percent => _percent;

  String get id => _id;

  void setname(String name) {
    _name = name;
    notifyListeners();
  }

  void setsize(String size) {
    _size = size;
    notifyListeners();
  }

  void setstatus(String status) {
    _status = status;
    notifyListeners();
  }

  void setspeed(String speed) {
    _speed = speed;
    notifyListeners();
  }

  void setpercent(String percent) {
    _percent = percent;
    notifyListeners();
  }

  void setid(String id) {
    _id = id;
    notifyListeners();
  }

  void update(downingItem item) {
    _name = item.name;
    _size = item.size;
    _status = item.status;
    _speed = item.speed;
    _percent = item.percent;
    _id = item.id;
    notifyListeners();
  }

  Map<String, String> getinfo() {
    return {'name': _name, 'size': _size, 'status': _status, 'speed': _speed, 'percent': _percent, 'id': _id};
  }
}
