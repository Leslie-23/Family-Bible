import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../databases/bible_database.dart';
import '../models/verse_model.dart';
import '../providers/scroll_controller_provider.dart';
import '../utils/text_utils.dart';
import '../widgets/ux_states.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final List<Verse> verses;

  const SearchScreen(this.verses, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final List<Verse> _results = [];
  final List<Verse> _suggestions = [];

  // Method to perform the search
  Future<void> search() async {
    final query =
        _searchController.text.trim().replaceAll(" ", "").toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _results.clear();
      });
      return;
    }

    final results = <Verse>[];

    for (var verse in widget.verses) {
      // Matching verses based on the trimmed and lowercase text
      bool matchVerse =
          verse.text.trim().replaceAll(" ", "").toLowerCase().contains(query);
      if (matchVerse) {
        bool contains = results.any((element) => element == verse);
        if (!contains) {
          results.add(verse);
        }
      }
    }

    setState(() {
      _results
        ..clear()
        ..addAll(results);
    });
  }

  void _updateSuggestions(String value) {
    final query = value.trim().replaceAll(" ", "").toLowerCase();
    if (query.isEmpty) {
      setState(() => _suggestions.clear());
      return;
    }

    final matches = <Verse>[];
    for (final verse in widget.verses) {
      final normalized = verse.text.trim().replaceAll(" ", "").toLowerCase();
      final reference =
          '${verse.book}${verse.chapter}${verse.verse}'.toLowerCase();

      if (normalized.contains(query) || reference.contains(query)) {
        matches.add(verse);
      }

      if (matches.length == 6) break;
    }

    setState(() {
      _suggestions
        ..clear()
        ..addAll(matches);
    });
  }

  String _selectedBook = "All";

  void _onTap(String book) {
    setState(() {
      _selectedBook = book;
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultBooks =
        _results.map((toElement) => toElement.book).toSet().toList();

    final books = BibleDatabase.books;

    resultBooks.sortByCompare(
      (keyOf) => keyOf,
      (a, b) {
        int indexA = books.indexOf(a);
        int indexB = books.indexOf(b);

        return indexA.compareTo(indexB);
      },
    );

    // Insert 'OT' & 'NT' to resultbooks
    if (_results.isNotEmpty) {
      resultBooks.insert(0, "NT");

      resultBooks.insert(0, "OT");
    }

    List<Verse> filteredResult = [];

    if (_selectedBook == "All") {
      filteredResult = _results;
    } else if (_selectedBook == "OT") {
      filteredResult =
          _results.where((verse) => books.indexOf(verse.book) < 39).toList();
      resultBooks.removeWhere(
          (book) => books.indexOf(book) > 38 && book != "OT" && book != "NT");
    } else if (_selectedBook == "NT") {
      filteredResult =
          _results.where((verse) => books.indexOf(verse.book) > 38).toList();
      resultBooks.removeWhere(
          (book) => books.indexOf(book) < 39 && book != "OT" && book != "NT");
    } else {
      filteredResult =
          _results.where((verse) => verse.book == _selectedBook).toList();
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0.0,
        title: TextField(
          autofocus: true,
          controller: _searchController,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: "Search",
          ),
          onChanged: _updateSuggestions,
          onSubmitted: (s) async =>
              await search().then((_) => _scrollController.jumpTo(0.0)),
          textInputAction: TextInputAction.search,
        ),
        actions: [
          // Clear search button when there's input
          if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: () async {
                await search().then((_) => _scrollController.jumpTo(0.0));
              },
              icon: const Icon(Icons.search_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_suggestions.isNotEmpty)
            Material(
              color: Theme.of(context).colorScheme.surface,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                itemBuilder: (context, index) {
                  final verse = _suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.manage_search_rounded),
                    title: Text(
                      verse.text.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      "${verse.book} ${verse.chapter}:${verse.verse}",
                    ),
                    onTap: () {
                      _jumpToVerse(verse);
                    },
                  );
                },
              ),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: resultBooks.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final book = resultBooks[index];

                  // Calculate the result count for each book and for verses in books in OT and NT
                  final resultCount = _results
                      .where((verse) =>
                          verse.book == book ||
                          book == "OT" &&
                              books.indexOf(verse.book) < 39 &&
                              books.contains(verse.book) ||
                          book == "NT" && books.indexOf(verse.book) > 38)
                      .toList()
                      .length;

                  return index == 0
                      ? Row(
                          children: [
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  _onTap("All");
                                },
                                child: Card(
                                  color: "All" == _selectedBook
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                      : null,
                                  margin: EdgeInsets.only(
                                      left: 14.0,
                                      right: index == (resultBooks.length - 1)
                                          ? 14.0
                                          : 0.0),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0, vertical: 4.0),
                                    child: Text("All ${_results.length}"),
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  _onTap(book);
                                },
                                child: Card(
                                  color: book == _selectedBook
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                      : null,
                                  margin: EdgeInsets.only(
                                      left: 14.0,
                                      right: index == (resultBooks.length - 1)
                                          ? 14.0
                                          : 0.0),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0, vertical: 4.0),
                                    child: Text("$book $resultCount"),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: GestureDetector(
                            onTap: () {
                              _onTap(book);
                            },
                            child: Card(
                              color: book == _selectedBook
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : null,
                              margin: EdgeInsets.only(
                                  left: 14.0,
                                  right: index == (resultBooks.length - 1)
                                      ? 14.0
                                      : 0.0),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                child: Text("$book $resultCount"),
                              ),
                            ),
                          ),
                        );
                },
              ),
            ),
          ),
          Expanded(
            child: filteredResult.isEmpty && _searchController.text.isNotEmpty
                ? const EmptyStateView(
                    icon: Icons.search_off_rounded,
                    title: 'No matching verses',
                    body: 'Try a shorter word, a book name, or a verse phrase.',
                  )
                : ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredResult.length,
                    itemBuilder: (context, index) {
                      Verse verse = filteredResult[index];
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom:
                                BorderSide(color: Theme.of(context).hoverColor),
                          ),
                        ),
                        child: ListTile(
                          onTap: () {
                            _jumpToVerse(verse);
                          },
                          title: TextUtils.search(
                              input: verse.text.trim(),
                              text: _searchController.text.trim(),
                              context: context),
                          subtitle: Text(
                              "${verse.book} ${verse.chapter}:${verse.verse}"),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _jumpToVerse(Verse verse) {
    int idx = widget.verses.indexWhere(
      (element) =>
          element.chapter == verse.chapter &&
          element.book == verse.book &&
          element.verse == verse.verse,
    );
    ScrollControllerProvider.jumpTo(ref: ref, index: idx);
    Navigator.pop(context);
  }
}
