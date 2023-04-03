import 'package:flutter/material.dart';

///connectionStatus : Returns the connection status as [ConnectionStatusEnum].
///
///connectionDelay : Returns the duration between sending the request and receiving the response from the server.
///
///isWebSocket : Determines whether the request sent is an API or WebSocket request.
class ConnectionStatusModel {
  final bool? isWebSocket;
  final ConnectionStatusEnum? connectionStatus;
  final int? connectionDelay;
  final Color? color;
  final String? title;

  ConnectionStatusModel({
    this.isWebSocket,
    this.connectionStatus,
    this.connectionDelay,
    this.color,
    this.title,
  });
}

enum ConnectionStatusEnum { ok, normal, slow, error }
