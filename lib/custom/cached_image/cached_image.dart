library cached_network_svg_image;

import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomNetworkCachedImage extends StatefulWidget {
  CustomNetworkCachedImage(
    String url, {
    Key? key,
    String? cacheKey,
    Widget? placeholder,
    Widget? errorWidget,
    double? width,
    double? height,
    Map<String, String>? headers,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    bool matchTextDirection = false,
    bool allowDrawingOutsideViewBox = false,
    @deprecated Color? color,
    @deprecated BlendMode colorBlendMode = BlendMode.srcIn,
    String? semanticsLabel,
    bool excludeFromSemantics = false,
    Duration fadeDuration = const Duration(milliseconds: 300),
    ColorFilter? colorFilter,
    WidgetBuilder? placeholderBuilder,
    BaseCacheManager? cacheManager,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  })  : _url = url,
        _cacheKey = cacheKey,
        _placeholder = placeholder,
        _errorWidget = errorWidget,
        _width = width,
        _height = height,
        _headers = headers,
        _fit = fit,
        _alignment = alignment,
        _matchTextDirection = matchTextDirection,
        _color = color,
        _colorBlendMode = colorBlendMode,
        _semanticsLabel = semanticsLabel,
        _excludeFromSemantics = excludeFromSemantics,
        _fadeDuration = fadeDuration,
        _errorBuilder = errorBuilder,
        _cacheManager = cacheManager ?? DefaultCacheManager(),
        super(key: key ?? ValueKey(url));

  final String _url;
  final String? _cacheKey;
  final Widget? _placeholder;
  final Widget? _errorWidget;
  final double? _width;
  final double? _height;
  final Map<String, String>? _headers;
  final BoxFit _fit;
  final AlignmentGeometry _alignment;
  final bool _matchTextDirection;
  final Color? _color;
  final BlendMode _colorBlendMode;
  final String? _semanticsLabel;
  final bool _excludeFromSemantics;
  final Duration _fadeDuration;
  final BaseCacheManager _cacheManager;
  final Widget Function(BuildContext, Object, StackTrace?)? _errorBuilder;

  @override
  State<CustomNetworkCachedImage> createState() =>
      _CustomNetworkCachedImageState();

  static Future<void> preCache(
    String imageUrl, {
    String? cacheKey,
    BaseCacheManager? cacheManager,
  }) {
    final key = cacheKey ?? _generateKeyFromUrl(imageUrl);
    cacheManager ??= DefaultCacheManager();
    return cacheManager.downloadFile(key);
  }

  static Future<void> clearCacheForUrl(
    String imageUrl, {
    String? cacheKey,
    BaseCacheManager? cacheManager,
  }) {
    final key = cacheKey ?? _generateKeyFromUrl(imageUrl);
    cacheManager ??= DefaultCacheManager();
    return cacheManager.removeFile(key);
  }

  static Future<void> clearCache({BaseCacheManager? cacheManager}) {
    cacheManager ??= DefaultCacheManager();
    return cacheManager.emptyCache();
  }

  static String _generateKeyFromUrl(String url) => url.split('?').first;
}

class _CustomNetworkCachedImageState extends State<CustomNetworkCachedImage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isError = false;
  File? _imageFile;
  late String _cacheKey;

  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _cacheKey = widget._cacheKey ??
        CustomNetworkCachedImage._generateKeyFromUrl(widget._url);
    _controller = AnimationController(
      vsync: this,
      duration: widget._fadeDuration,
    );
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      _setToLoadingAfter15MsIfNeeded();

      var file =
          (await widget._cacheManager.getFileFromMemory(_cacheKey))?.file;

      file ??= await widget._cacheManager.getSingleFile(
        widget._url,
        key: _cacheKey,
        headers: widget._headers ?? {},
      );

      _imageFile = file;
      _isLoading = false;

      _setState();

      _controller.forward();
    } catch (e) {
      log('CustomNetworkCachedImage: $e');

      _isError = true;
      _isLoading = false;

      _setState();
    }
  }

  void _setToLoadingAfter15MsIfNeeded() => Future.delayed(
        const Duration(milliseconds: 15),
        () {
          if (!_isLoading && _imageFile == null && !_isError) {
            _isLoading = true;
            _setState();
          }
        },
      );

  void _setState() => mounted ? setState(() {}) : null;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget._width,
      height: widget._height,
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    if (_isLoading) return _buildPlaceholderWidget();

    if (_isError) return _buildErrorWidget();

    return FadeTransition(
      opacity: _animation,
      child: _buildNetworkImage(),
    );
  }

  Widget _buildPlaceholderWidget() =>
      Center(child: widget._placeholder ?? const SizedBox());

  Widget _buildErrorWidget() =>
      Center(child: widget._errorWidget ?? const SizedBox());

  Widget _buildNetworkImage() {
    if (_imageFile == null) return const SizedBox();

    return Image.file(_imageFile!,
        fit: widget._fit,
        width: widget._width,
        height: widget._height,
        alignment: widget._alignment,
        matchTextDirection: widget._matchTextDirection,
        color: widget._color,
        colorBlendMode: widget._colorBlendMode,
        semanticLabel: widget._semanticsLabel,
        excludeFromSemantics: widget._excludeFromSemantics,
        errorBuilder: widget._errorBuilder);
  }
}
