import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../services/image_cache_service.dart';
import 'loading_widget.dart';


/// 优化的缓存图片组件
class CachedImageWidget extends StatefulWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final bool enableMemoryCache;
  final VoidCallback? onImageLoaded;
  final VoidCallback? onImageError;

  const CachedImageWidget({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.enableMemoryCache = true,
    this.onImageLoaded,
    this.onImageError,
  });

  @override
  State<CachedImageWidget> createState() => _CachedImageWidgetState();
}

class _CachedImageWidgetState extends State<CachedImageWidget>
    with AutomaticKeepAliveClientMixin {
  final ImageCacheService _cacheService = ImageCacheService();
  ui.Image? _image;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => widget.enableMemoryCache;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _loadImage();
    }
  }

  /// 加载图片
  Future<void> _loadImage() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // 检查文件是否存在
      final file = File(widget.imagePath);
      if (!await file.exists()) {
        throw Exception('图片文件不存在: ${widget.imagePath}');
      }

      // 从缓存服务加载图片
      final image = await _cacheService.loadAndCacheImage(widget.imagePath);

      if (!mounted) return;

      if (image != null) {
        setState(() {
          _image = image;
          _isLoading = false;
          _hasError = false;
        });
        widget.onImageLoaded?.call();
      } else {
        throw Exception('无法加载图片');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      widget.onImageError?.call();
    }
  }

  /// 重试加载图片
  void _retryLoad() {
    _loadImage();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    Widget child;

    if (_isLoading) {
      child = widget.placeholder ??
          const LoadingWidget(
            size: 40,
            message: '加载中...',
          );
    } else if (_hasError) {
      child = widget.errorWidget ??
          Container(
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.grey[600], size: 32),
                const SizedBox(height: 8),
                Text('图片加载失败', style: TextStyle(color: Colors.grey[600])),
                if (_errorMessage != null)
                  Text(_errorMessage!, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _retryLoad,
                  child: const Text('重试'),
                ),
              ],
            ),
          );
    } else if (_image != null) {
      child = CustomPaint(
        painter: _ImagePainter(_image!, widget.fit),
        size: Size(
          widget.width ?? double.infinity,
          widget.height ?? double.infinity,
        ),
      );
    } else {
      child = widget.errorWidget ??
          Container(
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported, color: Colors.grey[600], size: 32),
                const SizedBox(height: 8),
                Text('图片不可用', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
    }

    // 应用边框圆角
    if (widget.borderRadius != null) {
      child = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: child,
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: child,
    );
  }

  @override
  void dispose() {
    // 图片会由缓存服务管理，这里不需要手动释放
    super.dispose();
  }
}

/// 自定义图片绘制器
class _ImagePainter extends CustomPainter {
  final ui.Image image;
  final BoxFit fit;

  _ImagePainter(this.image, this.fit);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final FittedSizes fittedSizes = applyBoxFit(fit, imageSize, size);
    final Size sourceSize = fittedSizes.source;
    final Size destinationSize = fittedSizes.destination;

    final double scaleX = sourceSize.width / imageSize.width;
    final double scaleY = sourceSize.height / imageSize.height;

    final Rect sourceRect = Rect.fromLTWH(
      (imageSize.width - sourceSize.width) / 2,
      (imageSize.height - sourceSize.height) / 2,
      sourceSize.width,
      sourceSize.height,
    );

    final Rect destinationRect = Rect.fromLTWH(
      (size.width - destinationSize.width) / 2,
      (size.height - destinationSize.height) / 2,
      destinationSize.width,
      destinationSize.height,
    );

    canvas.drawImageRect(image, sourceRect, destinationRect, Paint());
  }

  @override
  bool shouldRepaint(_ImagePainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.fit != fit;
  }
}

/// 图片预加载器
class ImagePreloader {
  static final ImageCacheService _cacheService = ImageCacheService();

  /// 预加载图片列表
  static Future<void> preloadImages(List<String> imagePaths) async {
    await _cacheService.preloadImages(imagePaths);
  }

  /// 预加载单个图片
  static Future<void> preloadImage(String imagePath) async {
    await _cacheService.loadAndCacheImage(imagePath);
  }
}
