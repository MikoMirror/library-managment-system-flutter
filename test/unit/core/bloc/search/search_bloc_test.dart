import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../../../../lib/core/bloc/search/search_bloc.dart';
import '../../../../../lib/core/repositories/search_repository.dart';
import 'search_bloc_test.mocks.dart';

@GenerateMocks([SearchRepository])
void main() {
  late SearchBloc searchBloc;
  late MockSearchRepository mockSearchRepository;

  setUp(() {
    mockSearchRepository = MockSearchRepository();
    searchBloc = SearchBloc(mockSearchRepository);
  });

  tearDown(() {
    searchBloc.close();
  });

  test('initial state is correct', () {
    expect(searchBloc.state.isLoading, false);
    expect(searchBloc.state.results, []);
    expect(searchBloc.state.error, '');
    expect(searchBloc.state.type, SearchType.books);
  });

  blocTest<SearchBloc, SearchState>(
    'emits loading and success states when search is successful',
    build: () {
      when(mockSearchRepository.search(
        query: 'test',
        type: SearchType.books,
        filters: null,
      )).thenAnswer((_) => Stream.value(['result1', 'result2']));
      return searchBloc;
    },
    act: (bloc) => bloc.search(
      query: 'test',
      type: SearchType.books,
    ),
    expect: () => [
      isA<SearchState>().having((s) => s.isLoading, 'isLoading', true),
      isA<SearchState>()
          .having((s) => s.isLoading, 'isLoading', false)
          .having((s) => s.results, 'results', ['result1', 'result2'])
          .having((s) => s.error, 'error', ''),
    ],
  );

  blocTest<SearchBloc, SearchState>(
    'emits loading and error states when search fails',
    build: () {
      when(mockSearchRepository.search(
        query: 'test',
        type: SearchType.books,
        filters: null,
      )).thenAnswer((_) => Stream.error('Error occurred'));
      return searchBloc;
    },
    act: (bloc) => bloc.search(
      query: 'test',
      type: SearchType.books,
    ),
    expect: () => [
      isA<SearchState>().having((s) => s.isLoading, 'isLoading', true),
      isA<SearchState>()
          .having((s) => s.isLoading, 'isLoading', false)
          .having((s) => s.error, 'error', 'Error occurred')
          .having((s) => s.results, 'results', []),
    ],
  );

  blocTest<SearchBloc, SearchState>(
    'clearSearch resets the state',
    build: () => searchBloc,
    act: (bloc) => bloc.clearSearch(),
    expect: () => [
      isA<SearchState>()
          .having((s) => s.isLoading, 'isLoading', false)
          .having((s) => s.results, 'results', [])
          .having((s) => s.error, 'error', ''),
    ],
  );
} 