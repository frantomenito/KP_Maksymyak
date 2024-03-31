import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '_controller.dart';
import '_image_painter.dart';
import '_signature_painter.dart';
import 'delegates/text_delegate.dart';
import 'widgets/_color_widget.dart';
import 'widgets/_mode_widget.dart';
import 'widgets/_range_slider.dart';
import 'widgets/_text_dialog.dart';

export '_image_painter.dart';

///[ImagePainter] widget.
@immutable
class ImagePainter extends StatefulWidget {
  const ImagePainter._({
    Key? key,
    required this.image,
    required this.goBack,
    required this.saveImage,
    this.height,
    this.width,
    this.placeHolder,
    this.isScalable,
    this.brushIcon,
    this.clearAllIcon,
    this.colorIcon,
    this.undoIcon,
    this.isSignature = false,
    this.controlsAtTop = true,
    this.signatureBackgroundColor = Colors.white,
    this.colors,
    this.initialPaintMode,
    this.initialStrokeWidth,
    this.initialColor,
    this.onColorChanged,
    this.onStrokeWidthChanged,
    this.onPaintModeChanged,
    this.textDelegate,
    this.showControls = true,
    this.controlsBackgroundColor,
    this.optionSelectedColor,
    this.optionUnselectedColor,
    this.optionColor,
    this.onUndo,
    this.onClear,
  }) : super(key: key);

  ///Constructor for loading image from [File].
  factory ImagePainter.image(
    Image image, {
    required Key key,
    required void Function() saveImage,
    required void Function() goBack,
    double? height,
    double? width,
    bool? scalable,
    Widget? placeholderWidget,
    List<Color>? colors,
    Widget? brushIcon,
    Widget? undoIcon,
    Widget? clearAllIcon,
    Widget? colorIcon,
    PaintMode? initialPaintMode,
    double? initialStrokeWidth,
    Color? initialColor,
    ValueChanged<PaintMode>? onPaintModeChanged,
    ValueChanged<Color>? onColorChanged,
    ValueChanged<double>? onStrokeWidthChanged,
    TextDelegate? textDelegate,
    bool? controlsAtTop,
    bool? showControls,
    Color? controlsBackgroundColor,
    Color? selectedColor,
    Color? unselectedColor,
    Color? optionColor,
    VoidCallback? onUndo,
    VoidCallback? onClear,
  }) {
    return ImagePainter._(
      key: key,
      goBack: goBack,
      saveImage: saveImage,
      image: image,
      height: height,
      width: width,
      placeHolder: placeholderWidget,
      colors: colors,
      isScalable: scalable ?? false,
      brushIcon: brushIcon,
      undoIcon: undoIcon,
      colorIcon: colorIcon,
      clearAllIcon: clearAllIcon,
      initialPaintMode: initialPaintMode,
      initialColor: initialColor,
      initialStrokeWidth: initialStrokeWidth,
      onPaintModeChanged: onPaintModeChanged,
      onColorChanged: onColorChanged,
      onStrokeWidthChanged: onStrokeWidthChanged,
      textDelegate: textDelegate,
      controlsAtTop: controlsAtTop ?? true,
      showControls: showControls ?? true,
      controlsBackgroundColor: controlsBackgroundColor,
      optionSelectedColor: selectedColor,
      optionUnselectedColor: unselectedColor,
      optionColor: optionColor,
      onUndo: onUndo,
      onClear: onClear,
    );
  }
  final Image image;
  final void Function() saveImage;
  final void Function() goBack;

  ///Height of the Widget. Image is subjected to fit within the given height.
  final double? height;

  ///Width of the widget. Image is subjected to fit within the given width.
  final double? width;

  ///Widget to be shown during the conversion of provided image to [ui.Image].
  final Widget? placeHolder;

  ///Defines whether the widget should be scaled or not. Defaults to [false].
  final bool? isScalable;

  ///Flag to determine signature or image;
  final bool isSignature;

  ///Signature mode background color
  final Color signatureBackgroundColor;

  ///List of colors for color selection
  ///If not provided, default colors are used.
  final List<Color>? colors;

  ///Icon Widget of strokeWidth.
  final Widget? brushIcon;

  ///Widget of Color Icon in control bar.
  final Widget? colorIcon;

  ///Widget for Undo last action on control bar.
  final Widget? undoIcon;

  ///Widget for clearing all actions on control bar.
  final Widget? clearAllIcon;

