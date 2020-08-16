// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show Vertices, VertexMode;
import 'package:flutter/material.dart';

class Hexagon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(100, 100),
      painter: const _HexagonPainter(
      ),
    );
  }
}

class _HexagonPainter extends CustomPainter {
  const _HexagonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const hexagonMargin = 1.0;
    final hexagonRadius = math.min(size.width, size.height) / 2;

    final hexStart = math.Point<double>(0, -hexagonRadius);
    final hexagonRadiusPadded = hexagonRadius - hexagonMargin;
    final centerToFlat = math.sqrt(3) / 2 * hexagonRadiusPadded;
    final positions = <Offset>[
      Offset(hexStart.x, hexStart.y),
      Offset(hexStart.x + centerToFlat, hexStart.y + 0.5 * hexagonRadiusPadded),
      Offset(hexStart.x + centerToFlat, hexStart.y + 1.5 * hexagonRadiusPadded),
      Offset(hexStart.x + centerToFlat, hexStart.y + 1.5 * hexagonRadiusPadded),
      Offset(hexStart.x, hexStart.y + 2 * hexagonRadiusPadded),
      Offset(hexStart.x, hexStart.y + 2 * hexagonRadiusPadded),
      Offset(hexStart.x - centerToFlat, hexStart.y + 1.5 * hexagonRadiusPadded),
      Offset(hexStart.x - centerToFlat, hexStart.y + 1.5 * hexagonRadiusPadded),
      Offset(hexStart.x - centerToFlat, hexStart.y + 0.5 * hexagonRadiusPadded),
    ];

    final vertices = Vertices(
      VertexMode.triangleFan,
      positions,
      colors: List<Color>.filled(positions.length, Colors.green),
    );

    canvas.drawVertices(vertices, BlendMode.color, Paint());
  }

  @override
  bool shouldRepaint(_HexagonPainter oldDelegate) {
    return true;
  }
}
