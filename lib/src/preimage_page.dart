/*
 * Copyright (c) 2021 CHANGLEI. All rights reserved.
 */

import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:preimage/src/preimage_route.dart';
import 'package:preimage/src/preimage_view.dart';
import 'package:preimage/src/primitive_navigation_bar.dart';
import 'package:preimage/src/support_activity_indicator.dart';

const double _kMaxDragVelocity = 100;
const double _kMaxDragDistance = 200;
const Duration _kDuration = Duration(milliseconds: 300);

/// 构建navigationBar
typedef PreimageNavigationBarBuilder = Widget Function(
  BuildContext context,
  int index,
  int count,
  VoidCallback onBackPressed,
);

/// 图片预览
class Preimage {
  const Preimage._();

  /// 预览一组图片
  static Future<T?> preview<T>(
    BuildContext context, {
    int initialIndex = 0,
    required List<ImageOptions?>? images,
    ValueChanged<int>? onIndexChanged,
    PreimageNavigationBarBuilder? navigationBarBuilder = _buildNavigationBar,
    IndexedWidgetBuilder? bottomBarBuilder,
    ValueChanged<ImageOptions>? onLongPressed,
    ValueChanged<Edge>? onOverEdge,
    bool rootNavigator = false,
  }) {
    final _images = images?.where((image) => image != null && image.isNotEmpty).toList();
    if (_images == null || _images.isEmpty) {
      return Future.value();
    }
    return _push(
      context,
      PreimagePage(
        initialIndex: initialIndex,
        images: _images.map((e) => e!).toList(),
        onIndexChanged: onIndexChanged,
        navigationBarBuilder: navigationBarBuilder,
        bottomBarBuilder: bottomBarBuilder,
        onLongPressed: onLongPressed,
        onOverEdge: onOverEdge,
      ),
      rootNavigator: rootNavigator,
    );
  }

  /// 预览单张图片
  static Future<T?> previewSingle<T>(
    BuildContext context,
    ImageOptions? image, {
    PreimageNavigationBarBuilder navigationBarBuilder = _buildNavigationBar,
    WidgetBuilder? bottomBarBuilder,
    ValueChanged<ImageOptions>? onLongPressed,
    bool rootNavigator = false,
  }) {
    if (image == null || image.isEmpty) {
      return Future.value();
    }
    return _push(
      context,
      PreimagePage.single(
        image,
        navigationBarBuilder: navigationBarBuilder,
        bottomBarBuilder: bottomBarBuilder,
        onLongPressed: onLongPressed,
      ),
      rootNavigator: rootNavigator,
    );
  }

  static Future<T?> _push<T>(BuildContext context, Widget widget, {bool rootNavigator = false}) {
    return Navigator.of(context, rootNavigator: rootNavigator).push(
      PreimageRoute(
        opaque: false,
        fullscreenDialog: false,
        builder: (context) => widget,
      ),
    );
  }

  static Widget _buildNavigationBar(
    BuildContext context,
    int index,
    int count,
    VoidCallback onBackPressed,
  ) {
    return _DefaultNavigationBar(
      currentIndex: index,
      count: count,
      onBackPressed: onBackPressed,
    );
  }
}

/// 图片预览
class PreimagePage extends StatefulWidget {
  /// 构造函数
  const PreimagePage({
    Key? key,
    this.initialIndex = 0,
    required this.images,
    this.onIndexChanged,
    this.navigationBarBuilder,
    this.bottomBarBuilder,
    this.onLongPressed,
    this.onOverEdge,
  })  : assert(images.length > 0),
        assert(initialIndex >= 0 && initialIndex < images.length),
        super(key: key);

  /// 预览单张图片
  factory PreimagePage.single(
    ImageOptions image, {
    WidgetBuilder? bottomBarBuilder,
    PreimageNavigationBarBuilder? navigationBarBuilder,
    ValueChanged<ImageOptions>? onLongPressed,
  }) {
    return PreimagePage(
      images: [image],
      onLongPressed: onLongPressed,
      navigationBarBuilder: navigationBarBuilder,
      bottomBarBuilder: bottomBarBuilder == null ? null : (context, index) => bottomBarBuilder(context),
    );
  }

  /// 初始的索引
  final int initialIndex;

  /// 需要显示的图片组
  final List<ImageOptions> images;

  /// 索引变化的时候
  final ValueChanged<int>? onIndexChanged;

  /// 构建预览页面的navigationBar
  final PreimageNavigationBarBuilder? navigationBarBuilder;

  /// 构建预览页面的bottomBar
  final IndexedWidgetBuilder? bottomBarBuilder;

  /// 长按回调
  final ValueChanged<ImageOptions>? onLongPressed;

  /// 超过边界回调
  final ValueChanged<Edge>? onOverEdge;

  @override
  _PreimagePageState createState() => _PreimagePageState();
}

