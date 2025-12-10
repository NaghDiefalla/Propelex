import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home.dart';

class SearchPage extends StatefulWidget {
  final HomePageState homeState;

  const SearchPage({super.key, required this.homeState});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _searchQuery = '';
  int _minRating = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ratings = widget.homeState.quoteRatings;
    final filteredQuotes = widget.homeState.quoteHistory.where((quote) {
      final matchesText = quote.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          quote.author.toLowerCase().contains(_searchQuery.toLowerCase());
      final rating = ratings[quote.id] ?? 0;
      return matchesText && rating >= _minRating;
    }).toList();

    final hasResults = filteredQuotes.isNotEmpty;
    final hasQuery = _searchQuery.isNotEmpty;
    final hasFilter = _minRating > 0;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search quotes or authors...',
            hintStyle: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            border: InputBorder.none,
            prefixIcon: Icon(
              Icons.search_rounded,
              color: colorScheme.primary,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    tooltip: 'Clear search',
                    onPressed: () => setState(() => _searchQuery = ''),
                  )
                : null,
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
          style: textTheme.bodyLarge,
        ),
        actions: [
          // Filter chip
          if (hasFilter)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text('$_minRating+'),
                  ],
                ),
                backgroundColor: colorScheme.secondaryContainer,
                onDeleted: () => setState(() => _minRating = 0),
                deleteIcon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          // Filter menu
          PopupMenuButton<int>(
            icon: Icon(
              Icons.tune_rounded,
              color: hasFilter ? colorScheme.primary : null,
            ),
            tooltip: 'Filter by rating',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (v) => setState(() => _minRating = v),
            itemBuilder: (ctx) => [
              PopupMenuItem<int>(
                enabled: false,
                child: Text(
                  'Minimum Rating',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const PopupMenuDivider(),
              ...List.generate(6, (i) => PopupMenuItem<int>(
                    value: i,
                    child: Row(
                      children: [
                        Text('$i+ stars', style: const TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(width: 12),
                        Row(
                          children: List.generate(
                            5,
                            (idx) => Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: Icon(
                                idx < i ? Icons.star_rounded : Icons.star_border_rounded,
                                color: Colors.amber.shade600,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ],
      ),
      body: hasResults
          ? Column(
              children: [
                // Results count
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  color: colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${filteredQuotes.length} ${filteredQuotes.length == 1 ? 'quote found' : 'quotes found'}',
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Quotes list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredQuotes.length,
                    separatorBuilder: (context, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final quote = filteredQuotes[filteredQuotes.length - 1 - index];
                      final rating = ratings[quote.id];
                      final isRated = rating != null && rating > 0;

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.1),
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            widget.homeState.setCurrentQuote(quote);
                            Get.back();
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        quote.content,
                                        style: textTheme.bodyLarge?.copyWith(
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '- ${quote.author}',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                    if (isRated) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.star_rounded,
                                              size: 14,
                                              color: Colors.amber.shade700,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$rating',
                                              style: textTheme.labelSmall?.copyWith(
                                                color: Colors.amber.shade900,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasQuery || hasFilter
                          ? Icons.search_off_rounded
                          : Icons.search_rounded,
                      size: 80,
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      hasQuery || hasFilter
                          ? 'No quotes found'
                          : 'Search your quote history',
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      hasQuery || hasFilter
                          ? 'Try adjusting your search query or rating filter'
                          : 'Enter keywords to search through your saved quotes',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (hasFilter) ...[
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _minRating = 0),
                        icon: const Icon(Icons.clear_rounded),
                        label: const Text('Clear rating filter'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
