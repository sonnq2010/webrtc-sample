import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class DualVideoLayout extends StatefulWidget {
  final RTCVideoRenderer local;
  final RTCVideoRenderer remote;
  const DualVideoLayout({super.key, required this.local, required this.remote});

  @override
  State<DualVideoLayout> createState() => _DualVideoLayoutState();
}

class _DualVideoLayoutState extends State<DualVideoLayout> {

  bool defaultView = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RTCVideoView(defaultView ? widget.local : widget.remote, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,),
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    defaultView = !defaultView;
                  });
                },
                child: SizedBox(
                    width: 130,
                    height: 200,
                    child: RTCVideoView(defaultView ? widget.remote : widget.local, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,)),
              ),
            ),
          ),
        )
      ],
    );
  }
}

