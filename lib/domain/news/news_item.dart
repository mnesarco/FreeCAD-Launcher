class NewsItem {
  const NewsItem({
    required this.title,
    required this.link,
    this.publishedAt,
    this.summary,
  });

  final String title;
  final String link;
  final DateTime? publishedAt;
  final String? summary;
}
