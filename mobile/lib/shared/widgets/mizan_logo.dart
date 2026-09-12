import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class MizanLogo extends StatelessWidget {
  final double width;
  final double? height;
  final bool useDarkVariant;
  final bool showText;

  const MizanLogo({
    super.key,
    double? size,
    double? width,
    this.height,
    this.useDarkVariant = true,
    this.showText = true,
  }) : width = size ?? width ?? 200;

  @override
  Widget build(BuildContext context) {
    final assetPath = useDarkVariant ? AppConstants.logoDark : AppConstants.logoLight;

    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
