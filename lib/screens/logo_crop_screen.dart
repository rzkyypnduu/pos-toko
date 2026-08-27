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
  Size _containerSize = Size.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadImage();
    });
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
    _containerSize = Size(containerSize, containerSize);

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
    final mq = MediaQuery.of(context);
    final containerSize = mq.size.width - 32;

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
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
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: SizedBox(
                width: containerSize,
                height: containerSize,
                child: ClipRect(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onScaleStart: (_) {},
                        onScaleUpdate: (details) {
                          setState(() {
                            final newScale = (_scale * details.scale).clamp(_minScale, _minScale * 3);
                            final scaleRatio = newScale / _scale;
                            _scale = newScale;
                            final centerX = containerSize / 2;
                            final centerY = containerSize / 2;
                            _offset = Offset(
                              centerX - (centerX - _offset.dx) * scaleRatio + details.focalPointDelta.dx,
                              centerY - (centerY - _offset.dy) * scaleRatio + details.focalPointDelta.dy,
                            );
                          });
                        },
                        child: Transform.translate(
                          offset: _offset,
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
                      IgnorePointer(
                        child: CustomPaint(
                          size: Size(containerSize, containerSize),
                          painter: _GridPainter(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Batal'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _imageSize == Size.zero ? null : _cropAndSave,
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
    final containerSize = _containerSize.width;
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

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      borderPaint,
    );

    final linePaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 0.5;
    final third = size.width / 3;
    for (int i = 1; i <= 2; i++) {
      canvas.drawLine(Offset(third * i, 0), Offset(third * i, size.height), linePaint);
      canvas.drawLine(Offset(0, third * i), Offset(size.width, third * i), linePaint);
    }

    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final cornerLen = size.width / 8;
    final paths = [
      Path()
        ..moveTo(0, cornerLen)
        ..lineTo(0, 0)
        ..lineTo(cornerLen, 0),
      Path()
        ..moveTo(size.width - cornerLen, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, cornerLen),
      Path()
        ..moveTo(0, size.height - cornerLen)
        ..lineTo(0, size.height)
        ..lineTo(cornerLen, size.height),
      Path()
        ..moveTo(size.width - cornerLen, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width, size.height - cornerLen),
    ];
    for (final p in paths) {
      canvas.drawPath(p, cornerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
