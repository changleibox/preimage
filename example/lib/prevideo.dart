/*
 * Copyright (c) 2021 CHANGLEI. All rights reserved.
 */

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:preimage_example/scheduler.dart';
import 'package:video_player/video_player.dart';

const _offsetDuration = Duration(
  seconds: 3,
);
const _animationDuration = Duration(
  milliseconds: 300,
);
const _fadeDuration = Duration(
  milliseconds: 150,
);

/// Created by changlei on 2021/7/22.
///
/// 预览视频
class Prevideo extends StatefulWidget {
  /// 构造函数
  const Prevideo({
    Key? key,
    required this.controller,
    this.fit = BoxFit.contain,
    bool usedOrigin = false,
  })  : assert(controller != null),
        dataSource = null,
        dataSourceType = null,
        formatHint = null,
        httpHeaders = const {},
        package = null,
        closedCaptionFile = null,
        videoPlayerOptions = null,
        _usedOrigin = usedOrigin,
        super(key: key);

  /// Constructs a [VideoPlayerController] playing a video from an asset.
  ///
  /// The name of the asset is given by the [dataSource] argument and must not be
  /// null. The [package] argument must be non-null when the asset comes from a
  /// package and null otherwise.
  const Prevideo.asset({
    Key? key,
    required this.dataSource,
    this.package,
    this.closedCaptionFile,
    this.videoPlayerOptions,
    this.fit = BoxFit.contain,
  })  : dataSourceType = DataSourceType.asset,
        formatHint = null,
        httpHeaders = const {},
        controller = null,
        _usedOrigin = false,
        super(key: key);

  /// Constructs a [VideoPlayerController] playing a video from obtained from
  /// the network.
  ///
  /// The URI for the video is given by the [dataSource] argument and must not be
  /// null.
  /// **Android only**: The [formatHint] option allows the caller to override
  /// the video format detection code.
  /// [httpHeaders] option allows to specify HTTP headers
  /// for the request to the [dataSource].
  const Prevideo.network({
    Key? key,
    required this.dataSource,
    this.formatHint,
    this.closedCaptionFile,
    this.videoPlayerOptions,
    this.httpHeaders = const {},
    this.fit = BoxFit.contain,
  })  : dataSourceType = DataSourceType.network,
        package = null,
        controller = null,
        _usedOrigin = false,
        super(key: key);

  /// Constructs a [VideoPlayerController] playing a video from a file.
  ///
  /// This will load the file from the file-URI given by:
  /// `'file://${file.path}'`.
  Prevideo.file({
    Key? key,
    required File file,
    this.closedCaptionFile,
    this.videoPlayerOptions,
    this.fit = BoxFit.contain,
  })  : dataSource = 'file://${file.path}',
        dataSourceType = DataSourceType.file,
        package = null,
        formatHint = null,
        httpHeaders = const {},
        controller = null,
        _usedOrigin = false,
        super(key: key);

  /// controller
  final VideoPlayerController? controller;

  /// The URI to the video file. This will be in different formats depending on
  /// the [DataSourceType] of the original video.
  final String? dataSource;

  /// HTTP headers used for the request to the [dataSource].
  /// Only for [VideoPlayerController.network].
  /// Always empty for other video types.
  final Map<String, String> httpHeaders;

  /// **Android only**. Will override the platform's generic file format
  /// detection with whatever is set here.
  final VideoFormat? formatHint;

  /// Describes the type of data source this [VideoPlayerController]
  /// is constructed with.
  final DataSourceType? dataSourceType;

  /// Provide additional configuration options (optional). Like setting the audio mode to mix
  final VideoPlayerOptions? videoPlayerOptions;

  /// Only set for [asset] videos. The package that the asset was loaded from.
  final String? package;

  /// Optional field to specify a file containing the closed
  /// captioning.
  ///
  /// This future will be awaited and the file will be loaded when
  /// [initialize()] is called.
  final Future<ClosedCaptionFile>? closedCaptionFile;

  /// 是否使用原始controller，而不是重新创建一个
  final bool _usedOrigin;

  /// 平铺方式
  final BoxFit fit;

  @override
  _PrevideoState createState() => _PrevideoState();
}

