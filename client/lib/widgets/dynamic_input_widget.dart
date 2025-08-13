import 'package:flutter/material.dart';
import 'package:client/models/tool.dart';

class DynamicInputWidget extends StatelessWidget {
  final InputField field;
  final Function(String) onChanged;

  const DynamicInputWidget({
    super.key,
    required this.field,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (field.type) {
      case 'text':
        return _buildTextField(context);
      default:
        return Text('Unsupported field type: ${field.type}');
    }
  }

  Widget _buildTextField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        TextFormField(
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: field.hint,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
