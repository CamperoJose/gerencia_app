import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:typed_data'; // Importa esta librería
import 'package:image/image.dart' as img;
import 'dart:convert'; // Para decodificar el JSON

class DisplayPhotoScreen extends StatefulWidget {
  final String imagePath;
  final String dateTime;

  const DisplayPhotoScreen({
    Key? key,
    required this.imagePath,
    required this.dateTime,
  }) : super(key: key);

  @override
  _DisplayPhotoScreenState createState() => _DisplayPhotoScreenState();
}

class _DisplayPhotoScreenState extends State<DisplayPhotoScreen> {
  String _plateNumber = "Esperando resultado...";
  String _imageUrl = "";
  bool _loading = false;
  bool _loadingImageFromServer = false; // Indica si se está cargando la imagen del servidor
  String _plateStatus = ""; // Estado de la placa

  // Lista de placas registradas
  final List<String> _registeredPlates = ["5184XKA", "6363BKE"];

  Future<void> _detectLicensePlate() async {
    setState(() {
      _loading = true;
    });

    var url = Uri.parse('http://172.20.10.2:8000/detect-license-plate/');
    var request = http.MultipartRequest('POST', url);

    // Convertir la imagen a formato JPEG
    File imageFile = File(widget.imagePath);
    Uint8List imageBytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);

    if (image != null) {
      // Cambiando la extensión a .jpg
      List<int> jpegData = img.encodeJpg(image, quality: 100); // 100 es la calidad máxima
      var jpegFile = File('${imageFile.parent.path}/temp_image.jpg'); // Asegúrate de que la extensión sea .jpg
      await jpegFile.writeAsBytes(jpegData);

      // Agregar el archivo JPEG al request
      request.files.add(await http.MultipartFile.fromPath('file', jpegFile.path));

      try {
        var response = await request.send();
        var responseData = await http.Response.fromStream(response);

        if (response.statusCode == 200) {
          var jsonResponse = json.decode(responseData.body);

          if (jsonResponse['license_plate_data'] != null) {
            setState(() {
              _plateNumber = jsonResponse['license_plate_data']['plate_number'] ?? "No se encontró la placa";
              _imageUrl = jsonResponse['image_url']?.replaceAll('localhost', '172.20.10.2') ?? "";
            });
            await _checkPlateAndControlGate(_plateNumber); // Verificar placa y controlar compuerta
          } else {
            setState(() {
              _plateNumber = "No se detectó placa";
            });
          }
        } else {
          setState(() {
            _plateNumber = 'Error al detectar placa: ${response.statusCode}';
          });
        }
      } catch (e) {
        setState(() {
          _plateNumber = 'Error: $e';
        });
      } finally {
        setState(() {
          _loading = false;
        });
        await jpegFile.delete();
      }
    } else {
      setState(() {
        _plateNumber = 'Error al procesar la imagen';
        _loading = false;
      });
    }
  }

  Future<void> _checkPlateAndControlGate(String plateNumber) async {
    if (_registeredPlates.contains(plateNumber)) {
      setState(() {
        _plateStatus = "(Placa registrada)"; // Estado de la placa
      });
      // Mostrar mensaje de abriendo compuerta
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Abriendo compuerta...')),
      );
      await _openGate(); // Abrir compuerta
      await Future.delayed(const Duration(seconds: 10)); // Esperar 10 segundos
      await _closeGate(); // Cerrar compuerta
    } else {
      setState(() {
        _plateStatus = "(Placa no registrada)"; // Estado de la placa
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Placa no registrada.')),
      );
    }
  }

  Future<void> _openGate() async {
    final response = await http.get(Uri.parse('http://172.20.10.3/open'));
    if (response.statusCode == 200) {
      // Compuerta abierta, mostrar mensaje
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir la compuerta: ${response.statusCode}')),
      );
    }
  }

  Future<void> _closeGate() async {
    final response = await http.get(Uri.parse('http://172.20.10.3/close'));
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compuerta cerrada.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar la compuerta: ${response.statusCode}')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _detectLicensePlate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado de la Placa'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                'Foto tomada el ${widget.dateTime}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              // Imagen original
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Image.file(
                      File(widget.imagePath),
                      height: 300, // Aumenta la altura para una mejor visualización
                      width: 300, // Aumenta el ancho para una mejor visualización
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: 10),
                    const Text("Imagen Original", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Imagen del servidor
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _loadingImageFromServer
                        ? const CircularProgressIndicator() // Mostrar indicador de carga
                        : (_imageUrl.isNotEmpty
                            ? Image.network(
                                _imageUrl,
                                height: 300, // Aumenta la altura para una mejor visualización
                                width: 300, // Aumenta el ancho para una mejor visualización
                                fit: BoxFit.cover,
                                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                          : null,
                                    ),
                                  );
                                },
                              )
                            : const SizedBox()), // Cambia el texto a un SizedBox para evitar el mensaje cuando no hay URL
                    const SizedBox(height: 10),
                    const Text("Imagen Procesada", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Mostrar número de placa y su estado
              Text(
                'Número de Placa:\n$_plateNumber $_plateStatus',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _plateStatus.contains("registrada") ? Colors.green : Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: _openGate,
                    child: const Text('Abrir Compuerta'),
                  ),
                  ElevatedButton(
                    onPressed: _closeGate,
                    child: const Text('Cerrar Compuerta'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
