import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:botovod/SourceManager.dart';
import 'package:botovod/image_painter_custom/lib/image_painter.dart';

class DrawingView extends StatefulWidget {
  @override
  _DrawingViewState createState() => _DrawingViewState();
}

class _DrawingViewState extends State<DrawingView> {
  final _imageKey = GlobalKey<ImagePainterState>();
  var canGoBack = false;

  void saveImage() async {
    final image = await _imageKey.currentState?.exportImage();




    // final directory = (await getApplicationDocumentsDirectory()).path;
    // await Directory('$directory/sample').create(recursive: true);
    // final fullPath =
    //     '$directory/sample/${DateTime.now().millisecondsSinceEpoch}.png';
    // final imgFile = File('$fullPath');
    // if (image != null) {
    //   imgFile.writeAsBytesSync(image);
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       backgroundColor: Colors.grey[700],
    //       padding: const EdgeInsets.only(left: 10),
    //       content: Row(
    //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //         children: [
    //           const Text("Image Exported successfully.",
    //               style: TextStyle(color: Colors.white)),
    //           TextButton(
    //             onPressed: () => OpenFile.open("$fullPath"),
    //             child: Text(
    //               "Open",
    //               style: TextStyle(
    //                 color: Colors.blue[200],
    //               ),
    //             ),
    //           )
    //         ],
    //       ),
    //     ),
    //   );
    // }
  }

  void goBack() {

  }

  @override
  Widget build(BuildContext context) {
    final drawingImage = ModalRoute.of(context)!.settings.arguments as DrawingImage;

    return WillPopScope(child: Scaffold(
      body: ImagePainter.image(
        drawingImage.image,
        goBack: goBack,
        saveImage: saveImage,
        key: _imageKey,
        scalable: true,
        initialStrokeWidth: 2,
        textDelegate: TextDelegate(),
        initialColor: Colors.green,
        initialPaintMode: PaintMode.line,
      ),
    ),

    onWillPop: () async {
      return !Navigator.of(context).userGestureInProgress; // Disable back navigation
    });
  }
}