/*
 * Copyright (c) 2021 CHANGLEI. All rights reserved.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:preimage/src/vertigo_preview.dart';

/// 默认的动画执行时间
const _kDuration = Duration(
  milliseconds: 300,
);

/// 构建topBar和bottomBar
typedef PreimageBarBuilder = Widget Function(
  BuildContext context,
  int index,
  int count,
);

/// 边界类型
enum Edge {
  /// 起始
  start,

  /// 结束
  end,
}

/// Created by box on 2020/4/21.
///
/// 图片预览控件
class PreimageGallery extends StatefulWidget {
  /// 图片预览
  const PreimageGallery({
    Key? key,
    this.initialIndex = 0,
    required this.itemCount,
    required this.builder,
    this.onPageChanged,
    this.topBarBuilder,
    this.bottomBarBuilder,
    this.onPressed,
    this.onDoublePressed,
    this.onLongPressed,
    this.onScaleStateChanged,
    this.loadingBuilder,
    this.dragDamping,
    this.scaleDamping,
    this.duration = _kDuration,
    this.onDragStartCallback,
    this.onDragEndCallback,
    this.enabled = true,
    this.behavior,
    this.dragStartBehavior = DragStartBehavior.start,
    this.onOverEdge,
  }) : super(key: key);

  /// 初始index
  final int initialIndex;

  /// 图片左右切换时回调
  final ValueChanged<int>? onPageChanged;

  /// 构建topBar
  final PreimageBarBuilder? topBarBuilder;

  /// 构建bottomBar
  final PreimageBarBuilder? bottomBarBuilder;

  /// 点击
  final ValueChanged<int>? onPressed;

  /// 双击
  final ValueChanged<int>? onDoublePressed;

  /// 长按
  final ValueChanged<int>? onLongPressed;

  /// 缩放回调
  final ValueChanged<PhotoViewScaleState>? onScaleStateChanged;

  /// 构建loading
  final LoadingBuilder? loadingBuilder;

  /// The count of items in the gallery, only used when constructed via [PhotoViewGallery.builder]
  final int itemCount;

  /// Called to build items for the gallery when using [PhotoViewGallery.builder]
  final PhotoViewGalleryBuilder builder;

  /// 拖拽阻尼距离
  final double? dragDamping;

  /// 缩放阻尼距离
  final double? scaleDamping;

  /// 页面可动元素的动画时长
  final Duration duration;

  /// 拖动开始回调
  final VertigoDragStartCallback? onDragStartCallback;

  /// 拖拽结束回调
  final VertigoDragEndCallback? onDragEndCallback;

  /// 是否启用
  final bool enabled;

  /// How this gesture detector should behave during hit testing.
  ///
  /// This defaults to [HitTestBehavior.deferToChild] if [child] is not null and
  /// [HitTestBehavior.translucent] if child is null.
  final HitTestBehavior? behavior;

  /// Determines the way that drag start behavior is handled.
  ///
  /// If set to [DragStartBehavior.start], gesture drag behavior will
  /// begin upon the detection of a drag gesture. If set to
  /// [DragStartBehavior.down] it will begin when a down event is first detected.
  ///
  /// In general, setting this to [DragStartBehavior.start] will make drag
  /// animation smoother and setting it to [DragStartBehavior.down] will make
  /// drag behavior feel slightly more reactive.
  ///
  /// By default, the drag start behavior is [DragStartBehavior.start].
  ///
  /// Only the [DragGestureRecognizer.onStart] callbacks for the
  /// [VerticalDragGestureRecognizer], [HorizontalDragGestureRecognizer] and
  /// [PanGestureRecognizer] are affected by this setting.
  ///
  /// See also:
  ///
  ///  * [DragGestureRecognizer.dragStartBehavior], which gives an example for the different behaviors.
  final DragStartBehavior dragStartBehavior;

  /// 超过边界回调
  final ValueChanged<Edge>? onOverEdge;

  @override
  _PreimageGalleryState createState() => _PreimageGalleryState();
}

class _PreimageGalleryState extends State<PreimageGallery> {
  final _vertigoController = VertigoPreviewController();

  late int _currentIndex = 0;
  late PageController _pageController;

  bool _notifyOverEdge = true;

  @override
  void initState() {
    _currentIndex = widget.initialIndex;
    _pageController = PageController(
      initialPage: widget.initialIndex,
    );
    _pageController.addListener(() {
      _vertigoController.display(true);
    });
    super.initState();
  }

  @override
  void didUpdateWidget(PreimageGallery oldWidget) {
    if (widget.initialIndex != oldWidget.initialIndex) {
      _pageController.jumpToPage(widget.initialIndex);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _vertigoController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    _currentIndex = index;
    setState(() {});
    if (widget.onPageChanged != null) {
      widget.onPageChanged!(_currentIndex);
    }
  }

  void _onTap() {
    widget.onPressed?.call(_currentIndex);
  }

  void _onDoubleTap() {
    widget.onDoublePressed?.call(_currentIndex);
  }

  void _onLongPress() {
    widget.onLongPressed?.call(_currentIndex);
  }

  void _onScaleStateChanged(PhotoViewScaleState scaleState) {
    switch (scaleState) {
      case PhotoViewScaleState.covering:
      case PhotoViewScaleState.originalSize:
      case PhotoViewScaleState.zoomedIn:
        _vertigoController.display(false);
        break;
      case PhotoViewScaleState.initial:
      case PhotoViewScaleState.zoomedOut:
      default:
        _vertigoController.display(true);
        break;
    }
    if (widget.onScaleStateChanged != null) {
      widget.onScaleStateChanged!(scaleState);
    }
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

  Widget _buildTopBar(BuildContext context) {
    return widget.topBarBuilder!.call(
      context,
      _currentIndex,
      widget.itemCount,
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return widget.bottomBarBuilder!.call(
      context,
      _currentIndex,
      widget.itemCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasTopBar = widget.topBarBuilder != null;
    final hasBottomBar = widget.bottomBarBuilder != null;
    return VertigoPreview(
      controller: _vertigoController,
      duration: widget.duration,
      topBarBuilder: hasTopBar ? _buildTopBar : null,
      bottomBarBuilder: hasBottomBar ? _buildBottomBar : null,
      dragDamping: widget.dragDamping,
      scaleDamping: widget.scaleDamping,
      onPressed: _onTap,
      onDoublePressed: _onDoubleTap,
      onLongPressed: _onLongPress,
      onDragStartCallback: (details) {
        _pageController.jumpToPage(_currentIndex);
        widget.onDragStartCallback?.call(details);
      },
      onDragEndCallback: widget.onDragEndCallback,
      enabled: widget.enabled,
      behavior: widget.behavior,
      dragStartBehavior: widget.dragStartBehavior,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: PhotoViewGallery.builder(
          itemCount: widget.itemCount,
          scrollDirection: Axis.horizontal,
          enableRotation: true,
          gaplessPlayback: true,
          backgroundDecoration: BoxDecoration(
            color: CupertinoColors.black.withOpacity(0.0),
          ),
          pageController: _pageController,
          onPageChanged: _onPageChanged,
          loadingBuilder: widget.loadingBuilder,
          scaleStateChangedCallback: _onScaleStateChanged,
          builder: widget.builder,
        ),
      ),
    );
  }
}
