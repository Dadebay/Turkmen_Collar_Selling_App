import 'dart:convert';

/// Defensive coercion helpers for JSON parsing.
///
/// Each method silently falls back instead of throwing when the incoming
/// value is missing or of an unexpected type. The non-nullable variants
/// accept an optional `fallback`; the `*OrNull` variants return `null`
/// when coercion is impossible.
class SafeParser {
  const SafeParser._();

  // ---------------------------------------------------------------------------
  // int
  // ---------------------------------------------------------------------------

  static int asInt(dynamic value, {int fallback = 0}) {
    return asIntOrNull(value) ?? fallback;
  }

  static int? asIntOrNull(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.isFinite ? value.toInt() : null;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is bool) {
      return value ? 1 : 0;
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      final parsedInt = int.tryParse(trimmed);
      if (parsedInt != null) {
        return parsedInt;
      }
      final parsedDouble = double.tryParse(trimmed);
      if (parsedDouble != null && parsedDouble.isFinite) {
        return parsedDouble.toInt();
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // double
  // ---------------------------------------------------------------------------

  static double asDouble(dynamic value, {double fallback = 0.0}) {
    return asDoubleOrNull(value) ?? fallback;
  }

  static double? asDoubleOrNull(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is bool) {
      return value ? 1.0 : 0.0;
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      return double.tryParse(trimmed);
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // String
  // ---------------------------------------------------------------------------

  static String asString(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }
    if (value is String) {
      return value;
    }
    return value.toString();
  }

  static String? asStringOrNull(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    return value.toString();
  }

  // ---------------------------------------------------------------------------
  // bool
  // ---------------------------------------------------------------------------

  static bool asBool(dynamic value, {bool fallback = false}) {
    return asBoolOrNull(value) ?? fallback;
  }

  static bool? asBoolOrNull(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      switch (value.toLowerCase().trim()) {
        case 'true':
        case '1':
        case 'yes':
        case 'y':
          return true;
        case 'false':
        case '0':
        case 'no':
        case 'n':
        case '':
          return false;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // DateTime
  // ---------------------------------------------------------------------------

  static DateTime asDateTime(dynamic value, {DateTime? fallback}) {
    return asDateTimeOrNull(value) ?? fallback ?? DateTime.now();
  }

  static DateTime? asDateTimeOrNull(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      return DateTime.tryParse(trimmed);
    }
    if (value is int) {
      // Heuristic: 13-digit values are millisecond epochs; smaller are seconds.
      try {
        if (value > 99999999999) {
          return DateTime.fromMillisecondsSinceEpoch(value);
        }
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // List
  // ---------------------------------------------------------------------------

  /// Maps a JSON list to `List<T>`, silently skipping entries that the mapper
  /// fails to convert. Returns `fallback` (defaults to `const []`) when the
  /// value isn't a list.
  static List<T> asList<T>(
    dynamic value,
    T Function(dynamic item) mapper, {
    List<T> fallback = const [],
  }) {
    if (value is! List) {
      return fallback;
    }
    final out = <T>[];
    for (final item in value) {
      try {
        out.add(mapper(item));
      } catch (_) {
        // skip malformed entries
      }
    }
    return out;
  }

  /// Coerces `value` to `List<String>`. Accepts a list, a single string
  /// (returned as a 1-element list), or a JSON-encoded array string.
  static List<String> asStringList(dynamic value) {
    if (value == null) {
      return const [];
    }
    if (value is List) {
      return value.map((e) => asString(e)).toList(growable: false);
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return const [];
      }
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is List) {
            return decoded.map((e) => asString(e)).toList(growable: false);
          }
        } catch (_) {
          // fall through and treat as single-string list
        }
      }
      return [value];
    }
    return const [];
  }

  /// Same as [asList] but returns `List<dynamic>` without per-item coercion.
  static List<dynamic> asDynamicList(dynamic value) {
    if (value is List) {
      return List<dynamic>.from(value);
    }
    return const [];
  }

  // ---------------------------------------------------------------------------
  // Map
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> asMap(dynamic value) {
    return asMapOrNull(value) ?? const {};
  }

  static Map<String, dynamic>? asMapOrNull(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }
}
