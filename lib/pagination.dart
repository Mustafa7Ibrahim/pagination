library pagination;

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:pagination/src/utils.dart';

import 'src/pagination_status.dart';

export 'package:pagination/src/pagination_status.dart';

/// A widget that provides paginated view for items of type [T].
class Pagination<T> extends StatefulWidget {
  const Pagination({
    super.key,
    required this.hasReachedMax,
    required this.itemsPerPage,
    required this.onLoadMore,
    required this.status,
    required this.data,
    required this.builder,
    this.errorWidget,
    this.errorLoadMoreWidget,
    this.physics,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.emptyWidget,
  });

  final bool hasReachedMax;
  final int itemsPerPage;
  final List<T> data;
  final void Function(int) onLoadMore;
  final PaginationStatus status;
  final Widget? errorWidget;
  final ErrorLoadMoreWidget? errorLoadMoreWidget;
  final ScrollPhysics? physics;
  final CrossAxisAlignment crossAxisAlignment;
  final Widget? emptyWidget;
  final PaginationBuilder<T> builder;

  @override
  State<Pagination<T>> createState() => _PaginationState<T>();
}

class _PaginationState<T> extends State<Pagination<T>> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  late final int _loadThreshold = widget.itemsPerPage - 3;

  int get _page => widget.data.length ~/ widget.itemsPerPage + 1;

  void _loadMore() {
    if (_isLoading || widget.hasReachedMax) return;
    _isLoading = true;
    widget.onLoadMore(_page);
    Future.delayed(const Duration(milliseconds: 250), () {
      _isLoading = false;
    });
  }

  void _checkAndLoadDataIfNeeded() {
    if (widget.hasReachedMax ||
        widget.status == PaginationStatus.loading ||
        widget.status == PaginationStatus.error) return;

    if (widget.data.length <= _loadThreshold && _page < 2) {
      _loadMore();
    }
  }

  bool _onScrollNotification(ScrollNotification scrollInfo) {
    if (widget.hasReachedMax ||
        widget.status == PaginationStatus.loading ||
        widget.status == PaginationStatus.error) return false;

    if (scrollInfo is ScrollUpdateNotification) {
      final remainingScroll = _scrollController.position.maxScrollExtent -
          scrollInfo.metrics.pixels;
      if (remainingScroll <= 100) {
        _loadMore();
      }
    }
    return false;
  }

  @override
  void didUpdateWidget(covariant Pagination<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAndLoadDataIfNeeded();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isFirstPageLoading =
        widget.status == PaginationStatus.loading && _page == 1;
    final bool isFirstPageError =
        widget.status == PaginationStatus.error && _page == 1;

    final size = MediaQuery.sizeOf(context);

    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: widget.physics,
        child: Column(
          crossAxisAlignment: widget.crossAxisAlignment,
          children: [
            if (isFirstPageLoading)
              FadeIn(
                child: SizedBox(
                  height: size.height * 0.7,
                  width: size.width,
                  child: const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                ),
              )
            else if (isFirstPageError)
              FadeIn(
                child: SizedBox(
                  height: size.height * 0.7,
                  width: size.width,
                  child: widget.errorWidget ??
                      const Center(child: Text('Error loading data')),
                ),
              )
            else if (widget.data.isEmpty)
              FadeIn(
                child: SizedBox(
                  height: size.height * 0.7,
                  width: size.width,
                  child: widget.emptyWidget ??
                      const Center(child: Text('No data available')),
                ),
              )
            else
              FadeIn(
                child: widget.builder(
                  widget.data,
                  const NeverScrollableScrollPhysics(),
                  true,
                ),
              ),
            if (widget.status == PaginationStatus.loading && _page > 1)
              FadeIn(
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  ),
                ),
              ),
            if (widget.status == PaginationStatus.error && _page > 1)
              FadeInUp(
                child: widget.errorLoadMoreWidget?.call(_page) ??
                    const Center(child: Text('Error loading data')),
              ),
          ],
        ),
      ),
    );
  }
}
