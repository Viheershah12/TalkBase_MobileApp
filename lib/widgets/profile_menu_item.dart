import 'package:flutter/material.dart';

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: textColor ?? Theme.of(context).iconTheme.color),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      trailing: textColor == null
          ? const Icon(Icons.arrow_forward_ios, size: 16)
          : null,
    );
  }
}