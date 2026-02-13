class GeneralTranslationRequestData {
  final String title;
  final String artist;
  final String content; // lyric body
  final String? genre;

  GeneralTranslationRequestData({
    required this.title,
    required this.artist,
    required this.content,
    this.genre,
  });
}
