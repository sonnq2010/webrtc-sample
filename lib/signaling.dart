import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class DirectSignaling {

  DirectSignaling({required this.host});

  final String host; // nodejs web server ip address
  late String socketId; // given by nodejs webb server

  late RTCPeerConnection localPeer;
  late WebSocketChannel channel;
  void Function(MediaStream stream)? onLocalStreamAvailable;
  void Function(MediaStream stream)? onRemoteStreamAvailable;
  void Function(RTCPeerConnectionState state)? onConnectionState;

  Future<void> initalize({onLocalStreamAvailable, onRemoteStreamAvailable, onConnectionState}) async{
    this.onLocalStreamAvailable = onLocalStreamAvailable;
    this.onRemoteStreamAvailable = onRemoteStreamAvailable;
    this.onConnectionState = onConnectionState;
    if (kIsWeb) {
      channel = HtmlWebSocketChannel.connect(host);
    } else {
      channel = IOWebSocketChannel.connect(host);
    }


    channel.stream.listen(_handleWebsocketMessages);
    await initWebRTC();
  }

  void _handleWebsocketMessages(msg) async {
    Map<String, dynamic> message = jsonDecode(msg);

    if (message['type'] == 'id') {
      socketId = message['data'];
      //print('Đã nhận được id từ server: $socketId');
    }
    else if (message['type'] == 'answer') {
      var response = message['data'];
      print('Đã nhận được response');
      await handleResponse(response);
    }
    else if (message['type'] == 'offer') {
      var response = message['data'];
      print('Đã nhận được offer');
      await handleOffer(response);
    }
    else if (message['type'] == 'candidate') {
      var candidate = message['data'];
      //print('Đã nhận được remote candidate');
      await handleRemoteCandidates(candidate);
    }
  }

  Future<void> initWebRTC() async {
    var localStream = await getUserMedia();
    onLocalStreamAvailable?.call(localStream);

    localPeer = await createPeerConnection({'iceServers': [{'url': 'stun:stun.l.google.com:19302'}]},  {
      "mandatory": {
        "OfferToReceiveAudio": true,
        "OfferToReceiveVideo": true,
      },
      "optional": [],
    });

    // send ice candidates to other side
    localPeer.onIceCandidate = (RTCIceCandidate candidate) {
      channel.sink.add(jsonEncode({'type':'candidate', 'data': candidate.toMap(), 'from': socketId}));
    };

    // RTCPeerConnectionStateConnected, RTCPeerConnectionStateDisconnected, RTCPeerConnectionStateFailed
    if (onConnectionState != null) localPeer.onConnectionState = onConnectionState;

    // handle incoming stream
    localPeer.onAddStream = (MediaStream stream) {
      onRemoteStreamAvailable?.call(stream); // pass the stream to the outside
    };

    // handle incoming tracks
    localPeer.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        onRemoteStreamAvailable?.call(event.streams[0]); // pass the stream to the outside
      }
    };

    // send local media stream and tracks to the other side
    localStream.getTracks().forEach((track) async {
      await localPeer.addTrack(track, localStream);
    });
  }

  Future<void> handleRemoteCandidates(Map<String, dynamic> candidateMap) async {
    await localPeer.addCandidate(RTCIceCandidate(candidateMap['candidate'],
        candidateMap['sdpMid'], candidateMap['sdpMLineIndex']));
  }

  Future<void> handleResponse(Map<String, dynamic> description) async {
    var desc = RTCSessionDescription(description['sdp'], description['type']);
    await localPeer.setRemoteDescription(desc);
  }

  Future<void> handleOffer(Map<String, dynamic> description) async {
    var desc = RTCSessionDescription(description['sdp'], description['type']);
    await localPeer.setRemoteDescription(desc);

    var answer = await localPeer.createAnswer({'offerToReceiveVideo': 1});
    await localPeer.setLocalDescription(answer);

    String msg = jsonEncode({'type':'answer', 'data': answer.toMap(), 'from': socketId});
    channel.sink.add(msg);
  }

  Future<MediaStream> getUserMedia() async {
    MediaStream stream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': {
      'mandatory': {
        'minWidth':
        '640', // Provide your own width, height and frame rate here
        'minHeight': '480',
        'minFrameRate': '30',
      },
      'facingMode': 'user',
      'optional': [],
    }});
    return stream;
  }

  Future<void> call() async {
    var offer = await localPeer.createOffer({'offerToReceiveVideo': 1});
    await localPeer.setLocalDescription(offer);
    String msg = jsonEncode({'type':'offer', 'data': offer.toMap(), 'from': socketId});
    channel.sink.add(msg);
  }

}