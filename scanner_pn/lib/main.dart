// Importación de librerías
// ignore_for_file: prefer_const_constructors, library_private_types_in_public_api, use_key_in_widget_constructors

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// Función main
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Inicializar aplicación junto a los servicios de Firebase
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

// Widget estático de la aplicación
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scanner de texto',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ImagePickerPage(),
    );
  }
}

// Widgets dinámicos de la aplicación
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
      _extractedText = ''; // Se vacía la variable en caso de que se quiera seleccionar otra imagen
    });

    _extractTextFromImage();
  }
  
  // Extraemos el texto de la imagen
  Future<void> _extractTextFromImage() async {
    if (_imageFile == null) return;

    final inputImage = InputImage.fromFile(_imageFile!);
    final textRecognizer = TextRecognizer();
    final text = await textRecognizer.processImage(inputImage);

    setState(() {
      _extractedText = text.text;
    });
    
    // Se cierra la entrada de imagen
    await textRecognizer.close();

    // Comparar el texto extraído con documentos en Firestore
    await _compareWithFirestore(text.text);
  }

  Future<void> _compareWithFirestore(String extractedText) async {
    final usersCollection = FirebaseFirestore.instance.collection('users');
    final querySnapshot = await usersCollection.get();
  
    // Se buscará en todos los documentos de la colección si hay alguna coincidencia
    for (QueryDocumentSnapshot document in querySnapshot.docs) {
      final cedula = document['Cédula'];
      final nombre = document['Nombre'];
    
      if (extractedText.trim() == 'Cédula: $cedula\nNombre: $nombre'.trim()) {
        // Coincidencia encontrada
        _showConfirmationMessage();
        return;
      }
    }

    // No se encontró ninguna coincidencia
    _showNoConfirmationMessage();
  }
  
  // Muestra el mensaje de confirmación
  void _showConfirmationMessage() {
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

  // Muestra el mensaje de error
  void _showNoConfirmationMessage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text('La información no coincide con ningún usuario de la base de datos.'),
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
        title: Text('Scanner de Texto'),
      ),
      body: Center(
        child: _imageFile == null
            ? Text('No ha seleccionado ninguna imagen')
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.file(_imageFile!),
                  SizedBox(height: 20),
                  Text(
                    'Texto Extraído:',
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
            tooltip: 'Tomar Foto',
            child: Icon(Icons.camera),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () => _pickImage(ImageSource.gallery),
            tooltip: 'Seleccionar Imagen',
            child: Icon(Icons.photo_library),
          ),
        ],
      ),
    );
  }
}