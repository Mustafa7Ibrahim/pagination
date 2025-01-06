library pagination;

export 'package:pagination/src/pagination_status.dart';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:pagination/src/utils.dart';

import 'src/pagination_status.dart';

/// A widget that provides paginated view for items of type [T] using slivers.
class SliverNestedPagination<T> extends StatefulWidget {
  const SliverNestedPagination({
    super.key,
    required this.hasReachedMax,
    required this.itemsPerPage,
    required this.onLoadMore,
    required this.status,
    required this.data,
    required this.builder,
    required this.headerSliverBuilder,
    this.errorWidget,
    this.loadingWidget,
    this.loadingMoreWidget,
    this.errorLoadMoreWidget,
    this.physics,
    this.emptyWidget,
    this.controller,
    this.header,
  });

  final bool hasReachedMax;
  final int itemsPerPage;
  final List<T> data;
  final void Function(int) onLoadMore;
  final PaginationStatus status;
  final List<Widget> Function(BuildContext, bool) headerSliverBuilder;
  final Widget? header;
  final Widget? errorWidget;
  final Widget? loadingWidget;
  final Widget? loadingMoreWidget;
  final ErrorLoadMoreWidget? errorLoadMoreWidget;
  final ScrollPhysics? physics;
  final Widget? emptyWidget;
  final ScrollController? controller;
  final SliverPaginationBuilder<T> builder;

  @override
  State<SliverNestedPagination<T>> createState() => _SliverNestedPaginationState<T>();
}

class _SliverNestedPaginationState<T> extends State<SliverNestedPagination<T>> {
  late final ScrollController _scrollController;
  bool _isLoading = false;
  late final int _loadThreshold = widget.itemsPerPage - 3;

  int get _page => widget.data.length ~/ widget.itemsPerPage + 1;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
  }

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
      final remainingScroll =
          _scrollController.position.maxScrollExtent - scrollInfo.metrics.pixels;
      if (remainingScroll <= 100) {
        _loadMore();
      }
    }
    return false;
  }

  @override
  void didUpdateWidget(covariant SliverNestedPagination<T> oldWidget) {
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
    final bool isFirstPageLoading = widget.status == PaginationStatus.loading && _page == 1;
    final bool isFirstPageError = widget.status == PaginationStatus.error && _page == 1;

    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: widget.headerSliverBuilder,
        body: CustomScrollView(
          controller: _scrollController,
          physics: widget.physics,
          slivers: [
            widget.header ?? const SliverToBoxAdapter(),
            if (isFirstPageLoading)
              SliverFillRemaining(
                child: FadeIn(
                  child: widget.loadingWidget ??
                      const Center(child: CircularProgressIndicator.adaptive()),
                ),
              )
            else if (isFirstPageError)
              SliverFillRemaining(
                child: FadeIn(
                  child: widget.errorWidget ?? const Center(child: Text('Error loading data')),
                ),
              )
            else if (widget.data.isEmpty)
              SliverFillRemaining(
                child: FadeIn(
                  child: widget.emptyWidget ?? const Center(child: Text('No data available')),
                ),
              )
            else
              widget.builder(widget.data),
            if (widget.status == PaginationStatus.loading && _page > 1)
              SliverToBoxAdapter(
                child: FadeIn(
                  child: SafeArea(
                    child: widget.loadingMoreWidget ??
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator.adaptive()),
                        ),
                  ),
                ),
              ),
            if (widget.status == PaginationStatus.error && _page > 1)
              SliverToBoxAdapter(
                child: FadeIn(
                  child: widget.errorLoadMoreWidget?.call(_page) ??
                      const Center(child: Text('Error loading data')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
