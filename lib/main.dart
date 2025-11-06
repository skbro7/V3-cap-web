import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_html/html.dart' as html; // The perfect tool for web downloads

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Enforces portrait mode on mobile browsers that support it.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const V3CapApp());
}

class V3CapApp extends StatelessWidget {
  const V3CapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'V3 CAP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isProcessing = false;
  String? _lastThumbnailUrl;
  
  // Your Adsterra Smartlink is perfectly placed.
  final Uri _adUrl = Uri.parse('https://www.effectivegatecpm.com/euwk6tje?key=aeab73654d8b3c188f6d4ed2b26fdfda');

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception("No camera found.");
    }
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    return _controller!.initialize();
  }

  // The main function, now clean and robust.
  Future<void> _onCaptureAndDownload() async {
    if (_isProcessing || _controller == null || !_controller!.value.isInitialized) return;
    
    try {
      setState(() => _isProcessing = true);

      // Step 1: Show the Ad in a new tab. Clean and simple.
      await launchUrl(_adUrl, webOnlyWindowName: '_blank');

      // Step 2: Take the picture.
      final XFile rawFile = await _controller!.takePicture();
      final bytes = await rawFile.readAsBytes();

      // Step 3: Apply the filter.
      final filteredBytes = await _processImage(bytes);

      // Step 4: Trigger the download in the browser.
      _triggerDownload(filteredBytes, 'v3-cap-image.jpg');

      if (mounted) {
        setState(() {
          _lastThumbnailUrl = rawFile.path;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // Helper function to trigger download on web. This is the professional way.
  void _triggerDownload(Uint8List data, String downloadName) {
    final base64 = html.base64Encode(data);
    final anchor = html.AnchorElement(href: 'data:application/octet-stream;base64,$base64')
      ..setAttribute("download", downloadName)
      ..click();
  }

  Future<Uint8List> _processImage(Uint8List bytes) async {
    img.Image? originalImage = img.decodeImage(bytes);
    img.Image filteredImage = _applyCineV3Filter(originalImage!);
    return Uint8List.fromList(img.encodeJpg(filteredImage, quality: 95));
  }

  // Filter logic remains the same, as it's perfect.
  static img.Image _applyCineV3Filter(img.Image image) {
    img.adjustColor(image, saturation: 1.12, contrast: 1.03);
    img.brightness(image, 2);
    img.sharpen(image, amount: 36);
    img.contrast(image, contrast: 1.60);
    img.brightness(image, 3);
    img.adjustColor(image, highlights: -2.0, shadows: 6.0);
    _adjustLevels(image, black: 7, white: 252);
    _adjustTemperature(image, -6);
    img.adjustColor(image, hue: -4.0);
    return image;
  }

  static void _adjustTemperature(img.Image image, double amount) {
    final double rAdj = 1.0 - amount / 100.0;
    final double bAdj = 1.0 + amount / 100.0;
    for (final pixel in image) {
      pixel.r = (pixel.r * rAdj).clamp(0, 255).toInt();
      pixel.b = (pixel.b * bAdj).clamp(0, 255).toInt();
    }
  }

  static void _adjustLevels(img.Image image, {int black = 0, int white = 255}) {
    final int range = white - black;
    if (range <= 0) return;
    final double scale = 255.0 / range;
    for (final pixel in image) {
      pixel.r = ((pixel.r - black) * scale).clamp(0, 255).toInt();
      pixel.g = ((pixel.g - black) * scale).clamp(0, 255).toInt();
      pixel.b = ((pixel.b - black) * scale).clamp(0, 255).toInt();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(child: CameraPreview(_controller!)),
                _buildUIOverlay(),
                if (_isProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
        },
      ),
    );
  }

  Widget _buildUIOverlay() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          color: Colors.black.withOpacity(0.4),
          padding: const EdgeInsets.fromLTRB(25, 20, 25, 35),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildGalleryThumbnail(),
              _buildShutterButton(),
              const SizedBox(width: 55),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryThumbnail() {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white70, width: 2),
        image: _lastThumbnailUrl != null
            ? DecorationImage(image: NetworkImage(_lastThumbnailUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: _lastThumbnailUrl == null
          ? const Icon(Icons.photo_library, color: Colors.white, size: 24)
          : null,
    );
  }

  Widget _buildShutterButton() {
    return GestureDetector(
      onTap: _onCaptureAndDownload,
      child: Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.camera_alt, color: Colors.white, size: 28),
            Text("SAVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
