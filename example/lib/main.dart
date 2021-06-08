import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:preimage/preimage.dart';

const String _testAvatarUrl = 'https://p5.gexing.com/GSF/shaitu/20181118/1427/5bf1064593f44.jpg';

void main() {
  runApp(MyApp());
}

/// app
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      home: _PluginExamplePage(),
    );
  }
}

class _PluginExamplePage extends StatelessWidget {
  Widget _buildBottomBar(BuildContext context, int index) {
    if (index % 4 == 1) {
      return const SizedBox.shrink();
    }
    return Container(
      height: index.isEven ? null : MediaQuery.of(context).size.height / 2,
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

  @override
  Widget build(BuildContext context) {
    final images = List.generate(10, (index) {
      return ImageOptions(
        url: _testAvatarUrl,
        tag: [_testAvatarUrl, index].join('_'),
      );
    });
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Plugin example app'),
      ),
      child: Center(
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            final image = images[index];
            return CupertinoButton(
              borderRadius: BorderRadius.zero,
              padding: EdgeInsets.zero,
              minSize: 0,
              onPressed: () {
                Preimage.preview<void>(
                  context,
                  images: images,
                  initialIndex: index,
                  bottomBarBuilder: _buildBottomBar,
                );
              },
              child: PreimageHero(
                tag: image.tag,
                child: CachedNetworkImage(
                  imageUrl: image.url,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
