// This service is created by https://github.com/alper_mf

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'model/connection_status_model.dart';

///How to use?
///1. Initialize the service
///
///```dart
///ConnectionService.instance.init();
///```
///
///2. Get the stream
///
///```dart
///ConnectionService.instance.serverPingStream().listen((event) {
///  print(event.connectionStatus);
/// print(event.connectionDelay);
/// print(event.isWebSocket);
/// print(event.color);
/// print(event.title);
///
/// ConnectionService.instance.showMaterialWidget(context, 'Your message');
/// });
/// ```
///
/// 3. Get the internet availability stream
///
///
/// ```dart
/// ConnectionService.instance.getInternetAvailabilityStream().listen((event) {
///  print(event);
///
/// ConnectionService.instance.showMaterialWidget(context, 'Your message');
/// });
/// ```
///
/// 4. Show the material widget
///
/// ```dart
///

class ConnectionService {
  ConnectionService._(this.serverPingURL, this.webSocketURL) {
    _initialize();
  }

  static ConnectionService? _instance;

  static ConnectionService get instance {
    assert(_instance != null, 'ConnectionService must be initialized before use');

    return _instance!;
  }

  late final String serverPingURL;
  late final String? webSocketURL;

  final _hasConnectionStreamController = StreamController<bool>();
  final _serverPingStreamController = StreamController<ConnectionStatusModel>();

  final Duration _lookUpHasInternetDuration = const Duration(seconds: 10);
  final Duration _lookUpConnectionDelay = const Duration(seconds: 10);
  final Duration _lookUpWebSocketDelay = const Duration(seconds: 5);

  final String _checkInternetURL = 'google.com';

  void _initialize() {
    _instance = this;
  }

  ///Internet bağlantısı olup olmadığını kontrol eder.
  Future<bool> isInternetAvailable() async {
    try {
      final result = await InternetAddress.lookup(_checkInternetURL);
      final isActive = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      _updateStreamController(isActive);

      return isActive;
    } catch (e) {
      _updateStreamController(false);

      return false;
    }
  }

  ///It's updating the controller for stream
  _updateStreamController(bool result) {
    _hasConnectionStreamController.sink.add(result);
  }

  Stream<bool> getInternetAvailabilityStream() {
    return _hasConnectionStreamController.stream;
  }

  void _updateServerPingStreamController(ConnectionStatusModel model) {
    _serverPingStreamController.sink.add(model);
  }

  Stream<ConnectionStatusModel> serverPingStream() {
    return _serverPingStreamController.stream;
  }

  Future<bool> _checkWebSocketConnection() async {
    try {
      Stopwatch stopwatch = Stopwatch()..start();
      final WebSocket socket = await WebSocket.connect(webSocketURL ?? '');
      await socket.close();

      stopwatch.stop();

      int connectionSpeed = stopwatch.elapsedMilliseconds;

      _updateServerPingStreamController(createConnectionModel(connectionSpeed, true));

      return true;
    } catch (e) {
      final model = ConnectionStatusModel(
        color: Colors.red,
        connectionStatus: ConnectionStatusEnum.error,
        isWebSocket: true,
        title: 'Socket bağlantısı yok',
      );
      _updateServerPingStreamController(model);

      return false;
    }
  }

  ///This function prepares to the server connection delay
  Future _checkServerInternetConnection() async {
    try {
      Stopwatch stopwatch = Stopwatch()..start();
      final response = await http.get(Uri.parse(serverPingURL));
      if (response.statusCode == HttpStatus.ok) {
        stopwatch.stop();
        int connectionSpeed = stopwatch.elapsedMilliseconds;
        _updateServerPingStreamController(createConnectionModel(connectionSpeed, false));
      }
    } catch (e) {
      final model = ConnectionStatusModel(
        color: Colors.red,
        connectionStatus: ConnectionStatusEnum.error,
        isWebSocket: false,
        title: 'No internet connection',
      );
      _updateServerPingStreamController(model);
    }
    // print('SUNUCUYA ISTEK ATILDI => ${DateTime.now().minute}:${DateTime.now().second}');
  }

  ///This function is initializing the timers
  void init() {
    Timer.periodic(_lookUpHasInternetDuration, (timer) => isInternetAvailable());
    Timer.periodic(_lookUpConnectionDelay, (timer) => _checkServerInternetConnection());
    Timer.periodic(_lookUpWebSocketDelay, (timer) => _checkWebSocketConnection());
  }

  ConnectionStatusModel createConnectionModel(int stopWatchValue, bool isWebSocket) {
    late final ConnectionStatusModel model;

    if (stopWatchValue > 400) {
      model = ConnectionStatusModel(
        isWebSocket: isWebSocket,
        connectionStatus: ConnectionStatusEnum.slow,
        connectionDelay: stopWatchValue,
        color: Colors.orangeAccent,
        title: 'Your internet connection is slow',
      );

      return model;
    } else if (stopWatchValue > 250 && stopWatchValue < 400) {
      model = ConnectionStatusModel(
        isWebSocket: isWebSocket,
        connectionStatus: ConnectionStatusEnum.normal,
        connectionDelay: stopWatchValue,
        color: Colors.orange,
        title: 'Your internet connection is normal',
      );

      return model;
    } else if (stopWatchValue > 0 && stopWatchValue < 250) {
      model = ConnectionStatusModel(
        isWebSocket: isWebSocket,
        connectionStatus: ConnectionStatusEnum.ok,
        connectionDelay: stopWatchValue,
        color: Colors.greenAccent,
        title: 'Your internet connection is ok',
      );
    } else {
      model = ConnectionStatusModel(
        /*   isWebSocket: isWebSocket,
        connectionStatus: ConnectionStatusEnum.error,
        connectionDelay: stopWatchValue,
        color: Colors.green,
        title: "İnternet Bağlantınızı Kontrol Ediniz!", */
        isWebSocket: isWebSocket,
      );
    }

    return model;
  }

  void showMaterialBanner(BuildContext context, [String? message]) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final banner = MaterialBanner(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      content: Text(
        message ?? 'No internet connection',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Colors.redAccent,
      actions: [
        TextButton(
          onPressed: () => scaffoldMessenger.hideCurrentMaterialBanner(),
          child: const Text(
            'OK',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
    scaffoldMessenger.showMaterialBanner(banner);
  }
}
