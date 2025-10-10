import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home.dart';

class SearchPage extends StatefulWidget {
  final HomePageState homeState;

  const SearchPage({super.key, required this.homeState});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredQuotes = widget.homeState.quoteHistory.where((quote) =>
        quote.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        quote.author.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'Search quotes...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
            debugPrint('Search query: $value');
          },
        ),
      ),
      body: ListView.builder(
        itemCount: filteredQuotes.length,
        itemBuilder: (context, index) {
          final quote = filteredQuotes[filteredQuotes.length - 1 - index];
          return ListTile(
            title: Text(quote.content),
            subtitle: Text(
              '- ${quote.author}${widget.homeState.quoteRatings.containsKey(quote.id) ? ' (Rating: ${widget.homeState.quoteRatings[quote.id]})' : ''}',
            ),
            onTap: () {
              widget.homeState.setCurrentQuote(quote);
              Get.back();
            },
          );
        },
      ),
    );
  }
}