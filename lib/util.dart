import 'package:flutter/material.dart';

Color colorFor(String text) {
  var hash = 0;
  for (var i = 0; i < text.length; i++) {
    hash = text.codeUnitAt(i) + ((hash << 5) - hash);
  }
  final finalHash = hash.abs() % (256 * 256 * 256);
  final red = ((finalHash & 0xFF0000) >> 16);
  final blue = ((finalHash & 0xFF00) >> 8);
  final green = ((finalHash & 0xFF));
  final color = Color.fromRGBO(red, green, blue, 1);
  return color;
}

showMsgDialog(BuildContext context, String title, String msg) {
  // Create button
  Widget okButton = TextButton(
    child: const Text("OK"),
    onPressed: () {
      Navigator.of(context, rootNavigator: true).pop();
    },
  );

  // Create AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(msg),
    actions: [
      okButton,
    ],
  );

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

String convertToReadableSize(int bytes) {
  if (bytes < 1024) {
    return '${bytes}B';
  } else if (bytes < 1048576) {
    return '${(bytes / 1024).toStringAsFixed(2)}kB';
  } else if (bytes < 1073741824) {
    return '${(bytes / 1048576).toStringAsFixed(2)}MB';
  } else {
    return '${(bytes / 1073741824).toStringAsFixed(2)}GB';
  }
}

Icon getFileIcon(String fileName) {
  String extension = fileName.split('.').last.toLowerCase();
  switch (extension) {
    case 'pdf':
      return const Icon(Icons.picture_as_pdf);
    case 'doc':
    case 'docx':
    case 'ppt':
    case 'pptx':
    case 'xls':
    case 'xlsx':
    case 'odt':
    case 'ods':
    case 'odp':
    case 'txt':
    case 'rtf':
    case 'tex':
      return const Icon(Icons.insert_drive_file);
    case 'png':
    case 'jpeg':
    case 'jpg':
    case 'gif':
    case 'bmp':
    case 'webp':
    case 'tiff':
    case 'psd':
    case 'svg':
    case 'raw':
    case 'heif':
    case 'indd':
    case 'craw':
    case 'nef':
    case 'orf':
    case 'sr2':
    case 'arw':
    case 'dng':
      return const Icon(Icons.image);
    case 'mp3':
    case 'wav':
    case 'ogg':
    case 'flac':
    case 'aac':
    case 'wma':
    case 'm4a':
    case 'aiff':
    case 'alac':
    case 'amr':
    case 'ape':
    case 'au':
    case 'awb':
    case 'dct':
    case 'dss':
      return const Icon(Icons.music_note);
    case 'mp4':
    case 'avi':
    case 'flv':
    case 'wmv':
    case 'mov':
    case 'mkv':
    case 'webm':
    case 'vob':
    case 'mng':
    case 'qt':
    case 'mpg':
    case 'mpeg':
    case '3gp':
    case '3g2':
    case 'm4v':
    case 'svi':
    case 'mxf':
    case 'roq':
    case 'nsv':
    case 'f4v':
    case 'f4p':
    case 'f4a':
    case 'f4b':
      return const Icon(Icons.video_library);
    case 'pkg':
    case 'deb':
    case 'rpm':
    case 'apk':
    case 'dmg':
    case 'iso':
    case 'war':
    case 'ear':
    case 'sar':
    case 'wim':
    case 'swm':
    case 'esd':
    case 'dsw':
    case 'b1':
    case 'b6z':
    case 'partimg':
    case 'vhd':
    case 'hfs':
    case 'hfsx':
    case 'sparsebundle':
    case 'sparseimage':
    case 'toast':
    case 'vcd':
    case 'cso':
    case 'pim':
      return const Icon(Icons.album);
    case 'zip':
    case 'rar':
    case 'tar':
    case 'gz':
    case '7z':
    case 'xz':
    case 'bz2':
    case 'tgz':
    case 'zst':
    case 'lz':
    case 'lzma':
    case 'cab':
    case 'jar':
    case 'z':
      return const Icon(Icons.archive);

    default:
      return const Icon(Icons.insert_drive_file);
  }
}

Icon getFileStatusIcon(String status) {
  switch (status) {
    case 'waiting':
      return const Icon(Icons.hourglass_empty);
    case 'paused':
      return const Icon(Icons.pause);
    case 'downloading':
      return const Icon(Icons.play_arrow);
    case 'finishing':
    case 'hash_checking':
    case 'filehosting_waiting':
      return const Icon(Icons.hourglass_empty);
    case 'finished':
      return const Icon(Icons.check_circle);
    case 'extracting':
      return const Icon(Icons.unarchive);
    case 'error':
      return const Icon(Icons.warning);
    case 'seeding':
      return const Icon(Icons.local_florist);
    default:
      return const Icon(Icons.question_mark);
  }
}

String formatTime(int timestamp) {
  var dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  return "${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
}

String getfileTranferTime(int byteSize, int byteTransferred, int bytePerSecond) {
  int remainingBytes = byteSize - byteTransferred;
  int remainingTimeInSeconds = (remainingBytes / bytePerSecond).round();
  Duration remainingDuration = Duration(seconds: remainingTimeInSeconds);

  int days = remainingDuration.inDays;
  int hours = remainingDuration.inHours - days * 24;
  int minutes = remainingDuration.inMinutes - days * 24 * 60 - hours * 60;
  int seconds = remainingDuration.inSeconds - days * 24 * 60 * 60 - hours * 60 * 60 - minutes * 60;

  String time = '';
  if (days > 0) {
    time = "${days}d : ${hours}h";
  } else if (hours > 0) {
    time = "${hours}h : ${minutes}m";
  } else {
    time = "${minutes}m : ${seconds}s";
  }
  return time;
}

String calculateDuration(int startTime) {
  int duration = (DateTime.now().millisecondsSinceEpoch ~/ 1000) - startTime;
  int days = duration ~/ (24 * 60 * 60);
  int hours = (duration % (24 * 60 * 60)) ~/ (60 * 60);
  int minutes = (duration % (60 * 60)) ~/ 60;
  int seconds = duration % 60;

  if (days > 0) {
    return "${days}d:${hours}h";
  } else if (hours > 0) {
    return "${hours}h:${minutes}m";
  } else {
    return "${minutes}m:${seconds}s";
  }
}

String calculate2Duration(int startTime, int endTime) {
  int duration = endTime - startTime;
  int days = duration ~/ (24 * 60 * 60);
  int hours = (duration % (24 * 60 * 60)) ~/ (60 * 60);
  int minutes = (duration % (60 * 60)) ~/ 60;
  int seconds = duration % 60;

  if (days > 0) {
    return "${days}d:${hours}h";
  } else if (hours > 0) {
    return "${hours}h:${minutes}m";
  } else {
    return "${minutes}m:${seconds}s";
  }
}