class _PrevideoState extends State<Prevideo> with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  Future<void>? _initializeFuture;
  bool _initialized = false;
  Scheduler? _scheduler;

  VideoPlayerValue? _originValue;

  VideoPlayerController? get _origin => widget.controller;

  VideoPlayerController get _effectiveController {
    return _initialized || _origin == null ? _controller : _origin!;
  }

  void _onInitialized() {
    if (!mounted || !_controller.value.isBuffered) {
      return;
    }
    _controller.removeListener(_onInitialized);
    if (_origin != null) {
      _controller.value = _origin!.value;
    }
    _controller.play();
    _scheduler = Scheduler.postFrame(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _initialized = true;
      });
    });
    _origin?.pause();
    _origin?.seekTo(Duration.zero);
  }

  @override
  void initState() {
    try {
      _originValue = _origin?.value.copyWith();
      _origin?.seekTo(Duration.zero);
      _origin?.setLooping(true);
      _origin?.pause();
    } catch (e) {
      // nothing
    } finally {
      _controller = _generatedController;
      if (!_controller.value.isInitialized) {
        _controller.addListener(_onInitialized);
        _initializeFuture = _controller.initialize();
      }
      _controller.seekTo(Duration.zero);
      _controller.setLooping(true);
      _controller.pause();
    }
    super.initState();
  }

  @override
  void dispose() {
    try {
      if (_originValue != null) {
        _origin?.value = _originValue!;
      }
    } catch (e) {
      // nothing
    } finally {
      _controller.seekTo(Duration.zero);
      _controller.setLooping(false);
      _controller.pause();
      _controller.dispose();
    }
    _scheduler?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snapshot) {
        return FittedVideoPlayer(
          controller: _effectiveController,
          isDone: widget.controller != null || snapshot.connectionState == ConnectionState.done,
          fit: widget.fit,
        );
      },
    );
  }

  VideoPlayerController get _generatedController {
    if (widget._usedOrigin) {
      return _origin!;
    }
    var controller = _wrapController(widget.controller);
    if (controller != null) {
      return controller;
    }
    switch (widget.dataSourceType!) {
      case DataSourceType.asset:
        controller = VideoPlayerController.asset(
          widget.dataSource!,
          closedCaptionFile: widget.closedCaptionFile,
          videoPlayerOptions: widget.videoPlayerOptions,
          package: widget.package,
        );
        break;
      case DataSourceType.network:
        controller = VideoPlayerController.network(
          widget.dataSource!,
          closedCaptionFile: widget.closedCaptionFile,
          videoPlayerOptions: widget.videoPlayerOptions,
          httpHeaders: widget.httpHeaders,
          formatHint: widget.formatHint,
        );
        break;
      case DataSourceType.file:
        controller = VideoPlayerController.file(
          File.fromUri(Uri.parse(widget.dataSource!)),
          closedCaptionFile: widget.closedCaptionFile,
          videoPlayerOptions: widget.videoPlayerOptions,
        );
        break;
    }
    return controller;
  }
}

/// 视频播放器
class FittedVideoPlayer extends StatelessWidget {
  /// 构造函数
  const FittedVideoPlayer({
    Key? key,
    required this.controller,
    required this.isDone,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  /// controller
  final VideoPlayerController controller;

  /// 是否加载完成
  final bool isDone;

  /// 视频填充方式
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (!isDone) {
      child = const _Loading();
    } else {
      child = Stack(
        children: [
          Positioned.fill(
            child: FittedBox(
              fit: fit,
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              child: SizedBox.fromSize(
                size: controller.value.size,
                child: VideoPlayer(controller),
              ),
            ),
          ),
          Positioned(
            child: VideoBuffered(
              controller: controller,
            ),
          ),
        ],
      );
    }
    return AnimatedSwitcher(
      duration: _animationDuration,
      child: child,
    );
  }
}

/// 视频缓存控件
class VideoBuffered extends StatefulWidget {
  /// 构造函数
  const VideoBuffered({
    Key? key,
    required this.controller,
  }) : super(key: key);

  /// videoController
  final VideoPlayerController controller;

  @override
  _VideoBufferedState createState() => _VideoBufferedState();
}

class _VideoBufferedState extends State<VideoBuffered> {
  late VideoPlayerController _controller;

  Scheduler? _scheduler;

  @override
  void initState() {
    _initializeController();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant VideoBuffered oldWidget) {
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      _initializeController();
    }
    super.didUpdateWidget(oldWidget);
  }

  void _initializeController() {
    _controller = widget.controller;
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _scheduler?.cancel();
    super.dispose();
  }

