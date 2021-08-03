/*
 * Copyright (c) 2021 CHANGLEI. All rights reserved.
 */

import 'package:flutter/cupertino.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// Created by box on 2020/4/21.
///
/// 图片预览控件
const double _kMaxDragDistance = 200;
const Duration _kDuration = Duration(milliseconds: 300);

/// 拖拽通知
class DragNotification extends Notification {}

/// 拖拽开始通知
class DragStartNotification extends DragNotification {
  /// 拖拽开始通知
  DragStartNotification({
    required this.details,
  });

  /// 拖拽的详细信息
  final DragStartDetails details;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DragStartNotification && runtimeType == other.runtimeType && details == other.details;

  @override
  int get hashCode => details.hashCode;

  @protected
  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('details: $details');
  }
}

/// 拖拽时的通知
class DragUpdateNotification extends DragNotification {
  /// 拖拽时的通知
  DragUpdateNotification({
    required this.details,
    required this.startPosition,
    required this.translationPosition,
    required this.scale,
    required this.opacity,
    required this.dragDistance,
    required this.navigationBarOffsetPixels,
    required this.bottomBarOffsetPixels,
  });

  /// 拖拽的详细信息
  final DragUpdateDetails details;

  /// 开始的位置
  final Offset startPosition;

  /// 移动的position
  final Offset translationPosition;

  /// 缩放级别
  final double scale;

  /// 透明度变化
  final double opacity;

  /// 拖拽的距离
  final double dragDistance;

  /// navigationBar的距离变化
  final double navigationBarOffsetPixels;

  /// bottomBar的距离变化
  final double bottomBarOffsetPixels;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DragUpdateNotification &&
          runtimeType == other.runtimeType &&
          details == other.details &&
          startPosition == other.startPosition &&
          translationPosition == other.translationPosition &&
          scale == other.scale &&
          opacity == other.opacity &&
          dragDistance == other.dragDistance &&
          navigationBarOffsetPixels == other.navigationBarOffsetPixels &&
          bottomBarOffsetPixels == other.bottomBarOffsetPixels;

  @override
  int get hashCode =>
      details.hashCode ^
      startPosition.hashCode ^
      translationPosition.hashCode ^
      scale.hashCode ^
      opacity.hashCode ^
      dragDistance.hashCode ^
      navigationBarOffsetPixels.hashCode ^
      bottomBarOffsetPixels.hashCode;

  @protected
  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('details: $details');
    description.add('startPosition: $startPosition');
    description.add('translationPosition: $translationPosition');
    description.add('scale: $scale');
    description.add('opacity: $opacity');
    description.add('dragDistance: $dragDistance');
    description.add('navigationBarOffsetPixels: $navigationBarOffsetPixels');
    description.add('bottomBarOffsetPixels: $bottomBarOffsetPixels');
  }
}

/// 拖拽结束通知
class DragEndNotification extends DragNotification {
  /// 拖拽结束通知
  DragEndNotification({
    required this.details,
  });

  /// 拖拽的详细信息
  final DragEndDetails details;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DragEndNotification && runtimeType == other.runtimeType && details == other.details;

  @override
  int get hashCode => details.hashCode;

  @protected
  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('details: $details');
  }
}

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

/// 拖拽结束回调
typedef DragEndCallback = bool Function(
  double dragDistance,
  double? velocity,
);

/// 图片预览
class PreimageView extends StatefulWidget {
  /// 图片预览
  const PreimageView.builder({
    Key? key,
    this.initialIndex = 0,
    required this.itemCount,
    required this.builder,
    this.onPageChanged,
    this.navigationBarBuilder,
    this.bottomBarBuilder,
    this.onPressed,
    this.onLongPressed,
    this.onScaleStateChanged,
    this.loadingBuilder,
    this.dragReferenceDistance = _kMaxDragDistance,
    this.duration = _kDuration,
    this.onDragEndCallback,
  })  : assert(dragReferenceDistance >= 0 && dragReferenceDistance != double.infinity),
        super(key: key);

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
  final double dragReferenceDistance;

  /// 页面可动元素的动画时长
  final Duration duration;

  /// 拖拽结束回调
  final DragEndCallback? onDragEndCallback;

  @override
  _PreimageViewState createState() => _PreimageViewState();
}

class _PreimageViewState extends State<PreimageView> with SingleTickerProviderStateMixin {
  final _navigationBarKey = GlobalKey();
  final _bottomBarKey = GlobalKey();

