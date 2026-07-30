import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E293B) : Colors.grey[300]!;
    final highlightColor = isDark ? const Color(0xFF334155) : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class DashboardShimmerLoading extends StatelessWidget {
  const DashboardShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShimmerBox(width: double.infinity, height: 180, borderRadius: 20),
        const SizedBox(height: 24),
        Row(
          children: const [
            Expanded(child: ShimmerBox(width: double.infinity, height: 50, borderRadius: 14)),
            SizedBox(width: 12),
            Expanded(child: ShimmerBox(width: double.infinity, height: 50, borderRadius: 14)),
          ],
        ),
        const SizedBox(height: 24),
        const ShimmerBox(width: 150, height: 24),
        const SizedBox(height: 12),
        const ShimmerBox(width: double.infinity, height: 70, borderRadius: 14),
        const SizedBox(height: 12),
        const ShimmerBox(width: double.infinity, height: 70, borderRadius: 14),
      ],
    );
  }
}
