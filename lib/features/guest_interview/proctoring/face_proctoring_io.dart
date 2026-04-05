import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

import 'face_proctoring_types.dart';

FaceProctoringBinding createFaceProctoringBinding() => _FaceProctoringIo();

class _FaceProctoringIo implements FaceProctoringBinding {
  CameraController? _controller;
  FaceDetector? _detector;
  bool _processing = false;
  FaceCountListener? _listener;
  bool _streamOn = false;
  DateTime? _lastFrameProcessed;

  @override
  Widget? buildPreviewOverlay() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 112,
        height: 150,
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: c.value.previewSize?.height ?? 150,
            height: c.value.previewSize?.width ?? 112,
            child: CameraPreview(c),
          ),
        ),
      ),
    );
  }

  @override
  Future<void> start(FaceCountListener onFaces) async {
    _listener = onFaces;
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    final cam = await Permission.camera.request();
    if (!cam.isGranted) {
      return;
    }

    _detector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableLandmarks: false,
        enableContours: false,
        enableClassification: false,
        enableTracking: true,
      ),
    );

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final front = cameras.cast<CameraDescription?>().firstWhere(
          (c) => c?.lensDirection == CameraLensDirection.front,
          orElse: () => null,
        ) ??
        cameras.first;

    try {
      _controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      if (_controller!.value.isInitialized) {
        await _controller!.startImageStream(_onCameraImage);
        _streamOn = true;
      }
    } catch (e, st) {
      debugPrint('[FaceProctoringIo] caméra indisponible: $e\n$st');
      await _controller?.dispose();
      _controller = null;
    }
  }

  Future<void> _onCameraImage(CameraImage image) async {
    if (_processing || _detector == null || _controller == null) return;
    final tick = DateTime.now();
    if (_lastFrameProcessed != null &&
        tick.difference(_lastFrameProcessed!) <
            const Duration(milliseconds: 500)) {
      return;
    }
    _lastFrameProcessed = tick;
    _processing = true;
    try {
      final input = _inputImageFromCameraImage(image, _controller!);
      if (input == null) return;
      final faces = await _detector!.processImage(input);
      _listener?.call(faces.length);
    } catch (e, st) {
      debugPrint('[FaceProctoringIo] $e\n$st');
    } finally {
      _processing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(
    CameraImage image,
    CameraController controller,
  ) {
    final cam = controller.description;
    if (Platform.isIOS) {
      if (image.planes.isEmpty) return null;
      return InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    }

    final rot = InputImageRotationValue.fromRawValue(cam.sensorOrientation) ??
        InputImageRotation.rotation0deg;
    final format = InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;

    final plane0 = image.planes.first;
    Uint8List bytes;
    if (image.planes.length == 1) {
      bytes = plane0.bytes;
    } else {
      final bb = BytesBuilder(copy: false);
      for (final p in image.planes) {
        bb.add(p.bytes);
      }
      bytes = bb.takeBytes();
    }
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rot,
        format: format,
        bytesPerRow: plane0.bytesPerRow,
      ),
    );
  }

  @override
  Future<void> stop() async {
    _listener = null;
    if (_streamOn && _controller != null) {
      try {
        await _controller!.stopImageStream();
      } catch (_) {}
      _streamOn = false;
    }
    await _controller?.dispose();
    _controller = null;
    await _detector?.close();
    _detector = null;
  }
}