  ///Define where the controls is located.
  ///`true` represents top.
  final bool controlsAtTop;

  ///Initial PaintMode.
  final PaintMode? initialPaintMode;

  //the initial stroke width
  final double? initialStrokeWidth;

  //the initial color
  final Color? initialColor;

  final ValueChanged<Color>? onColorChanged;

  final ValueChanged<double>? onStrokeWidthChanged;

  final ValueChanged<PaintMode>? onPaintModeChanged;

  //the text delegate
  final TextDelegate? textDelegate;

  ///It will control displaying the Control Bar
  final bool showControls;

  final Color? controlsBackgroundColor;

  final Color? optionSelectedColor;

  final Color? optionUnselectedColor;

  final Color? optionColor;

  final VoidCallback? onUndo;

  final VoidCallback? onClear;

  @override
  ImagePainterState createState() => ImagePainterState();
}

///
class ImagePainterState extends State<ImagePainter> {
  final _repaintKey = GlobalKey();
  ui.Image? _image;
  late Controller _controller;
  late final ValueNotifier<bool> _isLoaded;
  late final TextEditingController _textController;
  late final TransformationController _transformationController;
  late final TextEditingController _colorHexController;

  late final TextEditingController _redController;
  late final TextEditingController _greenController;
  late final TextEditingController _blueController;

  int _selectedSegment = 0;

  Tool _selectedTool = Tool.Pen; // Initially select the pen tool

  int _strokeMultiplier = 1;
  late TextDelegate textDelegate;
  @override
  void initState() {
    super.initState();
    _isLoaded = ValueNotifier<bool>(false);
    _controller = Controller();
    if (widget.isSignature) {
      _controller.update(
        mode: PaintMode.freeStyle,
        color: Colors.black,
      );
    } else {
      _controller.update(
        mode: widget.initialPaintMode,
        strokeWidth: widget.initialStrokeWidth,
        color: widget.initialColor,
      );
    }
    _resolveAndConvertImage();

    _textController = TextEditingController();
    _colorHexController = TextEditingController(text: "4CAF50");
    _transformationController = TransformationController();
    textDelegate = widget.textDelegate ?? TextDelegate();

    _redController = TextEditingController(text: "76");
    _greenController = TextEditingController(text: "175");
    _blueController = TextEditingController(text: "80");
  }

  @override
  void dispose() {
    _controller.dispose();
    _isLoaded.dispose();
    _textController.dispose();
    _colorHexController.dispose();
    _transformationController.dispose();

    _redController.dispose();
    _blueController.dispose();
    _greenController.dispose();

    super.dispose();
  }

  bool get isEdited => _controller.paintHistory.isNotEmpty;

  Size get imageSize =>
      Size(_image?.width.toDouble() ?? 0, _image?.height.toDouble() ?? 0);

  ///Converts the incoming image type from constructor to [ui.Image]
  Future<void> _resolveAndConvertImage() async {
    var byteData =
        await widget.image.image.getBytes(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw ("Image couldn't be resolved");
    } else {
      _image = await _convertImage(byteData);
      _setStrokeMultiplier();
    }
  }

  ///Dynamically sets stroke multiplier on the basis of widget size.
  ///Implemented to avoid thin stroke on high res images.
  _setStrokeMultiplier() {
    if ((_image!.height + _image!.width) > 1000) {
      _strokeMultiplier = (_image!.height + _image!.width) ~/ 1000;
    }
    _controller.update(strokeMultiplier: _strokeMultiplier);
  }

