import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:preimage/preimage.dart';
import 'package:preimage_example/prevideo.dart';
import 'package:preimage_example/scheduler.dart';
import 'package:video_player/video_player.dart';

const String _testAvatarUrl = 'http://img.netbian.com/file/2020/1126/d80fba29d14a4dc832b73db9686d1fdd.jpg';

/// 测试视频（人类清除计划）
const String _testVideoUrl = 'https://vod4.buycar5.cn/20210718/lx14hBDC/index.m3u8';

/// 返回[FutureOr]
typedef FutureOrVoidCallback = FutureOr<void> Function();

void main() {
  runApp(PluginExampleApp());
}

/// app
class PluginExampleApp extends StatefulWidget {
  @override
  _PluginExampleAppState createState() => _PluginExampleAppState();
}

class _PluginExampleAppState extends State<PluginExampleApp> {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      home: PluginExamplePage(),
    );
  }
}

/// 示例代码
class PluginExamplePage extends StatefulWidget {
  static Object _buildImage(int index) {
    if (index.isOdd) {
      return VideoPlayerController.network(_testVideoUrl);
    } else {
      return _testAvatarUrl;
    }
  }

  @override
  _PluginExamplePageState createState() => _PluginExamplePageState();
}

class _PluginExamplePageState extends State<PluginExamplePage> {
  final _images = List.generate(10, PluginExamplePage._buildImage);

  @override
  void dispose() {
    _images.whereType<VideoPlayerController>().forEach((element) => element.dispose());
    super.dispose();
  }

  Future<void> _onPreviewPressed(int initialIndex) async {
    await Preimage.preview<void>(
      context,
      images: List.generate(_images.length, _buildImageOptions),
      initialIndex: initialIndex,
      bottomBarBuilder: (context, index, count) {
        return BottomBar(
          index: index,
          count: count,
        );
      },
      onOverEdge: (value) {
        print(value);
      },
    );
  }

  ImageOptions _buildImageOptions(int index) {
    final image = _images[index];
    String url;
    WidgetBuilder? builder;
    final isVideo = image is VideoPlayerController;
    if (isVideo) {
      final controller = image as VideoPlayerController;
      url = controller.dataSource;
      builder = (context) {
        return Prevideo(
          controller: controller,
          fit: BoxFit.contain,
          usedOrigin: false,
        );
      };
    } else {
      url = image.toString();
    }
    return ImageOptions(
      url: url,
      tag: [url, index].join('_'),
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Plugin example app'),
      ),
      child: Builder(
        builder: (context) {
          final padding = MediaQuery.of(context).padding;
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            addAutomaticKeepAlives: true,
            addRepaintBoundaries: true,
            padding: const EdgeInsets.all(15) + padding,
            itemCount: _images.length,
            itemBuilder: (context, index) {
              return CupertinoButton(
                onPressed: () => _onPreviewPressed(index),
                padding: EdgeInsets.zero,
                minSize: 0,
                child: _Avatar(
                  image: _images[index],
                  index: index,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    Key? key,
    required this.image,
    required this.index,
  }) : super(key: key);

  final Object image;
  final int index;

  @override
  Widget build(BuildContext context) {
    String url;
    Widget child;
    if (image is VideoPlayerController) {
      final controller = image as VideoPlayerController;
      url = controller.dataSource;
      child = VideoPlayerItem(
        controller: controller,
        fit: BoxFit.cover,
      );
    } else {
      url = image.toString();
      child = CachedNetworkImage(
        imageUrl: image.toString(),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }
    return PreimageHero(
      tag: [url, index].join('_'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: CupertinoColors.separator,
            width: 0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

/// 底部操作蓝
class BottomBar extends StatelessWidget {
  /// 构造函数
  const BottomBar({
    Key? key,
    required this.index,
    required this.count,
  }) : super(key: key);

  /// 当前索引
  final int index;

  /// 总数量
  final int count;

  @override
  Widget build(BuildContext context) {
    if (index % 4 == 1) {
      return const SizedBox.shrink();
    }
    final size = MediaQuery.of(context).size;
    return Container(
      height: index.isEven ? null : size.height / 2,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '测试标题',
              style: TextStyle(
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.label,
                  context,
                ),
              ),
            ),
            Text(
              '测试内容',
              style: TextStyle(
                fontSize: 15,
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.secondaryLabel,
                  context,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 预览item
class VideoPlayerItem extends StatefulWidget {
  /// 构造函数
  const VideoPlayerItem({
    Key? key,
    required this.controller,
    this.fit = BoxFit.contain,
    this.isAutoPlay = false,
  }) : super(key: key);

  /// controller
  final VideoPlayerController controller;

  /// 填充方式
  final BoxFit fit;

  /// 是否自动播放
  final bool isAutoPlay;

  @override
  _VideoPlayerItemState createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController _controller;

  Future<void>? _initializeFuture;
  Scheduler? _scheduler;

  @override
  void initState() {
    _initializeController();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant VideoPlayerItem oldWidget) {
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      _initializeController();
    }
    super.didUpdateWidget(oldWidget);
  }

  void _initializeController() {
    _controller = widget.controller;
    _controller.addListener(_onChanged);
    if (!_controller.value.isInitialized) {
      _initializeFuture = _controller.initialize();
    }
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
    return FutureBuilder(
      future: _initializeFuture,
      builder: (context, snapshot) {
        Widget child;
        if (snapshot.connectionState == ConnectionState.waiting) {
          child = const Center(
            child: CupertinoActivityIndicator(),
          );
        } else {
          child = Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: FittedBox(
                  fit: widget.fit,
                  alignment: Alignment.center,
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox.fromSize(
                    size: _controller.value.size,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),
              if (!_controller.value.isPlaying)
                const Positioned(
                  child: Icon(
                    CupertinoIcons.play_circle_fill,
                    color: Colors.black26,
                    size: 56,
                  ),
                ),
            ],
          );
        }
        return AnimatedSwitcher(
          duration: const Duration(
            milliseconds: 300,
          ),
          child: child,
        );
      },
    );
  }
}
