import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Emoji extends StatelessWidget {
  const Emoji(this.name, {this.size = 32, super.key});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/emoji/$name.svg',
      width: size,
      height: size,
      excludeFromSemantics: true,
    );
  }
}
