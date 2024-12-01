import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Herb Identification App',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  io.File? _imageFile;
  Uint8List? _webImage;
  final picker = ImagePicker();

  Future<void> _importImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (kIsWeb) {
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
        });
      }
    } else {
      setState(() {
        if (pickedFile != null) {
          _imageFile = io.File(pickedFile.path);
        } else {
          print('No image selected.');
        }
      });
    }
  }

  Future<void> _takePicture() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (kIsWeb) {
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
        });
      }
    } else {
      setState(() {
        if (pickedFile != null) {
          _imageFile = io.File(pickedFile.path);
        } else {
          print('No image captured.');
        }
      });
    }
  }

  Future<void> _scanImage() async {
    if (kIsWeb && _webImage != null) {
      await _sendToServer(_webImage!);
    } else if (_imageFile != null) {
      final bytes = await _imageFile!.readAsBytes();
      await _sendToServer(bytes);
    } else {
      print('No image selected for scanning.');
    }
  }

  Future<void> _sendToServer(Uint8List bytes) async {
    final url = Uri.parse('http://192.168.239.128:5000/upload');
    final request = http.MultipartRequest('POST', url)
      ..files.add(http.MultipartFile.fromBytes('image', bytes,
          filename: 'herb_image.jpg'));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final result = jsonDecode(responseData);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultPage(
              herbName: result['prediction'],
              benefits: result['benefits'],
            ),
          ),
        );
      } else {
        print('Failed to upload image. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('YMPV Herb Identification'),
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/background_image.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Main Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  width: 300,
                  height: 300,
                  color: Colors.grey[200]?.withOpacity(0.7),
                  child: _imageFile == null && _webImage == null
                      ? Center(
                          child: Text('புகைப்படம் தேர்ந்தெடுக்கப்படவில்லை'))
                      : kIsWeb
                          ? Image.memory(_webImage!)
                          : Image.file(_imageFile!),
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _importImage,
                  icon: Icon(Icons.upload),
                  label: Text('பதிவேற்றம் செய்'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    textStyle: TextStyle(fontSize: 16),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _takePicture,
                  icon: Icon(Icons.camera_alt),
                  label: Text('புகைப்படம் எடு'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    textStyle: TextStyle(fontSize: 16),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _scanImage,
                  icon: Icon(Icons.search),
                  label: Text('சமர்ப்பி'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    textStyle: TextStyle(fontSize: 16),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ResultPage extends StatelessWidget {
  final String herbName;
  final String benefits;

  ResultPage({required this.herbName, required this.benefits});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('மூலிகையின் விபரங்கள்')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('மூலிகை: $herbName',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('நன்மைகள்:', style: TextStyle(fontSize: 18)),
            Text(benefits, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
