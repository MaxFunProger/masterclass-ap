import 'package:flutter/material.dart';

/// Одна белая плашка под поле ввода (логин / регистрация).
class AuthRoundedField extends StatelessWidget {
  const AuthRoundedField({super.key, required this.child});

  final Widget child;

  /// Вертикальный зазор между соседними плашками.
  static const double fieldSpacing = 12;

  /// Одинаковый [TextField.scrollPadding] для всех полей - прокрутка при фокусе и клавиатуре.
  static const EdgeInsets fieldScrollPadding =
      EdgeInsets.fromLTRB(0, 24, 0, 220);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
