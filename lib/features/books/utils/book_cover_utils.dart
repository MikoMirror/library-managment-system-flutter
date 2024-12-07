class BookCoverUtils {
  static String getGoogleBooksCover(String url, {int zoom = 4}) {
    if (!url.contains('books.google.com')) return url;
    
    final uri = Uri.parse(url);
    final params = Map<String, String>.from(uri.queryParameters);
    
    params['zoom'] = zoom.toString();
    params['edge'] = 'curl';
    params['img'] = '1';
    
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      path: uri.path,
      queryParameters: params,
    ).toString();
  }

  static String getOpenLibraryCover(String isbn, {CoverSize size = CoverSize.large}) {
    return 'https://covers.openlibrary.org/b/isbn/$isbn-${size.value}.jpg';
  }
}

enum CoverSize {
  small('S'),
  medium('M'),
  large('L');

  final String value;
  const CoverSize(this.value);
} 