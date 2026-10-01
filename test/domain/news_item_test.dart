// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/domain/news/news_item.dart';

void main() {
  NewsItem item({String? summary}) {
    return NewsItem(title: 'Title', link: 'https://blog.freecad.org/post', summary: summary);
  }

  test('excerpt is null for missing or blank summaries', () {
    expect(item().excerpt, isNull);
    expect(item(summary: '   ').excerpt, isNull);
  });

  test('excerpt keeps short summaries unchanged', () {
    expect(item(summary: 'Short text').excerpt, 'Short text');
  });

  test('excerpt truncates at a word boundary with an ellipsis', () {
    final excerpt = item(summary: 'word ' * 60).excerpt!;

    expect(excerpt.endsWith('…'), isTrue);
    expect(excerpt.length, lessThanOrEqualTo(NewsItem.excerptLength + 1));
    expect(excerpt.contains('  '), isFalse);
    expect(excerpt.startsWith('word word'), isTrue);
  });
}
