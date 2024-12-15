class OpenLibraryService {
  static String transformCoverUrl(String url, {bool isLarge = false}) {
    if (url.contains('openlibrary.org')) {
      if (isLarge) {
        return url.replaceAll('-S.jpg', '-L.jpg')
                 .replaceAll('-M.jpg', '-L.jpg');
      } else {
        return url.replaceAll('-L.jpg', '-M.jpg')
                 .replaceAll('-S.jpg', '-M.jpg');
      }
    }
    return url;
  }

  static String getBookCoverUrl(String olid, {bool isLarge = false}) {
    final size = isLarge ? 'L' : 'M';
    return 'https://covers.openlibrary.org/b/olid/$olid-$size.jpg';
  }

  static bool isOpenLibraryUrl(String url) {
    return url.contains('openlibrary.org');
  }
} 