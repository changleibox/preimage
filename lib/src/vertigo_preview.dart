/*
 * Copyright (c) 2021 CHANGLEI. All rights reserved.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

/// Created by box on 2020/4/21.
///
/// 图片预览控件
const Duration _kDuration = Duration(
  milliseconds: 300,
);
const _dragDamping = 200.0;
const _scaleDamping = 400.0;
const _stoppedZeroAnimation = AlwaysStoppedAnimation<double>(0.0);

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
    description.add('offset: $offset');
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
typedef VertigoDragStartCallback = void Function(
  DragStartDetails details,
);

/// 拖拽结束回调
typedef VertigoDragEndCallback = bool Function(
  Offset dragDistance,
  double? velocity,
);

/// controller
class VertigoPreviewController extends ChangeNotifier {
  _VertigoPreviewState? _state;
  Animation<double>? _animation;
  Offset? _startPosition;
  Offset? _dragDistance;

  /// 拖动offset
  Animation<double> get animation {
    _checkStateNotNull();
    return _animation!;
  }

  /// 拖动的其实位置
  Offset get startPosition {
    _checkStateNotNull();
    return _startPosition!;
  }

  /// 拖动的距离
  Offset get dragDistance {
    _checkStateNotNull();
    return _dragDistance!;
  }

  void _notify(Animation<double> animation, Offset startPosition, Offset dragDistance) {
    if (_animation == animation && _startPosition == startPosition && _dragDistance == dragDistance) {
      return;
    }
    _animation = animation;
    _startPosition = startPosition;
    _dragDistance = dragDistance;
    notifyListeners();
  }

  void _checkStateNotNull() {
    assert(
      _state != null,
      '未绑定到`VertigoPreview`，或已解除绑定',
    );
  }

  /// 切换显示状态，[value]为true，则显示，false则不显示
  void display(bool value) {
    _checkStateNotNull();
    _state!._display(value);
  }

  @override
  void dispose() {
    _state = null;
    _animation = null;
    _startPosition = null;
    _dragDistance = null;
    super.dispose();
  }
}

/// 图片预览
class VertigoPreview extends StatefulWidget {
  /// 图片预览
  const VertigoPreview({
    Key? key,
    required this.child,
    this.controller,
    this.topBarBuilder,
    this.bottomBarBuilder,
    this.onPressed,
    this.onDoublePressed,
    this.onLongPressed,
    double? dragDamping,
    double? scaleDamping,
    this.duration = _kDuration,
    this.onDragStartCallback,
    this.onDragEndCallback,
    this.enabled = true,
    this.behavior,
    this.dragStartBehavior = DragStartBehavior.start,
  })  : assert(dragDamping == null || dragDamping > 0),
        assert(scaleDamping == null || scaleDamping > 0),
        dragDamping = dragDamping ?? _dragDamping,
        scaleDamping = scaleDamping ?? _scaleDamping,
        super(key: key);

  /// child
  final Widget child;

  /// controller
  final VertigoPreviewController? controller;

  /// 构建topBar
  final WidgetBuilder? topBarBuilder;

  /// 构建bottomBar
  final WidgetBuilder? bottomBarBuilder;

  /// 点击
  final VoidCallback? onPressed;

  /// 长按
  final VoidCallback? onDoublePressed;

  /// 双击
  final VoidCallback? onLongPressed;

  /// 拖拽阻尼
  final double dragDamping;

  /// 缩放阻尼
  final double scaleDamping;

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

  /// 获取[VertigoPreview]拖动参数
  static _VertigoPreviewScope? of(BuildContext context) {
    return _VertigoPreviewScope.of(context);
  }

  @override
  _VertigoPreviewState createState() => _VertigoPreviewState();
}

class _VertigoPreviewState extends State<VertigoPreview> with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  late Offset _startPosition;
  late Offset _dragDistance;

  Animation<double>? _routeAnimation;
  bool _dragTracking = true;

  @override
  void initState() {
    widget.controller?._state = this;
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.fastOutSlowIn,
    );
    _display(true);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _routeAnimation?.removeStatusListener(_onRouteAnimationStatusChanged);
    _routeAnimation = ModalRoute.of(context)?.animation;
    _routeAnimation?.addStatusListener(_onRouteAnimationStatusChanged);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _routeAnimation?.removeStatusListener(_onRouteAnimationStatusChanged);
    super.dispose();
  }

  void _onRouteAnimationStatusChanged(AnimationStatus status) {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Animation<double> get _actualAnimation {
    if (_animationController.isAnimating) {
      return _animation;
    }
    final status = _routeAnimation?.status;
    if (status == AnimationStatus.forward || status == AnimationStatus.reverse) {
      return _routeAnimation!.drive(Tween<double>(
        begin: 0,
        end: _animation.value,
      ));
    } else {
      return _animation;
    }
  }

  void _onVerticalDragStart(DragStartDetails details) {
    widget.onDragStartCallback?.call(details);
    _startPosition = details.localPosition;
    _notify();
    DragStartNotification(
      details: details,
    ).dispatch(context);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    _dragDistance = details.localPosition - _startPosition;

    final damping = _dragDistance.dy.abs() / widget.dragDamping;
    _animationController.value = 1.0 - damping.clamp(0.0, 1.0);
    _notify();
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
    final display = onDragEndCallback?.call(_dragDistance, velocity) != true;
    _display(display & _dragTracking);
    DragEndNotification(
      details: details,
    ).dispatch(context);
  }

  void _display(bool value) {
    _startPosition = Offset.zero;
    _dragDistance = Offset.zero;
    if (value) {
      _dragTracking = value;
      _animationController.forward();
    } else {
      _animationController.reverse().whenCompleteOrCancel(() {
        if (!mounted) {
          return;
        }
        setState(() {
          _dragTracking = value;
        });
      });
    }
    _notify();
  }

  void _notify() {
    if (!mounted) {
      return;
    }
    setState(() {});
    widget.controller?._notify(
      _actualAnimation,
      _startPosition,
      _dragDistance,
    );
  }

  Widget? _buildTopBar() {
    if (widget.topBarBuilder == null) {
      return null;
    }
    return Builder(
      builder: widget.topBarBuilder!,
    );
  }

  Widget? _buildBottomBar() {
    if (widget.bottomBarBuilder == null) {
      return null;
    }
    return Builder(
      builder: widget.bottomBarBuilder!,
    );
  }

  Matrix4 get _transform {
    final damping = _dragDistance.dy.abs() / widget.scaleDamping;
    final scale = 1.0 - damping.clamp(0, 1);
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
    final overlayBarAnimation = _dragTracking ? _actualAnimation : _stoppedZeroAnimation;
    return GestureDetector(
      behavior: widget.behavior,
      dragStartBehavior: widget.dragStartBehavior,
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
            child: _VertigoPreviewScope(
              animation: _actualAnimation,
              startPosition: _startPosition,
              dragDistance: _dragDistance,
              child: widget.child,
            ),
          ),
          Positioned.fill(
            top: null,
            child: _AnimatedOverlayBar(
              animation: overlayBarAnimation,
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              child: _buildBottomBar(),
            ),
          ),
          Positioned.fill(
            bottom: null,
            child: _AnimatedOverlayBar(
              animation: overlayBarAnimation,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              child: _buildTopBar(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedOverlayBar extends StatelessWidget {
  const _AnimatedOverlayBar({
    Key? key,
    required this.animation,
    required this.begin,
    required this.end,
    required this.child,
  }) : super(key: key);

  final Animation animation;
  final Alignment begin;
  final Alignment end;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    const color = CupertinoColors.black;
    return _AnimatedOverlay(
      listenable: animation,
      axisAlignment: -begin.y,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.6),
              color.withOpacity(0.0),
            ],
            begin: begin,
            end: end,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _AnimatedOverlay extends AnimatedWidget {
  const _AnimatedOverlay({
    Key? key,
    required Listenable listenable,
    required this.child,
    this.axisAlignment = 0,
  }) : super(
          key: key,
          listenable: listenable,
        );

  final Widget child;
  final double axisAlignment;

  /// The animation that controls the scale of the child.
  ///
  /// If the current value of the scale animation is v, the child will be
  /// painted v times its normal size.
  Animation<double> get animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      axisAlignment: axisAlignment,
      axis: Axis.vertical,
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}

class _VertigoPreviewScope extends InheritedWidget {
  const _VertigoPreviewScope({
    Key? key,
    required Widget child,
    required this.animation,
    required this.startPosition,
    required this.dragDistance,
  }) : super(key: key, child: child);

  /// 拖动offset
  final Animation<double> animation;

  /// 拖动的其实位置
  final Offset startPosition;

  /// 拖动的距离
  final Offset dragDistance;

  static _VertigoPreviewScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_VertigoPreviewScope>();
  }

  @override
  bool updateShouldNotify(_VertigoPreviewScope old) {
    return animation != old.animation || startPosition != old.startPosition || dragDistance != old.dragDistance;
  }
}
