import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/user.dart';

/// Circle avatar showing a user's chosen photo, or — if none is set —
/// their initials on their chosen [User.avatarColor]. Used everywhere a
/// user is represented (question cards, answers, profile, login screen)
/// so identity stays consistent across the app.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.radius = 14});

  final User user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (user.photoPath.isNotEmpty) {
      final file = File(user.photoPath);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: FileImage(file),
        );
      }
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Color(user.avatarColor),
      child: Text(
        user.avatar,
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