  ///Completer function to convert asset or file image to [ui.Image] before drawing on custompainter.
  Future<ui.Image> _convertImage(Uint8List img) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(img, (image) {
      _isLoaded.value = true;
      return completer.complete(image);
    });
    return completer.future;
  }

  ///Completer function to convert network image to [ui.Image] before drawing on custompainter.
  Future<ui.Image> _loadNetworkImage(String path) async {
    final completer = Completer<ImageInfo>();
    final img = NetworkImage(path);
    img.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener((info, _) => completer.complete(info)));
    final imageInfo = await completer.future;
    _isLoaded.value = true;
    return imageInfo.image;
  }

  void _updateSliderValue(double value) {
    setState(() {
      _controller.setStrokeWidth(value);

      if (widget.onStrokeWidthChanged != null) {
        widget.onStrokeWidthChanged!(value);
      }
    });
  }

  Widget _buildToolButton(
      String assetPath, bool isSelected, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200), // Adjust the duration as needed
        curve: Curves.easeInOut,
        transform: isSelected
            ? Matrix4.translationValues(0, 30, 0)
            : Matrix4.translationValues(0, 80, 0),
        child: Image(image: AssetImage(assetPath)),
      ),
    );
  }

  Widget _buildToolbar() {
    if (widget.showControls) {
      return Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildToolButton(
                "assets/tool-pen.png", _controller.mode == PaintMode.freeStyle,
                () {
              setState(() {
                _controller.setMode(PaintMode.freeStyle); // Set selected tool
              });
            }),
            _buildToolButton(
                "assets/tool-lines.png", _controller.mode == PaintMode.line,
                () {
              setState(() {
                _controller.setMode(PaintMode.line); // Set selected tool
              });
            }),
            _buildToolButton(
                "assets/tool-eraser.png", _controller.mode == PaintMode.eraser,
                () {
              setState(() {
                _controller.setMode(PaintMode.eraser); // Set selected tool
              });
            }),
            // Add more tool buttons as needed
          ],
        ),
      );
    }

    return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final toolbarHeight = MediaQuery.of(context).size.height / 4;
    final toolbarWidth = MediaQuery.of(context).size.width / 1.5;

    return Scaffold(
      appBar: AppBar(
        title: (widget.controlsAtTop && widget.showControls)
            ? _buildControls()
            : SizedBox(height: 0, width: 0),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _isLoaded,
        builder: (_, loaded, __) {
          if (loaded) {
            return Stack(
              children: [
                _paintImage(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding:
                          EdgeInsets.symmetric(vertical: 20, horizontal: 5),
                          child: Column(
                            children: [
                              _colorPicker(),
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                  Border.all(color: Colors.white, width: 3),
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.close),
                                  color: Colors.white,
                                  onPressed: () {},
                                ),
                              ),
                            ],
                          ),
                        ),

                        Column(
                          children: [
                            SizedBox(
                              height: toolbarHeight,
                              width: toolbarWidth,
                              child: _buildToolbar(),
                            ),

                            Container(
                              height: 60,
                              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                              child: Center(
                                child: InstrumentsToggleButton(),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding:
                          EdgeInsets.symmetric(vertical: 20, horizontal: 5),
                          child: TrailingButtons(),
                        ),
                      ],
                    ),


                  ],
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: FractionallySizedBox(
                    heightFactor: 0.5,
                    child: VerticalSlider(onChanged: _updateSliderValue),
                  ),
                ),
              ],
            );
          } else {
            return Container(
              height: widget.height ?? double.maxFinite,
              width: widget.width ?? double.maxFinite,
              child: Center(
                child: widget.placeHolder ?? const CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }


  Widget TrailingButtons() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border:
            Border.all(color: Colors.white, width: 3),
          ),
          child: PopupMenuButton(
            color: Colors.black,
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            icon: Text(
              '+',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
            ),
            itemBuilder: (_) => _buildShapeOptionsPopup(),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border:
            Border.all(color: Colors.white, width: 3),
          ),
          child: IconButton(
            icon: Icon(Icons.save_alt),
            color: Colors.white,
            onPressed: () {
              widget.saveImage();
            },
          ),
        ),
      ],
    );
  }

  Widget InstrumentsToggleButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.all(Radius.circular(5))
      ),

      child: ToggleButtons(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width /
                4, // Set width for both buttons
            child: Center(child: Text('Instruments')),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width /
                4, // Set width for both buttons
            child: Center(child: Text('Filters')),
          ),
        ],
        onPressed: (int index) {
          setState(() {
            _selectedSegment = index;
          });
        },
        isSelected: [
          _selectedSegment == 0,
          _selectedSegment == 1
        ],
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.grey,
        selectedColor: Colors.white,
        fillColor: Colors
            .grey, // Change this to your desired color

        borderColor: Colors
            .grey, // Change this to your desired color
        borderWidth: 2, // Adjust as needed
        selectedBorderColor: Colors
            .grey, // Change this to your desired color


      ),
    )
    ;
  }

  ///paints image on given constrains for drawing if image is not null.
  Widget _paintImage() {
    return Container(
      color: Colors.black,
      height: widget.height ?? double.maxFinite,
      width: widget.width ?? double.maxFinite,
      child: Column(
        children: [
          Expanded(
            child: FittedBox(
              alignment: FractionalOffset.center,
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return InteractiveViewer(
                        transformationController: _transformationController,
                        maxScale: 2.4,
                        minScale: 1,
                        panEnabled: _controller.mode == PaintMode.none,
                        scaleEnabled: widget.isScalable!,
                        onInteractionUpdate: _scaleUpdateGesture,
                        onInteractionEnd: _scaleEndGesture,
                        child: Opacity(
                          opacity: 0.99,
                          child: CustomPaint(
                            size: imageSize,
                            willChange: true,
                            isComplex: true,
                            painter: DrawImage(
                              image: _image,
                              controller: _controller,
                            ),
                          ),
                        ));
                  },
                ),
              ),
            ),
          ),
          if (!widget.controlsAtTop && widget.showControls) _buildControls(),
          SizedBox(height: MediaQuery.of(context).padding.bottom)
        ],
      ),
    );
  }

  Widget _colorPicker() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return PopupMenuButton(
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          tooltip: textDelegate.changeColor,
          icon: widget.colorIcon ??
              Container(
                width: 25,
                height: 25,
                padding: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                  color: _controller.color,
                ),
              ),
          itemBuilder: (_) => [_showColorPicker()],
        );
      },
    );
  }

  List<PopupMenuItem> _buildShapeOptionsPopup() {
    return [
      PopupMenuItem(
        child: Icon(
          Icons.circle_outlined,
          color: Colors.white,
        ),
        onTap: () {
          _controller.setMode(PaintMode.circle); // Set selected tool
        },
      ),
      PopupMenuItem(
        child: Icon(
          Icons.crop_square_rounded,
          color: Colors.white,
        ),
        onTap: () {
          _controller.setMode(PaintMode.rect); // Set selected tool
        },
      ),
      PopupMenuItem(
        child: Icon(
          Icons.text_fields,
          color: Colors.white,
        ),
        onTap: () {
          _controller.setMode(PaintMode.text); // Set selected tool
          _openTextDialog();
        },
      ),
      PopupMenuItem(
        child: Icon(
          Icons.arrow_forward_rounded,
          color: Colors.white,
        ),
        onTap: () {
          _controller.setMode(PaintMode.arrow); // Set selected tool
        },
      ),
      // Add more shape options as needed
    ];
  }

  _scaleStartGesture(ScaleStartDetails onStart) {
    final _zoomAdjustedOffset =
        _transformationController.toScene(onStart.localFocalPoint);
    if (!widget.isSignature) {
      _controller.setStart(_zoomAdjustedOffset);
      _controller.addOffsets(_zoomAdjustedOffset);
    }
  }

  ///Fires while user is interacting with the screen to record painting.
  void _scaleUpdateGesture(ScaleUpdateDetails onUpdate) {
    final _zoomAdjustedOffset =
        _transformationController.toScene(onUpdate.localFocalPoint);
    _controller.setInProgress(true);
    if (_controller.start == null) {
      _controller.setStart(_zoomAdjustedOffset);
    }
    _controller.setEnd(_zoomAdjustedOffset);
    if (_controller.mode == PaintMode.freeStyle) {
      _controller.addOffsets(_zoomAdjustedOffset);
    }
    if (_controller.mode == PaintMode.eraser) {
      _controller.addOffsets(_zoomAdjustedOffset);
    }
    if (_controller.onTextUpdateMode) {
      _controller.paintHistory
          .lastWhere((element) => element.mode == PaintMode.text)
          .offsets = [_zoomAdjustedOffset];
    }
  }

  ///Fires when user stops interacting with the screen.
  void _scaleEndGesture(ScaleEndDetails onEnd) {
    _controller.setInProgress(false);
    if (_controller.start != null &&
            _controller.end != null &&
            _controller.mode == PaintMode.freeStyle ||
        _controller.mode == PaintMode.eraser) {
      if (_controller.mode == PaintMode.freeStyle) {
        _controller.addOffsets(null);
        _addFreeStylePoints(false);
        _controller.offsets.clear();
      }

      if (_controller.mode == PaintMode.eraser) {
        _controller.addOffsets(null);
        _addFreeStylePoints(true);
        _controller.offsets.clear();
      }
    } else if (_controller.start != null &&
        _controller.end != null &&
        _controller.mode != PaintMode.text) {
      _addEndPoints();
    }
    _controller.resetStartAndEnd();
  }

  void _addEndPoints() => _addPaintHistory(
        PaintInfo(
          offsets: <Offset?>[_controller.start, _controller.end],
          mode: _controller.mode,
          color: _controller.color,
          strokeWidth: _controller.scaledStrokeWidth,
          fill: _controller.fill,
        ),
      );

  void _addFreeStylePoints(bool isEraser) => _addPaintHistory(
        PaintInfo(
          offsets: <Offset?>[..._controller.offsets],
          mode: isEraser ? PaintMode.eraser : PaintMode.freeStyle,
          color: _controller.color,
          strokeWidth: _controller.scaledStrokeWidth,
        ),
      );

  ///Provides [ui.Image] of the recorded canvas to perform action.
  Future<ui.Image> _renderImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = DrawImage(image: _image, controller: _controller);
    final size = Size(_image!.width.toDouble(), _image!.height.toDouble());
    painter.paint(canvas, size);
    return recorder
        .endRecording()
        .toImage(size.width.floor(), size.height.floor());
  }

  PopupMenuItem _showOptionsRow() {
    return PopupMenuItem(
      enabled: false,
      child: Center(
        child: SizedBox(
          child: Wrap(
            children: paintModes(textDelegate)
                .map(
                  (item) => SelectionItems(
                    data: item,
                    isSelected: _controller.mode == item.mode,
                    selectedColor: widget.optionSelectedColor,
                    unselectedColor: widget.optionUnselectedColor,
                    onTap: () {
                      if (widget.onPaintModeChanged != null) {
                        widget.onPaintModeChanged!(item.mode);
                      }
                      _controller.setMode(item.mode);

                      Navigator.of(context).pop();
                      if (item.mode == PaintMode.text) {
                        _openTextDialog();
                      }
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  PopupMenuItem _showColorPicker() {
    return PopupMenuItem(
      enabled: false,
      child: Center(
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: (widget.colors ?? editorColors).map((color) {
                return ColorItem(
                  isSelected: color == _controller.color,
                  color: color,
                  onTap: () {
                    _updateColorInputs(color);
                    if (widget.onColorChanged != null) {
                      widget.onColorChanged!(color);
                    }

                    // Set selected color hex to the TextFormField
                    String hexColor = color.value
                        .toRadixString(16)
                        .substring(2)
                        .toUpperCase();
                    _colorHexController.text = '$hexColor';

                    // Set RGB values to corresponding TextFormFields
                    _redController.text = color.red.toString();
                    _greenController.text = color.green.toString();
                    _blueController.text = color.blue.toString();

                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _colorHexController,
              decoration: InputDecoration(
                labelText: 'Enter Color Hex',
                hintText: 'RRGGBB',
                border: OutlineInputBorder(),
              ),
              maxLength: 6, // Including the '#' character
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              onChanged: (value) {
                if (value.length == 6) {
                  Color? color = _convertHexToColor(value);
                  if (color != null) {
                    _updateColorInputs(color);
                  }
                }
              },
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _redController,
              decoration: InputDecoration(
                labelText: 'Red (0-255)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _updateColorFromRGB();
              },
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _greenController,
              decoration: InputDecoration(
                labelText: 'Green (0-255)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _updateColorFromRGB();
              },
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _blueController,
              decoration: InputDecoration(
                labelText: 'Blue (0-255)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _updateColorFromRGB();
              },
            ),
          ],
        ),
      ),
    );
  }

  ///Generates [Uint8List] of the [ui.Image] generated by the [renderImage()] method.
  ///Can be converted to image file by writing as bytes.
  Future<Uint8List?> exportImage() async {
    late ui.Image _convertedImage;

    _convertedImage = await _renderImage();

    final byteData =
        await _convertedImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  void _updateColorInputs(Color color) {
    // Update hex text field value
    String hexColor = color.value.toRadixString(16).substring(2).toUpperCase();
    _colorHexController.text = '$hexColor';

    // Update RGB text field values
    _redController.text = color.red.toString();
    _greenController.text = color.green.toString();
    _blueController.text = color.blue.toString();

    _controller.setColor(color);
  }

  Color? _convertHexToColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    try {
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      // Invalid hex format
      return null;
    }
  }

  void _updateColorFromRGB() {
    int red = int.tryParse(_redController.text) ?? 0;
    int green = int.tryParse(_greenController.text) ?? 0;
    int blue = int.tryParse(_blueController.text) ?? 0;
    if (red >= 0 &&
        red <= 255 &&
        green >= 0 &&
        green <= 255 &&
        blue >= 0 &&
        blue <= 255) {
      _updateColorInputs(Color.fromRGBO(red, green, blue, 1));
    }
  }

  void _addPaintHistory(PaintInfo info) {
    if (info.mode != PaintMode.none) {
      _controller.addPaintInfo(info);
    }
  }

  void _openTextDialog() {
    _controller.setMode(PaintMode.text);
    final fontSize = 6 * _controller.strokeWidth;
    TextDialog.show(
      context,
      _textController,
      fontSize,
      _controller.color,
      textDelegate,
      onFinished: (context) {
        if (_textController.text.isNotEmpty) {
          _addPaintHistory(
            PaintInfo(
              mode: PaintMode.text,
              text: _textController.text,
              offsets: [],
              color: _controller.color,
              strokeWidth: _controller.scaledStrokeWidth,
            ),
          );
          _textController.clear();
        }
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(4),
      color: Colors.black,
      child: Row(
        children: [
          // AnimatedBuilder(
          //   animation: _controller,
          //   builder: (_, __) {
          //     final icon = paintModes(textDelegate)
          //         .firstWhere((item) => item.mode == _controller.mode)
          //         .icon;
          //     return PopupMenuButton(
          //       tooltip: textDelegate.changeMode,
          //       shape: ContinuousRectangleBorder(
          //         borderRadius: BorderRadius.circular(40),
          //       ),
          //       icon: Icon(icon, color: widget.optionColor ?? Colors.grey[700]),
          //       itemBuilder: (_) => [_showOptionsRow()],
          //     );
          //   },
          // ),
          ListenableBuilder(
              listenable: _controller,
              builder: (BuildContext context, Widget? widget2) {
                return IconButton(
                  tooltip: textDelegate.undo,
                  icon: Icon(Icons.undo,
                      color: _controller.paintHistory.isNotEmpty
                          ? Colors.white
                          : Colors.white54),
                  onPressed: () {
                    widget.onUndo?.call();
                    _controller.undo();
                  },
                );
              }),
          const Spacer(),
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              if (_controller.canFill()) {
                return IconButton(
                  icon: Icon(
                    _controller.fill
                        ? Icons.square_rounded
                        : Icons.crop_square_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    _controller.update(fill: !_controller.fill);
                  },
                );
              } else {
                return const SizedBox();
              }
            },
          ),

          const Spacer(),
          ListenableBuilder(
              listenable: _controller,
              builder: (BuildContext context, Widget? widget2) {
                return IconButton(
                  tooltip: textDelegate.clearAllProgress,
                  icon: Text('Clear',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _controller.paintHistory.isNotEmpty
                              ? Colors.white
                              : Colors.white54)),
                  onPressed: () {
                    widget.onClear?.call();
                    _controller.clear();
                  },
                );
              }),
        ],
      ),
    );
  }
}

extension ImageTool on ImageProvider {
  Future<Uint8List?> getBytes(
      {ui.ImageByteFormat format = ui.ImageByteFormat.rawRgba}) async {
    final Completer<Uint8List?> completer = Completer<Uint8List?>();
    final ImageStreamListener listener = ImageStreamListener(
      (imageInfo, synchronousCall) async {
        final bytes = await imageInfo.image.toByteData(format: format);
        if (!completer.isCompleted) {
          completer.complete(bytes?.buffer.asUint8List());
        }
      },
    );

    final ImageStream imageStream = resolve(ImageConfiguration.empty);
    imageStream.addListener(listener);

    try {
      return await completer.future;
    } finally {
      imageStream.removeListener(listener);
    }
  }
}

class VerticalSlider extends StatefulWidget {
  final ValueChanged<double> onChanged;

  VerticalSlider({required this.onChanged});

  @override
  _VerticalSliderState createState() => _VerticalSliderState();
}

class _VerticalSliderState extends State<VerticalSlider> {
  double _currentSliderValue = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: RotatedBox(
          quarterTurns: 3,
          child: SliderTheme(
            data: SliderThemeData(
                thumbColor: Colors.white,
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white54),
            child: Slider(
              value: _currentSliderValue, // Provide the value here
              min: 0,
              max: 10,
              divisions: 100,

              onChanged: (double value) {
                _currentSliderValue = value;

                widget.onChanged(
                    value); // Call the callback function with the updated value
              },
            ),
          )),
    );
  }
}

enum Tool {
  Pen,
  Lines,
  Eraser,
  // Add more tools as needed
}
