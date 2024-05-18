import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:myapp/dual_video_layout.dart';
import 'package:myapp/signaling.dart';


class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {

 final _sginaling = DirectSignaling(host: 'ws://tdtu.manh.store');
 var localRenderer = RTCVideoRenderer();
 var remoteRenderer = RTCVideoRenderer();

 var calling = false;
 var state = RTCPeerConnectionState.RTCPeerConnectionStateClosed;

 @override
  void initState() {
    super.initState();
    initializeWebRtc();
  }

 void initializeWebRtc() async {
   await localRenderer.initialize();
   await remoteRenderer.initialize();
   await _sginaling.initalize(
       onLocalStreamAvailable: _localStreamAvailable,
       onRemoteStreamAvailable: _remoteStreamAvailable,
       onConnectionState: _onConnectionState
   );
 }

  void _localStreamAvailable(MediaStream stream) // display local stream
  {
    setState(() {
      localRenderer.srcObject = stream;
    });
  }

 void _remoteStreamAvailable(MediaStream stream) // display remote stream
 {
    setState(() {
      remoteRenderer.srcObject = stream;
    });
 }

 void _onConnectionState(RTCPeerConnectionState state) {
   print(state);
   if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected ||
       state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
       state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
     calling = false;
   }
   setState(() {
     this.state = state;
   });
 }

 @override
 void dispose() {
   localRenderer.dispose();
   remoteRenderer.dispose();
   super.dispose();
 }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DualVideoLayout(
        local: localRenderer,
        remote: remoteRenderer,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: calling ? null : () {
          setState(() {
            calling = true;
          });
          _sginaling.call();
        },
        child: calling ? const CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 1,
        ) : const Icon(Icons.call),
      ),
    );
  }

}


