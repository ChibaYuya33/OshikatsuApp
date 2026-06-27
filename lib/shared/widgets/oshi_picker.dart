import 'package:flutter/material.dart';

import '../../core/db/models.dart';

/// フォームでどの推しに紐づけるか選ぶドロップダウン。
class OshiDropdown extends StatelessWidget {
  final List<Oshi> oshis;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  const OshiDropdown({
    super.key,
    required this.oshis,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedId,
      decoration: const InputDecoration(
        labelText: '推し *',
        prefixIcon: Icon(Icons.person_outline),
      ),
      items: oshis
          .map((o) => DropdownMenuItem(
                value: o.id,
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Color(o.themeColor),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(o.name),
                  ],
                ),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? '推しを選択してください' : null,
    );
  }
}
