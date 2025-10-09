import 'dart:typed_data';

class ToolInputValue {
  final String? text;
  final Uint8List? bytes;
  final String? mimeType;
  final String? fileName;

  const ToolInputValue({this.text, this.bytes, this.mimeType, this.fileName});

  const ToolInputValue.empty() : this();

  bool get hasText => text != null && text!.trim().isNotEmpty;

  bool get hasBytes => bytes != null && bytes!.isNotEmpty;

  bool get isEmpty => !hasText && !hasBytes;

  ToolInputValue copyWith({
    String? text,
    bool clearText = false,
    Uint8List? bytes,
    bool clearBytes = false,
    String? mimeType,
    String? fileName,
  }) {
    return ToolInputValue(
      text: clearText ? null : text ?? this.text,
      bytes: clearBytes ? null : bytes ?? this.bytes,
      mimeType: mimeType ?? this.mimeType,
      fileName: fileName ?? this.fileName,
    );
  }
}