  void _onChanged() {
    _scheduler?.cancel();
    _scheduler = Scheduler.postFrame(() {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller.value;
    return _Loading(
      isLoading: value.isBuffering && !value.isBuffered,
    );
  }
}

/// 加载框
class _Loading extends StatelessWidget {
  const _Loading({
    Key? key,
    this.isLoading = true,
  }) : super(key: key);

  // 是否正在加载
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedOpacity(
        opacity: isLoading ? 1 : 0,
        duration: _fadeDuration,
        curve: Curves.fastOutSlowIn,
        child: AnimatedContainer(
          duration: _fadeDuration,
          width: isLoading ? 64 : 0,
          height: isLoading ? 64 : 0,
          curve: Curves.fastOutSlowIn,
          decoration: BoxDecoration(
            color: CupertinoDynamicColor.resolve(
              CupertinoColors.tertiarySystemBackground,
              context,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x20000000),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: const CupertinoActivityIndicator(),
        ),
      ),
    );
  }
}

/// 扩展
extension VideoPlayerValueBuffered on VideoPlayerValue {
  /// 是否已经缓冲完成
  bool get isBuffered {
    final position = this.position.inMilliseconds;
    final duration = this.duration.inMilliseconds;
    final buffering = _maxBuffering - _offsetDuration.inMilliseconds;
    return buffering > 0 && duration > 0 && (position >= duration || position < buffering);
  }

  /// 缓存的比例
  double get buffering {
    final duration = this.duration.inMilliseconds;
    return duration <= 0 ? 0 : _maxBuffering / duration;
  }

  /// 播放的比例
  double get positioning {
    final position = this.position.inMilliseconds;
    final duration = this.duration.inMilliseconds;
    if (duration <= 0) {
      return 0;
    }
    return position / duration;
  }

  int get _maxBuffering {
    var maxBuffering = 0;
    for (var range in buffered) {
      final end = range.end.inMilliseconds;
      if (end > maxBuffering) {
        maxBuffering = end;
      }
    }
    return maxBuffering;
  }
}

VideoPlayerController? _wrapController(VideoPlayerController? origin) {
  if (origin == null) {
    return null;
  }
  VideoPlayerController controller;
  switch (origin.dataSourceType) {
    case DataSourceType.asset:
      controller = VideoPlayerController.asset(
        origin.dataSource,
        closedCaptionFile: origin.closedCaptionFile,
        videoPlayerOptions: origin.videoPlayerOptions,
        package: origin.package,
      );
      break;
    case DataSourceType.network:
      controller = VideoPlayerController.network(
        origin.dataSource,
        closedCaptionFile: origin.closedCaptionFile,
        videoPlayerOptions: origin.videoPlayerOptions,
        httpHeaders: origin.httpHeaders,
        formatHint: origin.formatHint,
      );
      break;
    case DataSourceType.file:
      controller = VideoPlayerController.file(
        File.fromUri(Uri.parse(origin.dataSource)),
        closedCaptionFile: origin.closedCaptionFile,
        videoPlayerOptions: origin.videoPlayerOptions,
      );
      break;
  }
  return controller;
}

/// 计算BoxFit对应的size
Size applyBoxFitForSize(BoxFit fit, Size inputSize, Size outputSize) {
  if (inputSize.height <= 0.0 || inputSize.width <= 0.0 || outputSize.height <= 0.0 || outputSize.width <= 0.0) {
    return Size.zero;
  }

  Size destinationSize;
  switch (fit) {
    case BoxFit.contain:
      if (outputSize.width / outputSize.height > inputSize.width / inputSize.height) {
        destinationSize = Size(inputSize.width * outputSize.height / inputSize.height, outputSize.height);
      } else {
        destinationSize = Size(outputSize.width, inputSize.height * outputSize.width / inputSize.width);
      }
      break;
    case BoxFit.cover:
      if (outputSize.width / outputSize.height > inputSize.width / inputSize.height) {
        destinationSize = Size(outputSize.width, inputSize.height * outputSize.width / inputSize.width);
      } else {
        destinationSize = Size(inputSize.width * outputSize.height / inputSize.height, outputSize.height);
      }
      break;
    case BoxFit.fitWidth:
      destinationSize = Size(outputSize.width, inputSize.height * outputSize.width / inputSize.width);
      break;
    case BoxFit.fitHeight:
      destinationSize = Size(inputSize.width * outputSize.height / inputSize.height, outputSize.height);
      break;
    case BoxFit.none:
      destinationSize = Size(min(inputSize.width, outputSize.width), min(inputSize.height, outputSize.height));
      break;
    case BoxFit.scaleDown:
      destinationSize = inputSize;
      final aspectRatio = inputSize.width / inputSize.height;
      if (destinationSize.height > outputSize.height) {
        destinationSize = Size(outputSize.height * aspectRatio, outputSize.height);
      }
      if (destinationSize.width > outputSize.width) {
        destinationSize = Size(outputSize.width, outputSize.width / aspectRatio);
      }
      break;
    case BoxFit.fill:
      destinationSize = outputSize;
      break;
  }
  return destinationSize;
}
