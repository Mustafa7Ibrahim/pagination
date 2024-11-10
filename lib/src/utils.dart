import 'package:flutter/material.dart';

/// Builder function type for displaying paginated data.
typedef PaginationBuilder<T> = Widget Function(
  List<T> data,
  ScrollPhysics physics,
  bool shrinkWrap,
);

/// builder function type for displaying pagination for a sliver list.
typedef SliverPaginationBuilder<T> = Widget Function(List<T> data);

/// Error widget builder for load more errors.
typedef ErrorLoadMoreWidget = Widget Function(int page);
