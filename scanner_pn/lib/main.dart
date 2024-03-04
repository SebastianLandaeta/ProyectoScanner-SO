import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scanner de Partidas de Nacimiento',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ImagePickerPage(),
    );
  }
}

class ImagePickerPage extends StatefulWidget {
  @override
  _ImagePickerPageState createState() => _ImagePickerPageState();
}

class _ImagePickerPageState extends State<ImagePickerPage> {
  File? _imageFile;
  String _extractedText = '';

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    setState(() {
      _imageFile = File(pickedFile!.path);
      _extractedText = ''; // Reset extracted text when a new image is picked
    });

    _extractTextFromImage();
  }

Future<void> _extractTextFromImage() async {
  if (_imageFile == null) return;

  final inputImage = InputImage.fromFile(_imageFile!);
  final textRecognizer = TextRecognizer();
  final text = await textRecognizer.processImage(inputImage);

  setState(() {
    _extractedText = text.text;
  });

  await textRecognizer.close();

  // Comparar el texto extraído con documentos en Firestore
  await _compareWithFirestore(text.text);
}

Future<void> _compareWithFirestore(String extractedText) async {
  final usersCollection = FirebaseFirestore.instance.collection('users');
  final querySnapshot = await usersCollection.get();

  for (QueryDocumentSnapshot document in querySnapshot.docs) {
    final cedula = document['Cédula'];
    final nombre = document['Nombre'];
    
    print('$cedula');
    print('$nombre');
    print('$extractedText');

    if (extractedText.trim() == 'Cédula: $cedula\nNombre: $nombre'.trim()) {
      // Coincidencia encontrada
      _showConfirmationMessage();
      return;
    }
  }

  // No se encontró ninguna coincidencia
  _showNoConfirmationMessage();
}

void _showConfirmationMessage() {
  // Muestra el mensaje de confirmación
  // Puedes usar showDialog, SnackBar, o cualquier otro método que prefieras
  // Ejemplo:
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Confirmación'),
      content: Text('El texto coincide con un usuario en la base de datos.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('OK'),
        ),
      ],
    ),
  );
}

void _showNoConfirmationMessage() {
  // Muestra el mensaje de no confirmación
  // Ejemplo:
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('No Confirmación'),
      content: Text('El texto no coincide con ningún usuario en la base de datos.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('OK'),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Text Recognition Example'),
      ),
      body: Center(
        child: _imageFile == null
            ? Text('No image selected')
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.file(_imageFile!),
                  SizedBox(height: 20),
                  Text(
                    'Extracted Text:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _extractedText,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _pickImage(ImageSource.camera),
            tooltip: 'Take Photo',
            child: Icon(Icons.camera),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () => _pickImage(ImageSource.gallery),
            tooltip: 'Select Image',
            child: Icon(Icons.photo_library),
          ),
        ],
      ),
    );
  }
}