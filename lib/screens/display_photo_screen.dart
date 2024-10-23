import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class DisplayPhotoScreen extends StatelessWidget {
  final String imagePath;
  final String dateTime;

  const DisplayPhotoScreen({
    Key? key,
    required this.imagePath,
    required this.dateTime,
  }) : super(key: key);

  Future<void> _openDoor() async {
    try {
      var response = await http.get(Uri.parse('http://172.20.10.2/open'));
      if (response.statusCode == 200) {
        print("Puerta abierta");
      } else {
        print("Error al abrir la puerta: ${response.statusCode}");
      }
    } catch (e) {
      print("Error al abrir la puerta: $e");
    }
  }

  Future<void> _closeDoor() async {
    try {
      var response = await http.get(Uri.parse('http://172.20.10.2/close'));
      if (response.statusCode == 200) {
        print("Puerta cerrada");
      } else {
        print("Error al cerrar la puerta: ${response.statusCode}");
      }
    } catch (e) {
      print("Error al cerrar la puerta: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Foto tomada'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.file(File(imagePath)),
            const SizedBox(height: 20),
            Text(
              'Esta foto se tomó el $dateTime',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _openDoor,
              child: const Text('Abrir Puerta'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _closeDoor,
              child: const Text('Cerrar Puerta'),
            ),
          ],
        ),
      ),
    );
  }
}
