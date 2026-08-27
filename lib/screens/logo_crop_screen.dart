import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class LogoCropScreen extends StatefulWidget {
  final File imageFile;
  const LogoCropScreen({super.key, required this.imageFile});

  @override
  State<LogoCropScreen> createState() => _LogoCropScreenState();
}

class _LogoCropScreenState extends State<LogoCropScreen> {
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  double _minScale = 1.0;
  Size _imageSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    _imageSize = Size(image.width.toDouble(), image.height.toDouble());
    image.dispose();

    if (!mounted) return;
    final containerSize = MediaQuery.of(context).size.width - 32;
    final fitScale = max(
      containerSize / _imageSize.width,
      containerSize / _imageSize.height,
    );
    _minScale = fitScale;
    _scale = fitScale;

    final scaledW = _imageSize.width * _scale;
    final scaledH = _imageSize.height * _scale;
    _offset = Offset(
      (containerSize - scaledW) / 2,
      (containerSize - scaledH) / 2,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final containerSize = MediaQuery.of(context).size.width - 32;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Potong Logo'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            'Geser dan zoom logo agar pas di dalam kotak',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Center(
            child: ClipRect(
              child: SizedBox(
                width: containerSize,
                height: containerSize,
                child: Stack(
                  children: [
                    GestureDetector(
                      onScaleUpdate: (details) {
                        setState(() {
                          _scale = (_scale * details.scale).clamp(_minScale, _minScale * 3);
                          _offset += details.focalPointDelta;
                        });
                      },
                      child: Transform.translate(
                        offset: _offset,
                        child: Transform.scale(
                          scale: 1.0,
                          child: SizedBox(
                            width: _imageSize.width * _scale,
                            height: _imageSize.height * _scale,
                            child: Image.file(
                              widget.imageFile,
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: CustomPaint(
                        size: Size(containerSize, containerSize),
                        painter: _CropOverlayPainter(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _cropAndSave,
                    icon: const Icon(Icons.check),
                    label: const Text('Gunakan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
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

  Future<void> _cropAndSave() async {
    final containerSize = MediaQuery.of(context).size.width - 32;
    final targetSize = 300;

    final bytes = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final srcW = image.width;
    final srcH = image.height;
    final displayedW = _imageSize.width * _scale;
    final displayedH = _imageSize.height * _scale;

    final cropLeft = (((_offset.dx * -1 + (containerSize / 2) - (displayedW / 2)) / displayedW * srcW).clamp(0.0, srcW - 1)).toDouble();
    final cropTop = (((_offset.dy * -1 + (containerSize / 2) - (displayedH / 2)) / displayedH * srcH).clamp(0.0, srcH - 1)).toDouble();
    final cropSize = ((containerSize / displayedW * srcW).clamp(1.0, min(srcW - cropLeft, srcH - cropTop))).toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(Colors.white, BlendMode.src);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(cropLeft, cropTop, cropSize, cropSize),
      Rect.fromLTWH(0, 0, targetSize.toDouble(), targetSize.toDouble()),
      Paint()..filterQuality = FilterQuality.high,
    );
    final picture = recorder.endRecording();
    final cropped = await picture.toImage(targetSize, targetSize);
    final byteData = await cropped.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    cropped.dispose();

    if (byteData == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final pngBytes = byteData.buffer.asUint8List();
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/cropped_logo_${DateTime.now().millisecondsSinceEpoch}.png');
    await tempFile.writeAsBytes(pngBytes);
    if (mounted) Navigator.pop(context, tempFile);
  }
}

class _CropOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final clearPaint = Paint()..blendMode = BlendMode.clear;
    final squareSize = size.width;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, squareSize, squareSize),
      clearPaint,
    );

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, squareSize, squareSize),
      borderPaint,
    );

    final linePaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 0.5;
    final third = squareSize / 3;
    for (int i = 1; i <= 2; i++) {
      canvas.drawLine(Offset(third * i, 0), Offset(third * i, squareSize), linePaint);
      canvas.drawLine(Offset(0, third * i), Offset(squareSize, third * i), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
