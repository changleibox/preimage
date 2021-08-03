/*
 * Copyright (c) 2021 CHANGLEI. All rights reserved.
 */

import 'package:flutter/cupertino.dart';

/// Created by box on 2020/4/21.
///
/// 图片预览控件
const Duration _kDuration = Duration(
  milliseconds: 300,
);

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
    required this.dragDistance,
    required this.offset,
  });

  /// 拖拽的详细信息
  final DragUpdateDetails details;

  /// 开始的位置
  final Offset startPosition;

  /// 拖拽的距离
  final Offset dragDistance;

  /// 透明度变化
  final double offset;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DragUpdateNotification &&
          runtimeType == other.runtimeType &&
          details == other.details &&
          startPosition == other.startPosition &&
          dragDistance == other.dragDistance &&
          offset == other.offset;

  @override
  int get hashCode => details.hashCode ^ startPosition.hashCode ^ dragDistance.hashCode ^ offset.hashCode;

  @protected
  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('details: $details');
    description.add('startPosition: $startPosition');
    description.add('dragDistance: $dragDistance');
    description.add('opacity: $offset');
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

/// 拖拽结束回调
typedef VertigoDragEndCallback = bool Function(
  Offset dragDistance,
  double? velocity,
);

/// controller
class VertigoPreviewController {
  _VertigoPreviewState? _state;

  /// 重置
  void reset() {
    _state?._reset();
  }

  /// 消失
  void dismiss() {
    _state?._dismiss();
  }

  /// 显示bar
  bool switchBar(bool show) {
    return _state?._switchBar(show) == true;
  }
}

/// 图片预览
class VertigoPreview extends StatefulWidget {
  /// 图片预览
  const VertigoPreview({
    Key? key,
    required this.child,
    this.controller,
    this.navigationBarBuilder,
    this.bottomBarBuilder,
    this.onPressed,
    this.onDoublePressed,
    this.onLongPressed,
    this.dampingDistance,
    this.duration = _kDuration,
    this.onDragEndCallback,
    this.enabled = true,
  }) : super(key: key);

  /// child
  final Widget child;

  /// controller
  final VertigoPreviewController? controller;

  /// 构建navigationBar
  final WidgetBuilder? navigationBarBuilder;

  /// 构建bottomBar
  final WidgetBuilder? bottomBarBuilder;

  /// 点击
  final VoidCallback? onPressed;

  /// 长按
  final VoidCallback? onDoublePressed;

  /// 双击
  final VoidCallback? onLongPressed;

  /// 组大拖拽距离
  final double? dampingDistance;

  /// 页面可动元素的动画时长
  final Duration duration;

  /// 拖拽结束回调
  final VertigoDragEndCallback? onDragEndCallback;

  /// 是否启用
  final bool enabled;

  @override
  _VertigoPreviewState createState() => _VertigoPreviewState();
}

class _VertigoPreviewState extends State<VertigoPreview> with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  late Offset _startPosition;
  late Offset _dragDistance;

  @override
  void initState() {
    widget.controller?._state = this;
    _animationController = AnimationController(
      duration: _kDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.fastOutSlowIn,
    );
    _reset();
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _startPosition = details.localPosition;
    DragStartNotification(details: details).dispatch(context);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    _dragDistance = details.localPosition - _startPosition;

    final size = MediaQuery.of(context).size;
    final dampingDistance = widget.dampingDistance ?? (size.height * 2);
    final damping = _dragDistance.dy.abs() / dampingDistance;
    _animationController.value = 1.0 - damping.clamp(0.0, 1.0);
    setState(() {});
    DragUpdateNotification(
      details: details,
      startPosition: _startPosition,
      dragDistance: _dragDistance,
      offset: _animation.value,
    ).dispatch(context);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity;
    final onDragEndCallback = widget.onDragEndCallback;
    if (onDragEndCallback?.call(_dragDistance, velocity) == true) {
      _dismiss();
    } else {
      _reset();
    }
    DragEndNotification(details: details).dispatch(context);
  }

  void _reset() {
    _startPosition = Offset.zero;
    _dragDistance = Offset.zero;
    _animationController.forward();
    setState(() {});
  }

  void _dismiss() {
    _startPosition = Offset.zero;
    _dragDistance = Offset.zero;
    _animationController.reverse();
    setState(() {});
  }

  bool _switchBar(bool show) {
    if (MatrixUtils.getAsTranslation(_transform) != Offset.zero) {
      return false;
    }
    if (show) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    return true;
  }

  Widget? _buildNavigationBar() {
    if (widget.navigationBarBuilder == null) {
      return null;
    }
    return Builder(
      builder: widget.navigationBarBuilder!,
    );
  }

  Widget? _buildBottomBar() {
    Widget? bottomBar;
    if (widget.bottomBarBuilder != null) {
      bottomBar = Builder(
        builder: widget.bottomBarBuilder!,
      );
    }
    if (bottomBar != null) {
      bottomBar = SingleChildScrollView(
        child: bottomBar,
      );
    }
    return bottomBar;
  }

  Matrix4 get _transform {
    final height = MediaQuery.of(context).size.height;
    final scale = 1.0 - _dragDistance.dy.abs() / (height * 2);
    final translation = _dragDistance + _startPosition * (1 - scale);
    return Matrix4.translationValues(
      translation.dx,
      translation.dy,
      0,
    )..scale(scale, scale, 1);
  }

  @override
  Widget build(BuildContext context) {
    var duration = Duration.zero;
    if (MatrixUtils.getAsTranslation(_transform) == Offset.zero) {
      duration = widget.duration;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: widget.enabled ? _onVerticalDragStart : null,
      onVerticalDragUpdate: widget.enabled ? _onVerticalDragUpdate : null,
      onVerticalDragEnd: widget.enabled ? _onVerticalDragEnd : null,
      onLongPress: widget.onLongPressed,
      onDoubleTap: widget.onDoublePressed,
      onTap: widget.onPressed,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          AnimatedContainer(
            transform: _transform,
            duration: duration,
            curve: Curves.fastOutSlowIn,
            child: widget.child,
          ),
          Positioned.fill(
            top: null,
            child: SizeTransition(
              sizeFactor: _animation,
              axis: Axis.vertical,
              axisAlignment: -1,
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
                    minWidth: double.infinity,
                    maxWidth: double.infinity,
                    minHeight: 0,
                    maxHeight: MediaQuery.of(context).size.height / 4,
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
          ),
          Positioned.fill(
            bottom: null,
            child: SizeTransition(
              sizeFactor: _animation,
              axis: Axis.vertical,
              axisAlignment: 1,
              child: Container(
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
          ),
        ],
      ),
    );
  }
}
