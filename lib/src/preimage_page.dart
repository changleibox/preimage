/*
 * Copyright (c) 2021 CHANGLEI. All rights reserved.
 */

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:preimage/src/preimage_gallery.dart';
import 'package:preimage/src/preimage_route.dart';
import 'package:preimage/src/primitive_navigation_bar.dart';
import 'package:preimage/src/vertigo_preview.dart';

const _dragVelocity = 100.0;
const _dragDamping = 200.0;
const _kDuration = Duration(
  milliseconds: 300,
);
const _transparent = Color(0x00000000);

/// 构建navigationBar
typedef PreimageTopBarBuilder = Widget Function(
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
    PreimageTopBarBuilder? topBarBuilder = _buildTopBar,
    PreimageBarBuilder? bottomBarBuilder,
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
        topBarBuilder: topBarBuilder,
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
    PreimageTopBarBuilder? topBarBuilder = _buildTopBar,
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
        topBarBuilder: topBarBuilder,
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

  static Widget _buildTopBar(
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

/// 图片
class ImageOptions {
  /// 图片
  const ImageOptions({
    required this.url,
    String? tag,
  })  : _tag = tag,
        child = null,
        childSize = null;

  /// 自定义child
  const ImageOptions.child({
    required this.url,
    this.child,
    this.childSize,
  }) : _tag = null;

  /// 图片地址，可以是远程路径和本地路径
  final String? url;

  /// 构建item
  final Widget? child;

  /// childSize
  final Size? childSize;

  /// hero的tag
  final String? _tag;

  /// 是否为空
  bool get isEmpty => url == null || url!.isEmpty;

  /// 是否不为空
  bool get isNotEmpty => url != null && url!.isNotEmpty;

  /// 复制一个
  ImageOptions copyWith({String? url, String? tag, Size? thumbnailSize}) {
    return ImageOptions(
      url: url ?? this.url,
      tag: tag ?? _tag,
    );
  }

  /// HeroTag
  Object? get tag => PreimageHero._buildHeroTag(_tag);
}

class _HeroTag {
  const _HeroTag(this.url);

  final String url;

  @override
  String toString() => url;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _HeroTag && other.url == url;
  }

  @override
  int get hashCode {
    return identityHashCode(url);
  }
}

/// hero
class PreimageHero extends StatelessWidget {
  /// hero
  const PreimageHero({
    Key? key,
    required this.tag,
    required this.child,
    this.createRectTween,
    this.flightShuttleBuilder,
    this.placeholderBuilder = _buildPlaceholder,
    this.transitionOnUserGestures = false,
  }) : super(key: key);

  /// Hero.tag
  final String? tag;

  /// child
  final Widget child;

  /// Hero.createRectTween
  final CreateRectTween? createRectTween;

  /// Hero.flightShuttleBuilder
  final HeroFlightShuttleBuilder? flightShuttleBuilder;

  /// Hero.placeholderBuilder
  final HeroPlaceholderBuilder? placeholderBuilder;

  /// Hero.placeholderBuilder
  final bool transitionOnUserGestures;

  static Widget _buildPlaceholder(BuildContext context, Size heroSize, Widget child) {
    return child;
  }

  @override
  Widget build(BuildContext context) {
    if (tag == null || tag!.isEmpty) {
      return child;
    }
    return Hero(
      tag: _buildHeroTag(tag)!,
      createRectTween: createRectTween,
      flightShuttleBuilder: flightShuttleBuilder,
      placeholderBuilder: placeholderBuilder,
      transitionOnUserGestures: transitionOnUserGestures,
      child: child,
    );
  }

  static Object? _buildHeroTag(String? tag) {
    if (tag == null || tag.isEmpty) {
      return null;
    }
    return _HeroTag('preimage:$tag');
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
    this.topBarBuilder,
    this.bottomBarBuilder,
    this.onLongPressed,
    this.onOverEdge,
  })  : assert(images.length > 0),
        assert(initialIndex >= 0 && initialIndex < images.length),
        super(key: key);

  /// 预览单张图片
  factory PreimagePage.single(
    ImageOptions image, {
    PreimageTopBarBuilder? topBarBuilder,
    WidgetBuilder? bottomBarBuilder,
    ValueChanged<ImageOptions>? onLongPressed,
  }) {
    PreimageBarBuilder? convertedBottomBarBuilder;
    if (bottomBarBuilder != null) {
      convertedBottomBarBuilder = (context, index, count) {
        return bottomBarBuilder(context);
      };
    }
    return PreimagePage(
      images: [image],
      onLongPressed: onLongPressed,
      topBarBuilder: topBarBuilder,
      bottomBarBuilder: convertedBottomBarBuilder,
    );
  }

  /// 初始的索引
  final int initialIndex;

  /// 需要显示的图片组
  final List<ImageOptions> images;

  /// 索引变化的时候
  final ValueChanged<int>? onIndexChanged;

  /// 构建预览页面的navigationBar
  final PreimageTopBarBuilder? topBarBuilder;

  /// 构建预览页面的bottomBar
  final PreimageBarBuilder? bottomBarBuilder;

  /// 长按回调
  final ValueChanged<ImageOptions>? onLongPressed;

  /// 超过边界回调
  final ValueChanged<Edge>? onOverEdge;

  @override
  _PreimagePageState createState() => _PreimagePageState();
}

