import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/db/models.dart';

/// 推しのアバター(写真があれば表示、無ければ頭文字＋推し色)。
class OshiAvatar extends StatelessWidget {
  final Oshi oshi;
  final double radius;
  const OshiAvatar({super.key, required this.oshi, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    final color = Color(oshi.themeColor);
    final hasPhoto =
        !kIsWeb && oshi.photoPath != null && File(oshi.photoPath!).existsSync();
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.25),
      backgroundImage: hasPhoto ? FileImage(File(oshi.photoPath!)) : null,
      child: hasPhoto
          ? null
          : Text(
              oshi.name.isNotEmpty ? oshi.name.characters.first : '推',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
              ),
            ),
    );
  }
}

/// ローカルパスの画像を角丸で表示(Web/欠損時はプレースホルダ)。
class LocalImage extends StatelessWidget {
  final String? path;
  final double size;
  final double radius;
  const LocalImage({
    super.key,
    required this.path,
    this.size = 56,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final exists = !kIsWeb && path != null && File(path!).existsSync();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: exists
          ? Image.file(File(path!),
              width: size, height: size, fit: BoxFit.cover)
          : Container(
              width: size,
              height: size,
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              child: Icon(Icons.image_outlined,
                  color: Theme.of(context).colorScheme.outline),
            ),
    );
  }
}

/// 空状態の表示。
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? hint;
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: scheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            if (hint != null) ...[
              const SizedBox(height: 8),
              Text(hint!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.outline,
                      )),
            ],
          ],
        ),
      ),
    );
  }
}

/// セクション見出し。
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}
