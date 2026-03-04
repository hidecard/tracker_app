import 'package:flutter/material.dart';
import 'glass_card.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? const Color(0xFF0077B6),
          foregroundColor: textColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const AppTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: const Color(0xFF0077B6), size: 20)
              : null,
          suffixIcon: suffixIcon != null
              ? IconButton(
                  icon: Icon(suffixIcon, color: const Color(0xFF0077B6)),
                  onPressed: onSuffixTap,
                )
              : null,
        ),
      ),
    );
  }
}

class AppDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? labelText;
  final IconData? prefixIcon;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelText,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: labelText,
          border: InputBorder.none,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: const Color(0xFF0077B6), size: 20)
              : null,
        ),
        dropdownColor: Colors.white,
        isExpanded: true,
      ),
    );
  }
}

class AppDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final void Function(DateTime) onDateSelected;
  final String? labelText;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const AppDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.labelText,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: firstDate ?? DateTime(2020),
          lastDate: lastDate ?? DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF0077B6),
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Color(0xFF0077B6),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F9FC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF0077B6), size: 20),
            const SizedBox(width: 12),
            Text(
              "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
              style: const TextStyle(fontSize: 16, color: Color(0xFF0077B6), fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Color(0xFF0077B6)),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF0077B6)),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: TextStyle(fontSize: 14, color: Colors.grey[600]), textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFF0077B6)),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0077B6))),
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      ),
    );
  }
}

class AppBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;

  const AppBadge({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF0077B6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? const Color(0xFF0077B6),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

