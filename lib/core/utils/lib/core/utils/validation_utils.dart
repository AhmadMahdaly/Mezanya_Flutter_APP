class ValidationUtils {
  static String? required(String? value, {String fieldName = 'الحقل'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName مطلوب';
    }
    return null;
  }

  static String? positiveNumber(double? value, {String fieldName = 'المبلغ'}) {
    if (value == null || value <= 0) {
      return '$fieldName يجب أن يكون أكبر من صفر';
    }
    return null;
  }

  static String? nonNegative(double? value, {String fieldName = 'الرصيد'}) {
    if (value == null || value < 0) {
      return '$fieldName لا يمكن أن يكون سالباً';
    }
    return null;
  }

  static String? uniqueName<T>(
    String name,
    List<T> items,
    String Function(T) getName, {
    String? excludeId,
    String Function(T)? getId,
  }) {
    final exists = items.any((item) {
      if (excludeId != null && getId != null && getId(item) == excludeId) {
        return false;
      }
      return getName(item) == name;
    });
    if (exists) return 'يوجد عنصر بنفس الاسم';
    return null;
  }
}