  late int _currentIndex = 0;
  late PageController _pageController;
  late Offset _startPosition;
  late Offset _translationPosition;
  late double _scaleOffset;
  late double _opacity;
  late double _dragDistance;
  late double _navigationBarOffsetPixels;
  late double _bottomBarOffsetPixels;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _pageController.addListener(_reset);
    _reset();
  }

  @override
  void didUpdateWidget(PreimageView oldWidget) {
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

  void _onLongPress() {
    widget.onLongPressed?.call(_currentIndex);
  }

  double _computeBarHeight(GlobalKey key) {
    return key.currentContext?.size?.height ?? 0.0;
  }

  void _onScaleStateChanged(PhotoViewScaleState scaleState) {
    if (_translationPosition != Offset.zero) {
      return;
    }
    double navBarOffsetPixels;
    double bottomOffsetPixels;
    switch (scaleState) {
      case PhotoViewScaleState.covering:
      case PhotoViewScaleState.originalSize:
      case PhotoViewScaleState.zoomedIn:
        navBarOffsetPixels = -_computeBarHeight(_navigationBarKey);
        bottomOffsetPixels = -_computeBarHeight(_bottomBarKey);
        break;
      case PhotoViewScaleState.initial:
      case PhotoViewScaleState.zoomedOut:
      default:
        navBarOffsetPixels = 0;
        bottomOffsetPixels = 0;
        break;
    }
    if (navBarOffsetPixels != _navigationBarOffsetPixels || bottomOffsetPixels != _bottomBarOffsetPixels) {
      _navigationBarOffsetPixels = navBarOffsetPixels;
      _bottomBarOffsetPixels = bottomOffsetPixels;
      setState(() {});
    }
    if (widget.onScaleStateChanged != null) {
      widget.onScaleStateChanged!(scaleState);
    }
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _pageController.jumpToPage(_currentIndex);
    _startPosition = details.localPosition;
    DragStartNotification(details: details).dispatch(context);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    final size = MediaQuery.of(context).size;
    final positionOffset = details.localPosition - _startPosition;
    _dragDistance = positionOffset.dy.abs();
    _scaleOffset = _dragDistance / (size.height * 2);
    _translationPosition = positionOffset + _startPosition * _scaleOffset;
    final dragOffset = _dragDistance / widget.dragReferenceDistance;
    _opacity = (1.0 - dragOffset).clamp(0.0, 1.0).toDouble();
    final barOffset = -dragOffset.clamp(0.0, 1.0);
    _navigationBarOffsetPixels = _computeBarHeight(_navigationBarKey) * barOffset;
    _bottomBarOffsetPixels = _computeBarHeight(_bottomBarKey) * barOffset;
    setState(() {});
    DragUpdateNotification(
      details: details,
      startPosition: _startPosition,
      translationPosition: _translationPosition,
      scale: 1.0 - _scaleOffset,
      opacity: _opacity,
      dragDistance: _dragDistance,
      navigationBarOffsetPixels: _navigationBarOffsetPixels,
      bottomBarOffsetPixels: _bottomBarOffsetPixels,
    ).dispatch(context);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final dragDistance = _translationPosition.dy < 0 ? -_dragDistance : _dragDistance;
    final onDragEndCallback = widget.onDragEndCallback;
    if (onDragEndCallback == null || !onDragEndCallback(dragDistance, details.primaryVelocity)) {
      _reset();
    } else {
      _dismiss();
    }
    DragEndNotification(details: details).dispatch(context);
  }

  void _reset() {
    _startPosition = Offset.zero;
    _translationPosition = Offset.zero;
    _scaleOffset = 0.0;
    _opacity = 1.0;
    _dragDistance = 0.0;
    _navigationBarOffsetPixels = 0.0;
    _bottomBarOffsetPixels = 0.0;
    setState(() {});
  }

  void _dismiss() {
    _startPosition = Offset.zero;
    _translationPosition = Offset.zero;
    _scaleOffset = 0.0;
    _opacity = 1.0;
    _dragDistance = 0.0;
    _navigationBarOffsetPixels = -_computeBarHeight(_navigationBarKey);
    _bottomBarOffsetPixels = -_computeBarHeight(_bottomBarKey);
    setState(() {});
  }

  Widget? _buildNavigationBar() {
    if (widget.navigationBarBuilder == null) {
      return null;
    }
    return widget.navigationBarBuilder!(
      context,
      _currentIndex,
      widget.itemCount,
    );
  }

  Widget? _buildBottomBar() {
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
    final scale = 1.0 - _scaleOffset;
    final positionOffset = _translationPosition;
    final duration = positionOffset == Offset.zero ? widget.duration : Duration.zero;
    final queryData = MediaQuery.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      onLongPress: _onLongPress,
      onTap: _onTap,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          AnimatedContainer(
            transform: Matrix4.translationValues(
              positionOffset.dx,
              positionOffset.dy,
              0,
            )..scale(scale, scale),
            duration: duration,
            curve: Curves.ease,
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
          AnimatedPositioned(
            left: 0,
            right: 0,
            bottom: _bottomBarOffsetPixels,
            duration: duration,
            child: DefaultTextStyle(
              style: DefaultTextStyle.of(context).style.copyWith(
                shadows: [
                  BoxShadow(
                    color: CupertinoColors.black.withOpacity(0.6),
                    blurRadius: 0.8,
                    offset: const Offset(0, 1.0),
                  ),
                ],
              ),
              child: Container(
                key: _bottomBarKey,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CupertinoColors.black.withOpacity(0.0),
                      CupertinoColors.black.withOpacity(0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                constraints: BoxConstraints(
                  minHeight: 0,
                  maxHeight: queryData.size.height / 4,
                ),
                child: AnimatedSize(
                  duration: widget.duration,
                  vsync: this,
                  alignment: Alignment.topCenter,
                  child: ClipRect(
                    child: _buildBottomBar(),
                  ),
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            left: 0,
            top: _navigationBarOffsetPixels,
            right: 0,
            duration: duration,
            child: Container(
              key: _navigationBarKey,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CupertinoColors.black.withOpacity(0.6),
                    CupertinoColors.black.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: _buildNavigationBar(),
            ),
          ),
        ],
      ),
    );
  }
}
