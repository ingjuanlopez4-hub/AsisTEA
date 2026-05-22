import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/child_profile.dart';

class ChildSelector extends StatelessWidget {
  final List<ChildProfile> children;
  final ChildProfile activeChild;
  final ValueChanged<ChildProfile> onChanged;

  const ChildSelector({
    super.key,
    required this.children,
    required this.activeChild,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreenDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: activeChild.childId,
          icon: const Icon(
            Icons.swap_vert,
            size: 18,
            color: Colors.white,
          ),
          dropdownColor: AppTheme.primaryGreenDark,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          items: children.map((child) {
            return DropdownMenuItem<String>(
              value: child.childId,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(child.avatar ?? '👤'),
                  const SizedBox(width: 8),
                  Text(child.name),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              final child = children.firstWhere((c) => c.childId == value);
              onChanged(child);
            }
          },
        ),
      ),
    );
  }
}
