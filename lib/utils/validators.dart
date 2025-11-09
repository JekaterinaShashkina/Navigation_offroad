import 'package:flutter/material.dart';

/// Универсальный тип валидатора (как у TextFormField.validator)
typedef Validator = String? Function(String? value);

class Validators {
  // Простая и надёжная проверка email
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Обязательное поле
  static Validator required([String message = 'Required']) => (v) {
    if (v == null || v.trim().isEmpty) return message;
    return null;
  };

  /// Только формат email (пустую строку не трогаем — комбинируем с [required])
  static Validator email([String message = 'Invalid email']) => (v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return null;
    if (!_email.hasMatch(s)) return message;
    return null;
  };

  /// Удобный комбинированный валидатор: и пустоту, и формат
  static Validator emailRequired({
    String empty = 'Enter email',
    String invalid = 'Invalid email',
  }) => (v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return empty;
    if (!_email.hasMatch(s)) return invalid;
    return null;
  };

  /// Минимальная длина
  static Validator minLength(int n, {String? message}) => (v) {
    final s = v ?? '';
    if (s.length < n) return message ?? 'At least $n characters';
    return null;
  };

  /// Совпадение паролей
  static Validator confirmPassword(
    TextEditingController other, {
    String message = 'Passwords do not match',
    }) {
      return (value) {
        final v = value ?? '';
        return v == other.text ? null : message;
      };
    }

  /// Комбинатор: выполняет валидаторы по очереди и возвращает первую ошибку
  static Validator compose(List<Validator> validators) => (v) {
    for (final f in validators) {
      final res = f(v);
      if (res != null) return res;
    }
    return null;
  };
}
