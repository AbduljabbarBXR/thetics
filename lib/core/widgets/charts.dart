import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class CalorieRing extends StatelessWidget {
  const CalorieRing({
    super.key,
    required this.value,
    required this.target,
    this.size = 190,
    this.strokeWidth = 14,
    this.center,
    this.color,
  });

  final double value;
  final double target;
  final double size;
  final double strokeWidth;
  final Widget? center;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final progress = target <= 0 ? 0.0 : value / target;
    final ringColor = color ?? (progress > 1 ? p.ember : p.accent);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(
              progress: progress.clamp(0, 1),
              trackColor: p.line.withValues(alpha: 0.7),
              color: ringColor,
              strokeWidth: strokeWidth,
              glow: p.isDark,
            ),
          ),
          if (center != null) center!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.color,
    required this.strokeWidth,
    required this.glow,
  });

  final double progress;
  final Color trackColor;
  final Color color;
  final double strokeWidth;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [color.withValues(alpha: 0.45), color],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    if (glow) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 8
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
    }
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, paint);

    // Minute ticks around the ring.
    final tickPaint = Paint()
      ..color = trackColor.withValues(alpha: 0.9)
      ..strokeWidth = 1;
    for (var i = 0; i < 60; i++) {
      final angle = (2 * math.pi / 60) * i - math.pi / 2;
      final inner = radius - strokeWidth / 2 - 4;
      final outer = radius - strokeWidth / 2 - (i % 5 == 0 ? 8 : 6);
      final start = Offset(
        center.dx + inner * math.cos(angle),
        center.dy + inner * math.sin(angle),
      );
      final end = Offset(
        center.dx + outer * math.cos(angle),
        center.dy + outer * math.sin(angle),
      );
      canvas.drawLine(start, end, tickPaint);
    }

    final dotAngle = -math.pi / 2 + 2 * math.pi * progress;
    final dotCenter = Offset(
      center.dx + radius * math.cos(dotAngle),
      center.dy + radius * math.sin(dotAngle),
    );
    canvas.drawCircle(dotCenter, strokeWidth * 0.44, Paint()..color = color);
    canvas.drawCircle(
      dotCenter,
      strokeWidth * 0.18,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}

class MacroBar extends StatelessWidget {
  const MacroBar({
    super.key,
    required this.label,
    required this.value,
    required this.target,
    required this.color,
    this.unit = 'g',
    this.compact = false,
  });

