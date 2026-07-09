import 'package:flutter/material.dart';

import '../../models/user.dart';

/// Circle avatar showing a user's initials on their chosen
/// [User.avatarColor] — used everywhere a user is represented (question
/// cards, answers, profile, welcome screen) so identity colors stay
/// consistent across the app.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.radius = 14});

  final User user;
  final double radius;

  @override
  Widget build(BuildContext context) {
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
