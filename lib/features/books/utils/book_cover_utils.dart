class BookCoverUtils {
  static String getGoogleBooksCover(String isbn, {int zoom = 1}) {
    return 'https://books.google.com/books/content?id=$isbn&printsec=frontcover&img=1&zoom=$zoom';
  }

  static String getOpenLibraryCover(String isbn, {CoverSize size = CoverSize.large}) {
    final sizeChar = size == CoverSize.large ? 'L' : 
                     size == CoverSize.medium ? 'M' : 'S';
    return 'https://covers.openlibrary.org/b/isbn/$isbn-$sizeChar.jpg';
  }
}

enum CoverSize {
  small,
  medium,
  large,
} 