  final String label;
  final double value;
  final double target;
  final Color color;
  final String unit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ratio = target <= 0 ? 0.0 : (value / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: p.muted,
                      letterSpacing: 1.1,
                      fontSize: compact ? 8.5 : 9.5,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${value.round()} / ${target.round()}$unit',
              style: TextStyle(
                color: p.text,
                fontSize: compact ? 10.5 : 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Stack(
            children: [
              Container(height: compact ? 5 : 7, color: p.line),
              FractionallySizedBox(
                widthFactor: ratio,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  height: compact ? 5 : 7,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.values,
    this.labels = const [],
    this.height = 150,
    this.color,
    this.showDots = true,
  });

  final List<double> values;
  final List<String> labels;
  final double height;
  final Color? color;
  final bool showDots;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final chartColor = color ?? p.accent;
    if (values.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No data yet',
            style:
                Theme.of(context).textTheme.bodySmall?.copyWith(color: p.faint),
          ),
        ),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _TrendPainter(
              values: values,
              color: chartColor,
              gridColor: p.line.withValues(alpha: 0.6),
              fillTop: chartColor.withValues(alpha: p.isDark ? 0.22 : 0.15),
              fillBottom: chartColor.withValues(alpha: 0.0),
              showDots: showDots,
            ),
          ),
        ),
        if (labels.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels
                .map(
                  (label) => Text(
                    label,
                    style: TextStyle(
                      color: p.faint,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.values,
    required this.color,
    required this.gridColor,
    required this.fillTop,
    required this.fillBottom,
    required this.showDots,
  });

  final List<double> values;
  final Color color;
  final Color gridColor;
  final Color fillTop;
  final Color fillBottom;
  final bool showDots;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const pad = 8.0;
    final chart = Rect.fromLTWH(
      pad,
      pad,
      size.width - pad * 2,
      size.height - pad * 2,
    );
    var min = values.reduce(math.min);
    var max = values.reduce(math.max);
    if (max - min < 0.5) {
      max += 0.5;
      min -= 0.5;
    }
    final range = max - min;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = chart.top + chart.height * (i / 2);
      _drawDashedLine(
        canvas,
        Offset(chart.left, y),
        Offset(chart.right, y),
        gridPaint,
      );
    }

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? chart.center.dx
          : chart.left + chart.width * (i / (values.length - 1));
      final normalized = (values[i] - min) / range;
      final y = chart.bottom - normalized * chart.height;
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final midX = (current.dx + next.dx) / 2;
      path.cubicTo(midX, current.dy, midX, next.dy, next.dx, next.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, chart.bottom)
      ..lineTo(points.first.dx, chart.bottom)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fillTop, fillBottom],
        ).createShader(chart),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (showDots) {
      for (var i = 0; i < points.length; i++) {
        final isLast = i == points.length - 1;
        canvas.drawCircle(
          points[i],
          isLast ? 4 : 2.4,
          Paint()..color = isLast ? color : color.withValues(alpha: 0.7),
        );
        if (isLast) {
          canvas.drawCircle(
            points[i],
            8,
            Paint()..color = color.withValues(alpha: 0.16),
          );
        }
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 5.0;
    var x = start.dx;
    while (x < end.dx) {
      canvas.drawLine(
        Offset(x, start.dy),
        Offset(x + dashWidth, end.dy),
        paint,
      );
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

class WeeklyVolumeChart extends StatelessWidget {
  const WeeklyVolumeChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 130,
    this.highlightIndex = 6,
  });

  final List<double> values;
  final List<String> labels;
  final double height;
  final int highlightIndex;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        SizedBox(
          height: height,
          child: CustomPaint(
            size: Size.infinite,
            painter: _BarsPainter(
              values: values,
              lineColor: p.line,
              idleColor: p.muted.withValues(alpha: 0.22),
              activeColor: p.accent,
              highlightIndex: highlightIndex,
            ),
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: List.generate(labels.length, (index) {
            final active = index == highlightIndex;
            return Expanded(
              child: Text(
                labels[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: active ? p.accent : p.faint,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.values,
    required this.lineColor,
    required this.idleColor,
    required this.activeColor,
    required this.highlightIndex,
  });

  final List<double> values;
  final Color lineColor;
  final Color idleColor;
  final Color activeColor;
  final int highlightIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const bottomPad = 2.0;
    final maxValue = values.reduce(math.max);
    final chartHeight = size.height - bottomPad;
    final slot = size.width / values.length;
    final barWidth = math.min(slot * 0.46, 22.0);

    final baseline = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      baseline,
    );

    for (var i = 0; i < values.length; i++) {
      final ratio = maxValue <= 0 ? 0.0 : (values[i] / maxValue);
      final h = math.max(3.0, ratio * chartHeight);
      final left = slot * i + (slot - barWidth) / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, size.height - h, barWidth, h),
        Radius.circular(barWidth / 2.5),
      );
      final active = i == highlightIndex;
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: active
              ? [activeColor, activeColor.withValues(alpha: 0.55)]
              : [idleColor, idleColor.withValues(alpha: 0.25)],
        ).createShader(rect.outerRect);
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.highlightIndex != highlightIndex;
  }
}

class MiniSparkline extends StatelessWidget {
  const MiniSparkline({
    super.key,
    required this.values,
    this.width = 84,
    this.height = 32,
    this.color,
  });

  final List<double> values;
  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _TrendPainter(
          values: values.isEmpty ? const [0, 0] : values,
          color: color ?? p.accent,
          gridColor: Colors.transparent,
          fillTop: (color ?? p.accent).withValues(alpha: 0.12),
          fillBottom: Colors.transparent,
          showDots: false,
        ),
      ),
    );
  }
}

class SegmentedProgress extends StatelessWidget {
  const SegmentedProgress({
    super.key,
    required this.value,
    this.height = 5,
    this.color,
  });

  final double value;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: Stack(
        children: [
          Container(height: height, color: p.line),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: color ?? p.accent,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