class _PreimagePageState extends State<PreimagePage> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  double _opacity = 1.0;
  bool _notifyOverEdge = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onPageChanged(int index) {
    _currentIndex = index;
  }

  void _onBackPressed() {
    if (widget.onIndexChanged != null) {
      widget.onIndexChanged!(_currentIndex);
    }
    Navigator.maybePop(context, _currentIndex);
  }

  void _onPressed(ImageOptions options) {
    _onBackPressed();
  }

  void _onLongPressed(ImageOptions options) {
    if (widget.onLongPressed != null) {
      widget.onLongPressed!(options);
    }
  }

  bool _onDragEndCallback(double dragDistance, double? velocity) {
    velocity ??= 0;
    if (dragDistance > _kMaxDragDistance / 2 || velocity >= _kMaxDragVelocity) {
      _onBackPressed();
      return true;
    }
    return false;
  }

  bool _onDragNotification(DragNotification notification) {
    if (notification is DragUpdateNotification) {
      _opacity = notification.opacity;
    } else {
      _opacity = 1.0;
    }
    setState(() {});
    return false;
  }

  bool _onScrollNotification(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (!metrics.hasPixels || !metrics.hasContentDimensions || widget.onOverEdge == null) {
      _notifyOverEdge = true;
      return false;
    }
    if (notification is UserScrollNotification && !metrics.outOfRange) {
      _notifyOverEdge = true;
    }
    if ((notification is! ScrollUpdateNotification && notification is! OverscrollNotification) || !_notifyOverEdge) {
      return false;
    }
    final pixels = metrics.pixels;
    final minScrollExtent = metrics.minScrollExtent;
    final maxScrollExtent = metrics.maxScrollExtent;
    if (pixels < minScrollExtent) {
      _notifyOverEdge = false;
      widget.onOverEdge?.call(Edge.start);
    } else if (pixels > maxScrollExtent) {
      _notifyOverEdge = false;
      widget.onOverEdge?.call(Edge.end);
    } else if (notification is OverscrollNotification) {
      _notifyOverEdge = false;
      final overscroll = notification.overscroll;
      widget.onOverEdge?.call(overscroll.isNegative ? Edge.start : Edge.end);
    }
    return false;
  }

  ImageProvider _buildImageProvider(BuildContext context, int index) {
    final url = widget.images[index].url;
    if (url!.startsWith('http')) {
      return CachedNetworkImageProvider(url);
    } else {
      return FileImage(File(url));
    }
  }

  Widget _buildLoading(BuildContext context, ImageChunkEvent? event) {
    double? offset;
    if (event != null) {
      final totalBytes = event.expectedTotalBytes ?? 1;
      offset = event.cumulativeBytesLoaded.toDouble() / totalBytes.toDouble();
    }
    return Center(
      child: SupportCupertinoActivityIndicator(
        radius: 14,
        animating: offset == null,
        position: offset,
      ),
    );
  }

  Widget? _buildNavigationBar(BuildContext context, int index, int count) {
    if (widget.navigationBarBuilder == null) {
      return null;
    }
    return widget.navigationBarBuilder!(
      context,
      index,
      count,
      _onBackPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final duration = _opacity == 1.0 ? _kDuration : Duration.zero;
    final queryData = MediaQuery.of(context);
    return CupertinoTheme(
      data: CupertinoTheme.of(context).copyWith(
        primaryColor: CupertinoColors.white,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: CupertinoColors.black.withOpacity(0),
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: CupertinoPageScaffold(
          child: MediaQuery(
            data: queryData.copyWith(
              textScaleFactor: 1.0,
            ),
            child: AnimatedContainer(
              duration: duration,
              color: CupertinoColors.black.withOpacity(_opacity),
              child: NotificationListener<DragNotification>(
                onNotification: _onDragNotification,
                child: NotificationListener<ScrollNotification>(
                  onNotification: _onScrollNotification,
                  child: PreimageView(
                    initialIndex: widget.initialIndex,
                    images: widget.images,
                    imageProviderBuilder: _buildImageProvider,
                    navigationBarBuilder: _buildNavigationBar,
                    bottomBarBuilder: widget.bottomBarBuilder,
                    loadingBuilder: _buildLoading,
                    duration: _kDuration,
                    dragReferenceDistance: _kMaxDragDistance,
                    onPressed: _onPressed,
                    onLongPressed: _onLongPressed,
                    onPageChanged: _onPageChanged,
                    onDragEndCallback: _onDragEndCallback,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DefaultNavigationBar extends StatelessWidget {
  const _DefaultNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.count,
    required this.onBackPressed,
  })  : assert(currentIndex < count),
        super(key: key);

  final int currentIndex;
  final int count;
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    return PrimitiveNavigationBar(
      middle: Text('${currentIndex + 1}/$count'),
      padding: const EdgeInsetsDirectional.only(
        start: 10,
        end: 10,
      ),
      brightness: Brightness.dark,
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.zero,
        onPressed: onBackPressed,
        child: const Text('关闭'),
      ),
    );
  }
}

/// 边界类型
enum Edge {
  /// 起始
  start,

  /// 结束
  end,
}
