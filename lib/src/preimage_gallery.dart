/*
 * Copyright (c) 2021 CHANGLEI. All rights reserved.
 */

import 'package:flutter/cupertino.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:preimage/src/vertigo_preview.dart' as vertigo;

/// Created by box on 2020/4/21.
///
/// 图片预览控件
const Duration _kDuration = Duration(
  milliseconds: 300,
);

/// 构建navigationBar
typedef PreimageNavigationBuilder = Widget? Function(
  BuildContext context,
  int index,
  int count,
);

/// 构建Provider
typedef ImageProviderBuilder = ImageProvider Function(
  BuildContext context,
  int index,
);

/// 图片预览
class PreimageGallery extends StatefulWidget {
  /// 图片预览
  const PreimageGallery.builder({
    Key? key,
    this.initialIndex = 0,
    required this.itemCount,
    required this.builder,
    this.onPageChanged,
    this.navigationBarBuilder,
    this.bottomBarBuilder,
    this.onPressed,
    this.onDoublePressed,
    this.onLongPressed,
    this.onScaleStateChanged,
    this.loadingBuilder,
    this.dampingDistance,
    this.duration = _kDuration,
    this.onDragEndCallback,
  }) : super(key: key);

  /// 初始index
  final int initialIndex;

  /// 图片左右切换时回调
  final ValueChanged<int>? onPageChanged;

  /// 构建navigationBar
  final PreimageNavigationBuilder? navigationBarBuilder;

  /// 构建bottomBar
  final PreimageNavigationBuilder? bottomBarBuilder;

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

  /// 组大拖拽距离
  final double? dampingDistance;

  /// 页面可动元素的动画时长
  final Duration duration;

  /// 拖拽结束回调
  final vertigo.DragEndCallback? onDragEndCallback;

  @override
  _PreimageGalleryState createState() => _PreimageGalleryState();
}

class _PreimageGalleryState extends State<PreimageGallery> {
  final _vertigoController = vertigo.VertigoPreviewController();

  late int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    _currentIndex = widget.initialIndex;
    _pageController = PageController(
      initialPage: widget.initialIndex,
    );
    _pageController.addListener(_vertigoController.reset);
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
    bool result;
    switch (scaleState) {
      case PhotoViewScaleState.covering:
      case PhotoViewScaleState.originalSize:
      case PhotoViewScaleState.zoomedIn:
        result = _vertigoController.switchBar(false);
        break;
      case PhotoViewScaleState.initial:
      case PhotoViewScaleState.zoomedOut:
      default:
        result = _vertigoController.switchBar(true);
        break;
    }
    if (result && widget.onScaleStateChanged != null) {
      widget.onScaleStateChanged!(scaleState);
    }
  }

  Widget? _buildNavigationBar(BuildContext context) {
    if (widget.navigationBarBuilder == null) {
      return null;
    }
    return widget.navigationBarBuilder!(
      context,
      _currentIndex,
      widget.itemCount,
    );
  }

  Widget? _buildBottomBar(BuildContext context) {
    Widget? bottomBar;
    if (widget.bottomBarBuilder != null) {
      bottomBar = widget.bottomBarBuilder!(
        context,
        _currentIndex,
        widget.itemCount,
      );
    }
    if (bottomBar != null) {
      bottomBar = SingleChildScrollView(
        child: bottomBar,
      );
    }
    return bottomBar;
  }

  @override
  Widget build(BuildContext context) {
    final navigationBar = _buildNavigationBar(context);
    final bottomBar = _buildBottomBar(context);
    return NotificationListener<vertigo.DragStartNotification>(
      onNotification: (notification) {
        _pageController.jumpToPage(_currentIndex);
        return false;
      },
      child: vertigo.VertigoPreview(
        duration: widget.duration,
        navigationBarBuilder: navigationBar == null ? null : (context) => navigationBar,
        bottomBarBuilder: bottomBar == null ? null : (context) => bottomBar,
        onDragEndCallback: widget.onDragEndCallback,
        dampingDistance: widget.dampingDistance,
        onPressed: _onTap,
        onDoublePressed: _onDoubleTap,
        onLongPressed: _onLongPress,
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