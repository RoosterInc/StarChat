const int commentMaxLength = 2000;

/// Returns true if the comment text is non-empty and within the allowed length.
bool isValidComment(String text) {
  final trimmed = text.trim();
  return trimmed.isNotEmpty && trimmed.length <= commentMaxLength;
}

