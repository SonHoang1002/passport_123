import 'package:flutter/material.dart'; 

class WLineDash extends StatelessWidget {
  final double height;
  final Color color;
  final Axis direction;

  const WLineDash({
    Key? key,
    this.height = 1,
    this.color = Colors.black,
    this.direction = Axis.horizontal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        bool isHorizontal = direction == Axis.horizontal;
        final boxWidth = constraints.constrainWidth();
        final boxHeight = constraints.constrainHeight();

        final dashWidth = isHorizontal ? 7.0 : height;
        final dashHeight = isHorizontal ? height : 7.0;
        int dashCount;
        if (isHorizontal) {
          dashCount = (boxWidth / (1.5 * dashWidth)).floor();
        } else {
          dashCount = (boxHeight / (1.5 * dashHeight)).floor();
        }
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: direction,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}
