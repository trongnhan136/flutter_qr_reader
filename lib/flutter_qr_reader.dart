import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class FlutterQrReader {
  static const MethodChannel _channel =
      const MethodChannel('me.hetian.flutter_qr_reader');

  static Future<String> imgScan(File file) async {
    if (file.existsSync() == false) {
      return "";
    }
    try {
      final rest =
          await _channel.invokeMethod("imgQrCode", {"file": file.path});
      return rest;
    } catch (e) {
      print(e);
      return '';
    }
  }
}

class QrReaderView extends StatefulWidget {
  Function(QrReaderViewController)? callback;

  int? autoFocusIntervalInMs;
  bool? torchEnabled;
  double? width;
  double? height;

  QrReaderView({
    Key? key,
    @required this.width,
    @required this.height,
    @required this.callback,
    this.autoFocusIntervalInMs = 500,
    this.torchEnabled = false,
  }) : super(key: key);

  @override
  _QrReaderViewState createState() => new _QrReaderViewState();
}

class _QrReaderViewState extends State<QrReaderView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: "me.hetian.flutter_qr_reader.reader_view",
        creationParams: {
          "width": ((widget.width ?? 120) * window.devicePixelRatio).floor(),
          "height": ((widget.height ?? 240) * window.devicePixelRatio).floor(),
          "extra_focus_interval": widget.autoFocusIntervalInMs,
          "extra_torch_enabled": widget.torchEnabled,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
          new Factory<OneSequenceGestureRecognizer>(
              () => new EagerGestureRecognizer()),
        ].toSet(),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: "me.hetian.flutter_qr_reader.reader_view",
        creationParams: {
          "width": widget.width,
          "height": widget.height,
          "extra_focus_interval": widget.autoFocusIntervalInMs,
          "extra_torch_enabled": widget.torchEnabled,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
          new Factory<OneSequenceGestureRecognizer>(
              () => new EagerGestureRecognizer()),
        ].toSet(),
      );
    } else {
      return Text('平台暂不支持');
    }
  }

  void _onPlatformViewCreated(int id) {
    if (widget.callback != null) {
      widget.callback!(QrReaderViewController(
        id: id,
      ));
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

typedef ReadChangeBack = void Function(String, List<Offset>);

class QrReaderViewController {
  int? id;
  MethodChannel? _channel;
  QrReaderViewController({@required this.id})
      : _channel =
            MethodChannel('me.hetian.flutter_qr_reader.reader_view_$id') {
    _channel?.setMethodCallHandler(_handleMessages);
  }
  ReadChangeBack? onQrBack;

  Future _handleMessages(MethodCall call) async {
    switch (call.method) {
      case "onQRCodeRead":
        List<Offset> points = [];
        if (call.arguments.containsKey("points")) {
          final pointsStrs = call.arguments["points"];
          for (String point in pointsStrs) {
            final a = point.split(",");
            points.add(Offset(
                double.tryParse(a.first) ?? 0, double.tryParse(a.last) ?? 0));
          }
        }
        if (this.onQrBack != null) {
          this.onQrBack!(call.arguments["text"], points);
        }

        break;
    }
  }

  // 打开手电筒
  Future<bool?> setFlashlight() async {
    return _channel?.invokeMethod("flashlight");
  }

  // 开始扫码
  Future startCamera(ReadChangeBack onQrBack) async {
    this.onQrBack = onQrBack;
    return _channel?.invokeMethod("startCamera");
  }

  // 结束扫码
  Future stopCamera() async {
    return _channel?.invokeMethod("stopCamera");
  }
}
