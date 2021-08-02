import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:preimage/preimage.dart';

const String _testAvatarUrl = 'http://img.netbian.com/file/2020/1126/d80fba29d14a4dc832b73db9686d1fdd.jpg';

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
  final _images = List.generate(10, _builderImage);

  static ImageOptions _builderImage(int index) {
    return ImageOptions(
      url: _testAvatarUrl,
      tag: [_testAvatarUrl, index].join('_'),
    );
  }

  Widget _buildBottomBar(BuildContext context, int index, int count) {
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
          itemCount: _images.length,
          itemBuilder: (context, index) {
            final image = _images[index];
            return KeyedSubtree(
              key: ObjectKey(image.url),
              child: CupertinoButton(
                borderRadius: BorderRadius.zero,
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: () {
                  Preimage.preview<void>(
                    context,
                    images: _images,
                    initialIndex: index,
                    bottomBarBuilder: _buildBottomBar,
                    onOverEdge: (value) {
                      print(value);
                    },
                  );
                },
                child: PreimageHero(
                  tag: [image.url, index].join('_'),
                  child: CachedNetworkImage(
                    imageUrl: image.url ?? '',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
