import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class MizanLogo extends StatefulWidget {
  final double width;
  final double? height;
  final bool useDarkVariant;
  final bool showText;
  final bool animated;
  final bool useIconOnly;
  final String? heroTag;

  const MizanLogo({
    super.key,
    double? size,
    double? width,
    this.height,
    this.useDarkVariant = true,
    this.showText = true,
    this.animated = true,
    this.useIconOnly = false,
    this.heroTag,
  }) : width = size ?? width ?? 200;

  @override
  State<MizanLogo> createState() => _MizanLogoState();
}

class _MizanLogoState extends State<MizanLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    if (widget.animated) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = widget.useIconOnly
        ? AppConstants.appIcon
        : (widget.useDarkVariant ? AppConstants.logoDark : AppConstants.logoLight);

    Widget imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(widget.useIconOnly ? widget.width * 0.22 : 0),
      child: Image.asset(
        assetPath,
        width: widget.width,
        height: widget.height ?? (widget.useIconOnly ? widget.width : null),
        fit: BoxFit.contain,
      ),
    );

    if (widget.heroTag != null) {
      imageWidget = Hero(tag: widget.heroTag!, child: imageWidget);
    }

    if (!widget.animated) {
      return imageWidget;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: imageWidget,
      ),
    );
  }
}
