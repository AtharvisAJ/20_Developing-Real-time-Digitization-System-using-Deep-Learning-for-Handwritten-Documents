import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';


Future<void> saveWordFile(String base64String) async {
  // Decode the base64 string into a byte list
  List<int> bytes = base64.decode(base64String);

  // Get the directory for storing files
  final Directory appDocDir = await getApplicationDocumentsDirectory();
  final String appDocPath = appDocDir.path;

  // Write the bytes to a file in the app documents directory
  final File file = File('$appDocPath/temp.docx');
  await file.writeAsBytes(bytes);

  // Open the file using the platform's default application for .docx files
  OpenFile.open('$appDocPath/temp.docx');
}



class Screen1 extends StatefulWidget {
  final CameraDescription camera;

  const Screen1({
     Key? key,
    required this.camera,
  }) : super(key: key);

  @override
  _Screen1State createState() => _Screen1State();
}

class _Screen1State extends State<Screen1> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  int numLines = 6;


  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.ultraHigh,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double gridHeight = MediaQuery.of(context).size.height * 0.8;

    double X = (MediaQuery.of(context).size.width / (numLines+1)).ceilToDouble();
    double lineWidth = 1.0;

    List<Widget> verticalLines = List.generate(numLines, (index) {
      return Positioned(
        left: X + index * (X + lineWidth),
        child: Container(
          width: lineWidth,
          height: gridHeight,
          color: Colors.red,
        ),
      );
    });

    int numHorizontalLines = (gridHeight - X) ~/ (X + lineWidth);
    List<Widget> horizontalLines = List.generate(numHorizontalLines+1, (index) {
      return Positioned(
        top: X + index * (X + lineWidth),
        child: Container(
          height: lineWidth,
          width: gridHeight,
          color: Colors.red,
        ),
      );
    });

    Future<void> _getImageFromGallery(BuildContext context, int numLines) async {
      final pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final image = File(pickedFile.path);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ImageScreen(
                  image: FileImage(image),
                  numLines: numLines,
                ),
          ),
        );
      }
    }

    bool _showLines = true;



    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return SingleChildScrollView(
              child: Column(children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.1,
                ),
                Stack(
                  children: <Widget>[
                    Container(
                      height: gridHeight,
                      child: CameraPreview(_controller),
                    ),
                    if (_showLines) ...verticalLines,
                    if (_showLines) ...horizontalLines,
                  ],
                ),
                GestureDetector(
                  onTap: () {},
                  child: Slider(
                    value: numLines.toDouble(),
                    min: 6,
                    max: 12,
                    divisions: 6,
                    label: numLines.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        numLines = value.toInt();
                      });
                    },
                  ),
                ),
                Row(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width*0.05,
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.1,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () async {
                          await _getImageFromGallery(context, numLines);
                        },
                        child: const Text(
                          'Gallery',
                          style: TextStyle(
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue,
                              decorationThickness: 2,
                              fontSize: 25.0),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width*0.01,
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.1,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () async {
                          final imageFile = await _controller.takePicture();
                          final bytes = await imageFile.readAsBytes();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ImageScreen(image: MemoryImage(bytes),numLines: numLines),
                            ),
                          );
                        },
                        child: Text('Capture\nScreenshot',
                          style: TextStyle(
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue,
                              decorationThickness: 2,
                              fontSize: 25.0
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width*0.01,
                    ),



                  ],
                ),

              ])
            );

          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }}

class ImageScreen extends StatefulWidget {
  final ImageProvider<Object> image;
  final int numLines;

  const ImageScreen({Key? key, required this.image,required this.numLines}) : super(key: key);

  @override
  _ImageScreenState createState() => _ImageScreenState(numLines);
}

class _ImageScreenState extends State<ImageScreen> {
   int numLines;

  _ImageScreenState(this.numLines);

  void shareImage(String base64Image,double X) async {
    // Convert the base64 string to a list of bytes
    final bytes = base64Decode(base64Image);
    // Create a temporary file with the image data
    final tempDir = await getTemporaryDirectory();
    final file = await new File('${tempDir.path}/image.png').create();
    await file.writeAsBytes(bytes);

    // Share the image file
    Share.shareFiles([file.path], text: X.toString());
  }

  void sendImage(String base64Image,double X) async {
    final url = Uri.parse('https://grid-kkbzhlecya-el.a.run.app');
    var response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({'base64_string': base64Image,'X':X}));
    final String responseData = jsonDecode(response.body)['word_file'];
    // ignore_for_file: avoid_print
    print(responseData);
    await saveWordFile(responseData);

  }
  @override
  Widget build(BuildContext context) {
    final _globalKey = GlobalKey();
    double gridHeight = MediaQuery.of(context).size.height * 0.8;

    double X = (MediaQuery.of(context).size.width / (numLines+1)).ceilToDouble();
    double lineWidth = 1.0;

    List<Widget> verticalLines = List.generate(numLines, (index) {
      return Positioned(
        left: X + index * (X + lineWidth),
        child: Container(
          width: lineWidth,
          height: gridHeight,
          color: Colors.red,
        ),
      );
    });

    int numHorizontalLines = (gridHeight - X) ~/ (X + lineWidth);
    List<Widget> horizontalLines = List.generate(numHorizontalLines+1, (index) {
      return Positioned(
        top: X + index * (X + lineWidth),
        child: Container(
          height: lineWidth,
          width: gridHeight,
          color: Colors.red,
        ),
      );
    });
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.1,
              ),


              RepaintBoundary(
                key: _globalKey,
                child: Stack(
                  children: <Widget>[
                    SizedBox(
                      height: gridHeight,
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.8,
                        child: Image(image: widget.image),
                      ),
                    ),
                    ...verticalLines,
                    ...horizontalLines,
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Slider(
                  value: numLines.toDouble(),
                  min: 6,
                  max: 12,
                  divisions: 6,
                  label: numLines.round().toString(),
                  onChanged: (double value) {
                    setState(() {
                      numLines = value.toInt();
                    });
                  },
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.1,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () async {
                    RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
                    ui.Image image = await boundary.toImage();
                    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                    Uint8List pngBytes = byteData!.buffer.asUint8List();
                    String base64Image = base64Encode(pngBytes);
                    print(base64Image);
                    sendImage(base64Image,X);
                  },
                  child: Text('Confirm'),
                ),
              ),
            ]
        ),
      )

    );
  }
}