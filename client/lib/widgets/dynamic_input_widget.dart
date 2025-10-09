import 'package:client/l10n/app_localizations.dart';
import 'package:client/models/tool.dart';
import 'package:client/models/tool_input_value.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

class DynamicInputWidget extends StatefulWidget {
  final InputField field;
  final ValueChanged<ToolInputValue> onChanged;
  final ToolInputValue? initialValue;

  const DynamicInputWidget({
    super.key,
    required this.field,
    required this.onChanged,
    this.initialValue,
  });

  @override
  State<DynamicInputWidget> createState() => _DynamicInputWidgetState();
}

class _DynamicInputWidgetState extends State<DynamicInputWidget> {
  ToolInputValue _value = const ToolInputValue.empty();
  TextEditingController? _textController;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue ?? const ToolInputValue.empty();
    if (widget.field.type == 'text') {
      _textController = TextEditingController(text: _value.text ?? '');
    }
  }

  @override
  void didUpdateWidget(covariant DynamicInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _value = widget.initialValue ?? const ToolInputValue.empty();
      if (widget.field.type == 'text') {
        _textController?.text = _value.text ?? '';
      }
    }
  }

  @override
  void dispose() {
    _textController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.field.type) {
      case 'text':
        return _buildTextField(context);
      case 'image':
        return _buildImagePicker(context);
      default:
        return Text('Unsupported field type: ${widget.field.type}');
    }
  }

  Widget _buildTextField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.field.label,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _textController,
          onChanged: (value) {
            final newValue = ToolInputValue(text: value);
            _value = newValue;
            widget.onChanged(newValue);
          },
          decoration: InputDecoration(
            hintText: widget.field.hint,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasImage = _value.hasBytes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.field.label,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasImage
                    ? colorScheme.primary.withOpacity(0.6)
                    : colorScheme.outlineVariant,
              ),
              color: colorScheme.surfaceContainerHighest.withOpacity(0.25),
            ),
            padding: const EdgeInsets.all(16),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _value.bytes!,
                      fit: BoxFit.cover,
                      height: 220,
                      width: double.infinity,
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.field.hint,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton.icon(
              onPressed: _pickImage,
              icon: Icon(hasImage ? Icons.refresh : Icons.upload_file),
              label: Text(
                hasImage
                    ? l10n.imagePickerReplaceButton
                    : l10n.imagePickerUploadButton,
              ),
            ),
            if (hasImage) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _removeImage,
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.imagePickerRemoveButton),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      return;
    }

    final bytes = await file.readAsBytes();
    final mimeType = await file.mimeType ?? lookupMimeType(file.name) ?? 'image/png';

    final newValue = ToolInputValue(
      bytes: bytes,
      mimeType: mimeType,
      fileName: file.name,
    );

    setState(() {
      _value = newValue;
    });
    widget.onChanged(newValue);
  }

  void _removeImage() {
    setState(() {
      _value = const ToolInputValue.empty();
    });
    widget.onChanged(const ToolInputValue.empty());
  }
}
