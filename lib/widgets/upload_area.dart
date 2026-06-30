import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

/// Drag-and-drop + file-picker upload zone. Emits the selected ZIP's bytes.
class UploadArea extends StatefulWidget {
  const UploadArea({required this.onBytes, this.busy = false, super.key});

  final void Function(Uint8List bytes) onBytes;
  final bool busy;

  @override
  State<UploadArea> createState() => _UploadAreaState();
}

class _UploadAreaState extends State<UploadArea> {
  bool _hovering = false;
  String? _error;

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: true,
    );
    final file = result?.files.firstOrNull;
    if (file?.bytes != null) {
      _validateAndEmit(file!.bytes!);
    }
  }

  void _validateAndEmit(Uint8List bytes) {
    if (bytes.lengthInBytes > AppConstants.maxZipBytes) {
      setState(() => _error = 'File exceeds the 100 MB limit.');
      return;
    }
    setState(() => _error = null);
    widget.onBytes(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DropTarget(
      onDragEntered: (_) => setState(() => _hovering = true),
      onDragExited: (_) => setState(() => _hovering = false),
      onDragDone: (detail) async {
        setState(() => _hovering = false);
        final file = detail.files.firstOrNull;
        if (file == null) return;
        final bytes = await file.readAsBytes();
        _validateAndEmit(bytes);
      },
      child: InkWell(
        onTap: widget.busy ? null : _pick,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _hovering
                ? scheme.primaryContainer.withValues(alpha: 0.4)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.3),
            border: Border.all(
              color: _hovering ? scheme.primary : scheme.outlineVariant,
              width: _hovering ? 2 : 1.5,
            ),
          ),
          child: Center(
            child: widget.busy
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_upload_outlined,
                          size: 56, color: scheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        'Drag & drop a project .zip here',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'or click to browse — up to 100 MB',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!,
                            style: TextStyle(color: scheme.error)),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
