import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

class ProfilePhotoCropPage extends StatefulWidget {
  const ProfilePhotoCropPage({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<ProfilePhotoCropPage> createState() => _ProfilePhotoCropPageState();
}

class _ProfilePhotoCropPageState extends State<ProfilePhotoCropPage> {
  final CropController _cropController = CropController();

  Uint8List? _preview;
  bool _ready = false;
  bool _processing = false;

  void _onCropped(CropResult result) {
    if (!mounted) return;

    switch (result) {
      case CropSuccess(:final croppedImage):
        setState(() {
          _preview = croppedImage;
          _processing = false;
        });

      case CropFailure():
        setState(() {
          _processing = false;
          _ready = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo recortar la fotografía. Inténtalo de nuevo.',
            ),
          ),
        );
    }
  }

  void _previewPhoto() {
    if (!_ready || _processing) return;

    setState(() => _processing = true);

    _cropController.cropCircle();
  }

  void _confirmPhoto() {
    final bytes = _preview;

    if (bytes == null) return;

    Navigator.of(context).pop(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final showingPreview = _preview != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(showingPreview ? 'Vista previa' : 'Ajustar fotografía'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                children: [
                  Icon(
                    showingPreview
                        ? Icons.check_circle_outline_rounded
                        : Icons.crop_rotate_rounded,
                    color: colors.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    showingPreview
                        ? 'Así se verá tu fotografía'
                        : 'Coloca tu rostro dentro del círculo',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    showingPreview
                        ? 'Puedes volver a ajustarla antes de confirmar.'
                        : 'Arrastra la imagen y usa dos dedos para ampliar o reducir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child:
                    showingPreview
                        ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colors.primary,
                                    width: 3,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.memory(
                                    _preview!,
                                    width: 220,
                                    height: 220,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Fotografía lista para utilizar',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                        : Crop(
                          image: widget.imageBytes,
                          controller: _cropController,
                          withCircleUi: true,
                          interactive: true,
                          fixCropRect: true,
                          filterQuality: FilterQuality.high,
                          baseColor: colors.surfaceContainerLowest,
                          maskColor: Colors.black.withAlpha(165),
                          progressIndicator: const Center(
                            child: CircularProgressIndicator(),
                          ),
                          onStatusChanged: (status) {
                            if (!mounted) return;

                            final ready = status == CropStatus.ready;

                            if (_ready != ready) {
                              setState(() => _ready = ready);
                            }
                          },
                          willUpdateScale: (scale) => scale > 0 && scale <= 5,
                          onCropped: _onCropped,
                        ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child:
                  showingPreview
                      ? Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _preview = null;
                                  _ready = false;
                                });
                              },
                              icon: const Icon(Icons.tune_rounded),
                              label: const Text('Ajustar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _confirmPhoto,
                              icon: const Icon(Icons.check_rounded),
                              label: const Text('Usar foto'),
                            ),
                          ),
                        ],
                      )
                      : SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              _ready && !_processing ? _previewPhoto : null,
                          icon:
                              _processing
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.visibility_outlined),
                          label: Text(
                            _processing
                                ? 'Procesando fotografía...'
                                : 'Previsualizar recorte',
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
