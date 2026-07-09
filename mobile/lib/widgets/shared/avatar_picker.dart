import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'avatar_color_picker.dart';

/// Composite avatar editor for signup and profile editing: a real photo
/// (camera or gallery) takes priority when set; otherwise the existing
/// colored-initials circle is used as a fallback and [AvatarColorPicker]
/// stays relevant.
class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    required this.photoPath,
    required this.avatarColor,
    required this.initials,
    required this.onPhotoChanged,
    required this.onColorChanged,
  });

  final String photoPath;
  final int avatarColor;
  final String initials;
  final ValueChanged<String> onPhotoChanged;
  final ValueChanged<int> onColorChanged;

  Future<void> _pick(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null) return;
    // Copy out of the picker's temp location — the OS can clear that
    // before the profile is saved, so it needs a stable home.
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'avatar_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final saved = await File(picked.path).copy(p.join(dir.path, fileName));
    onPhotoChanged(saved.path);
  }

  Future<void> _choosePhoto(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir depuis la galerie'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) {
      await _pick(source);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: CircleAvatar(
            radius: 44,
            backgroundColor: Color(avatarColor),
            backgroundImage: hasPhoto ? FileImage(File(photoPath)) : null,
            child: hasPhoto
                ? null
                : Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => _choosePhoto(context),
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: Text(
                  hasPhoto ? 'Changer la photo' : 'Ajouter une photo',
                ),
              ),
              if (hasPhoto)
                TextButton.icon(
                  onPressed: () => onPhotoChanged(''),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Retirer la photo'),
                ),
            ],
          ),
        ),
        if (!hasPhoto) ...[
          const SizedBox(height: 12),
          Center(
            child: AvatarColorPicker(
              selected: avatarColor,
              onChanged: onColorChanged,
            ),
          ),
        ],
      ],
    );
  }
}