class _PreimagePageState extends State<PreimagePage> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  double _offset = 1.0;

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

  void _onPressed(int index) {
    _onBackPressed();
  }

  void _onLongPressed(int index) {
    if (widget.onLongPressed != null) {
      widget.onLongPressed!(widget.images[index]);
    }
  }

  void _onDragStartCallback(DragStartDetails details) {
    if (mounted) {
      setState(() {
        _offset = 1.0;
      });
    }
  }

  bool _onDragEndCallback(Offset dragDistance, double? velocity) {
    final dy = dragDistance.dy;
    velocity ??= 0;
    if (dy >= _dragDamping / 2 || (dy >= 0 && velocity >= _dragVelocity)) {
      _onBackPressed();
      return true;
    }
    if (mounted) {
      setState(() {
        _offset = 1.0;
      });
    }
    return false;
  }

  bool _onDragNotification(DragUpdateNotification notification) {
    if (mounted) {
      setState(() {
        _offset = notification.offset;
      });
    }
    return false;
  }

  Widget _buildLoading(BuildContext context, ImageChunkEvent? event) {
    double? offset;
    final totalBytes = event?.expectedTotalBytes ?? 1.0;
    if (event != null && totalBytes != 0) {
      offset = event.cumulativeBytesLoaded.toDouble() / totalBytes;
    }
    Widget child = const CupertinoActivityIndicator(
      radius: 14,
    );
    if (offset != null) {
      child = CupertinoActivityIndicator.partiallyRevealed(
        radius: 14,
        progress: offset.clamp(0, 1).toDouble(),
      );
    }
    return Center(
      child: child,
    );
  }

  Widget _buildTopBar(BuildContext context, int index, int count) {
    return widget.topBarBuilder!(
      context,
      index,
      count,
      _onBackPressed,
    );
  }

  ImageProvider _buildImageProvider(BuildContext context, int index) {
    final url = widget.images[index].url;
    if (url!.startsWith(RegExp(r'http|https'))) {
      return CachedNetworkImageProvider(url);
    } else {
      return FileImage(File(url));
    }
  }

  PhotoViewGalleryPageOptions _buildPageOptions(BuildContext context, int index) {
    final imageOptions = widget.images[index];
    final heroTag = imageOptions.tag;
    PhotoViewHeroAttributes? attributes;
    if (heroTag != null) {
      attributes = PhotoViewHeroAttributes(
        tag: heroTag,
      );
    }
    final child = imageOptions.child;
    if (child != null) {
      return PhotoViewGalleryPageOptions.customChild(
        child: child,
        childSize: imageOptions.childSize,
        initialScale: PhotoViewComputedScale.contained,
        basePosition: Alignment.center,
        tightMode: true,
        disableGestures: true,
        gestureDetectorBehavior: HitTestBehavior.translucent,
        heroAttributes: attributes,
      );
    } else {
      return PhotoViewGalleryPageOptions(
        imageProvider: _buildImageProvider(context, index),
        initialScale: PhotoViewComputedScale.contained,
        basePosition: Alignment.center,
        tightMode: true,
        gestureDetectorBehavior: HitTestBehavior.translucent,
        heroAttributes: attributes,
      );
    }
  }

  SystemUiOverlayStyle get _overlayStyle {
    final isDark = _offset > 0.5;
    final newBrightness = isDark ? Brightness.dark : Brightness.light;
    final SystemUiOverlayStyle overlayStyle;
    switch (newBrightness) {
      case Brightness.dark:
        overlayStyle = SystemUiOverlayStyle.light;
        break;
      case Brightness.light:
        overlayStyle = SystemUiOverlayStyle.dark;
        break;
    }
    return overlayStyle;
  }

  @override
  Widget build(BuildContext context) {
    final duration = _offset == 1.0 ? _kDuration : Duration.zero;
    final hasTopBar = widget.topBarBuilder != null;
    final queryData = MediaQuery.of(context);
    return CupertinoTheme(
      data: CupertinoTheme.of(context).copyWith(
        primaryColor: CupertinoColors.white,
        scaffoldBackgroundColor: _transparent,
        brightness: Brightness.dark,
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: _overlayStyle,
        child: CupertinoPageScaffold(
          child: MediaQuery(
            data: queryData.copyWith(
              textScaleFactor: 1.0,
            ),
            child: AnimatedContainer(
              duration: duration,
              color: CupertinoColors.black.withOpacity(_offset),
              child: NotificationListener<DragUpdateNotification>(
                onNotification: _onDragNotification,
                child: PreimageGallery(
                  initialIndex: widget.initialIndex,
                  topBarBuilder: hasTopBar ? _buildTopBar : null,
                  bottomBarBuilder: widget.bottomBarBuilder,
                  loadingBuilder: _buildLoading,
                  duration: _kDuration,
                  dragDamping: _dragDamping,
                  scaleDamping: queryData.size.height * 2,
                  onPressed: _onPressed,
                  onLongPressed: _onLongPressed,
                  onPageChanged: _onPageChanged,
                  onDragStartCallback: _onDragStartCallback,
                  onDragEndCallback: _onDragEndCallback,
                  behavior: HitTestBehavior.translucent,
                  onOverEdge: widget.onOverEdge,
                  itemCount: widget.images.length,
                  builder: _buildPageOptions,
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
