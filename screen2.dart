import 'dart:async';
import 'dart:convert';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

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



class ImageListScreen extends StatefulWidget {
  const ImageListScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ImageListScreenState createState() => _ImageListScreenState();
}

class _ImageListScreenState extends State<ImageListScreen> {
  final List<String> _imageList = [];

  get pickedImage => null;

  Future _getImageFromCamera() async {
    // ignore: deprecated_member_use
    var image = await ImagePicker().getImage(source: ImageSource.camera);
    if (image != null) {
      List<int> imageBytes = await File(image.path).readAsBytes();
      String base64Image = base64Encode(imageBytes);
      setState(() {
        _imageList.add(base64Image);
      });
    }
  }

  Future _getImageFromGallery() async {
    // ignore: deprecated_member_use
    var image = await ImagePicker().getImage(source: ImageSource.gallery);
    if (image != null) {
      List<int> imageBytes = await File(image.path).readAsBytes();
      String base64Image = base64Encode(imageBytes);
      setState(() {
        _imageList.add(base64Image);
      });
    }
  }

  void _clearImageList() async {
    final payload = jsonEncode({'base64_strings': _imageList});

    // Send POST request to Cloud Run service
    final url = Uri.parse('https://ocr-kkbzhlecya-el.a.run.app');
    final headers = {'Content-Type': 'application/json'};
    final response = await http.post(headers: headers, url, body: payload);
    final String responseData = jsonDecode(response.body)['word_file'];
    // ignore_for_file: avoid_print
    print(responseData);
    await saveWordFile(responseData);
    setState(() {
      _showImages = false;

      Timer(const Duration(seconds: 10), () {
        setState(() {
          _showImages = true;
        });
      });
      _imageList.clear();
    });
  }

  bool _showImages = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'SCRIPT SCANNER',
            style: TextStyle(
              fontSize: 30.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_showImages)
            Expanded(
              child: ListView.builder(
                itemCount: _imageList.length,
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.memory(
                      base64Decode(_imageList[index]),
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          SizedBox(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(
                    width: 150,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: _getImageFromCamera,
                      child: const Text(
                        'Camera',
                        style: TextStyle(
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.blue,
                            decorationThickness: 2,
                            fontSize: 25.0),
                      ),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.all(10)),
                  SizedBox(
                    width: 150,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: _getImageFromGallery,
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
                  const Padding(padding: EdgeInsets.all(10)),

                  SizedBox(
                    width: 150,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: _clearImageList,
                      child: const Text(
                        'Done',
                        style: TextStyle(
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.blue,
                            decorationThickness: 2,
                            fontSize: 25.0),
                      ),
                    ),
                  ) // ignore: sized_box_for_whitespace
                ],
              )),
          const Padding(padding: EdgeInsets.all(10)),
        ],
      ),
    );
  }
}