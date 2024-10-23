import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'display_photo_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto(BuildContext context) async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      DateTime now = DateTime.now();
      String formattedDate =
          "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}:${now.second}";
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DisplayPhotoScreen(
            imagePath: photo.path,
            dateTime: formattedDate,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      extendBodyBehindAppBar: true, 
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/background.png', 
              fit: BoxFit.cover, 
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.3),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[

                const Text(
                  'Identificador de Placas',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 4),
                        blurRadius: 10,
                        color: Colors.black38,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                Hero(
                  tag: 'logo',
                  child: Image.asset(
                    'assets/plate_icon.png',
                    height: 200,

                  ),
                ),

                const SizedBox(height: 40),
                // Botón personalizado
                ElevatedButton(
                  onPressed: () => _takePhoto(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 20),
                    backgroundColor: const Color.fromARGB(255, 5, 86, 130), 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), 
                    ),
                    shadowColor: Colors.black45,
                    elevation: 10,
                  ),
                  child: const Text(
                    'Verificar Placa',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
