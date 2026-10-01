// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
class NewsItem {
  const NewsItem({
    required this.title,
    required this.link,
    this.publishedAt,
    this.summary,
  });

  static const int excerptLength = 180;

  final String title;
  final String link;
  final DateTime? publishedAt;
  final String? summary;

  String? get excerpt {
    final text = summary?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    if (text.length <= excerptLength) {
      return text;
    }
    final cut = text.substring(0, excerptLength);
    final lastSpace = cut.lastIndexOf(' ');
    return '${(lastSpace > 0 ? cut.substring(0, lastSpace) : cut).trimRight()}…';
  }
}
