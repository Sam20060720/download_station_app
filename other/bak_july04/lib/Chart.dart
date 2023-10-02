import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

class DownloadSpeedChart extends StatelessWidget {
  final List<charts.Series<dynamic, int>> seriesList;
  final bool animate;

  DownloadSpeedChart(this.seriesList, {super.key, required this.animate});

  @override
  Widget build(BuildContext context) {
    return charts.LineChart(
      seriesList,
      animate: animate,
    );
  }
}

List<charts.Series<DownloadSpeed, int>> createSampleData() {
  final data = [
    DownloadSpeed(0, 5),
    DownloadSpeed(1, 10),
    DownloadSpeed(2, 15),
    DownloadSpeed(3, 20),
    DownloadSpeed(4, 25),
  ];

  return [
    charts.Series<DownloadSpeed, int>(
      id: 'Download Speed',
      domainFn: (DownloadSpeed speed, _) => speed.time,
      measureFn: (DownloadSpeed speed, _) => speed.speed,
      data: data,
    )
  ];
}

// 圖表數據模型
class DownloadSpeed {
  final int time;
  final int speed;

  DownloadSpeed(this.time, this.speed);
}
