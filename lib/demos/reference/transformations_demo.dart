// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/l10n/gallery_localizations.dart';

import 'transformations_demo_board.dart';
import 'transformations_demo_edit_board_point.dart';

// BEGIN transformationsDemo#1

class TransformationsDemo extends StatefulWidget {
  const TransformationsDemo({Key key}) : super(key: key);

  @override
  _TransformationsDemoState createState() => _TransformationsDemoState();
}

class _TransformationsDemoState extends State<TransformationsDemo>
    with TickerProviderStateMixin {
  final GlobalKey _targetKey = GlobalKey();
  // The radius of a hexagon tile in pixels.
  static const _kHexagonRadius = 16.0;
  // The margin between hexagons.
  static const _kHexagonMargin = 1.0;
  // The radius of the entire board in hexagons, not including the center.
  static const _kBoardRadius = 8;

  Board _board = Board(
    boardRadius: _kBoardRadius,
    hexagonRadius: _kHexagonRadius,
    hexagonMargin: _kHexagonMargin,
  );

  final TransformationController _transformationController =
      TransformationController();
  Animation<Matrix4> _animationReset;
  AnimationController _controllerReset;
  Matrix4 _homeMatrix;

  // Handle reset to home transform animation.
  void _onAnimateReset() {
    _transformationController.value = _animationReset.value;
    if (!_controllerReset.isAnimating) {
      _animationReset?.removeListener(_onAnimateReset);
      _animationReset = null;
      _controllerReset.reset();
    }
  }

  // Initialize the reset to home transform animation.
  void _animateResetInitialize() {
    _controllerReset.reset();
    _animationReset = Matrix4Tween(
      begin: _transformationController.value,
      end: _homeMatrix,
    ).animate(_controllerReset);
    _controllerReset.duration = const Duration(milliseconds: 400);
    _animationReset.addListener(_onAnimateReset);
    _controllerReset.forward();
  }

  // Stop a running reset to home transform animation.
  void _animateResetStop() {
    _controllerReset.stop();
    _animationReset?.removeListener(_onAnimateReset);
    _animationReset = null;
    _controllerReset.reset();
  }

  void _onScaleStart(ScaleStartDetails details) {
    // If the user tries to cause a transformation while the reset animation is
    // running, cancel the reset animation.
    if (_controllerReset.status == AnimationStatus.forward) {
      _animateResetStop();
    }
  }

  void _onTapUp(TapUpDetails details) {
    final renderBox = _targetKey.currentContext.findRenderObject() as RenderBox;
    final offset =
        details.globalPosition - renderBox.localToGlobal(Offset.zero);
    final scenePoint = _transformationController.toScene(offset);
    final boardPoint = _board.pointToBoardPoint(scenePoint);
    setState(() {
      _board = _board.copyWithSelected(boardPoint);
    });
  }

  @override
  void initState() {
    super.initState();
    _controllerReset = AnimationController(
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    // The scene is drawn by a CustomPaint, but user interaction is handled by
    // the InteractiveViewer parent widget.
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title:
            Text(GalleryLocalizations.of(context).demo2dTransformationsTitle),
      ),
      body: Container(
        color: backgroundColor,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Draw the scene as big as is available, but allow the user to
            // translate beyond that to a visibleSize that's a bit bigger.
            final viewportSize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );

            // Start the first render, start the scene centered in the viewport.
            if (_homeMatrix == null) {
              _homeMatrix = Matrix4.identity()
                ..translate(
                  viewportSize.width / 2 - _board.size.width / 2,
                  viewportSize.height / 2 - _board.size.height / 2,
                );
              _transformationController.value = _homeMatrix;
            }

            return ClipRect(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: _onTapUp,
                child: InteractiveViewer(
                  key: _targetKey,
                  scaleEnabled: !kIsWeb,
                  transformationController: _transformationController,
                  boundaryMargin: EdgeInsets.symmetric(
                    horizontal: viewportSize.width,
                    vertical: viewportSize.height,
                  ),
                  minScale: 0.01,
                  onInteractionStart: _onScaleStart,
                  child: _HexagonalLayout(
                    childConstraints: BoxConstraints.loose(Size(100, 100)),
                    children: <Widget>[
                      Container(color: Colors.red),
                      Container(color: Colors.blue),
                    ],
                  ),
                  /*
                  child: SizedBox.expand(
                    child: CustomPaint(
                      size: _board.size,
                      painter: _BoardPainter(
                        board: _board,
                      ),
                    ),
                  ),
                  */
                ),
              ),
            );
          },
        ),
      ),
      persistentFooterButtons: [resetButton, editButton],
    );
  }

  IconButton get resetButton {
    return IconButton(
      onPressed: () {
        setState(() {
          _animateResetInitialize();
        });
      },
      tooltip: 'Reset',
      color: Theme.of(context).colorScheme.surface,
      icon: const Icon(Icons.replay),
    );
  }

  IconButton get editButton {
    return IconButton(
      onPressed: () {
        if (_board.selected == null) {
          return;
        }
        showModalBottomSheet<Widget>(
            context: context,
            builder: (context) {
              return Container(
                width: double.infinity,
                height: 150,
                padding: const EdgeInsets.all(12),
                child: EditBoardPoint(
                  boardPoint: _board.selected,
                  onColorSelection: (color) {
                    setState(() {
                      _board = _board.copyWithBoardPointColor(
                          _board.selected, color);
                      Navigator.pop(context);
                    });
                  },
                ),
              );
            });
      },
      tooltip: 'Edit',
      color: Theme.of(context).colorScheme.surface,
      icon: const Icon(Icons.edit),
    );
  }

  @override
  void dispose() {
    _controllerReset.dispose();
    super.dispose();
  }
}

// CustomPainter is what is passed to CustomPaint and actually draws the scene
// when its `paint` method is called.
class _BoardPainter extends CustomPainter {
  const _BoardPainter({
    this.board,
  });

  final Board board;

  @override
  void paint(Canvas canvas, Size size) {
    void drawBoardPoint(BoardPoint boardPoint) {
      final color = boardPoint.color.withOpacity(
        board.selected == boardPoint ? 0.7 : 1,
      );
      final vertices = board.getVerticesForBoardPoint(boardPoint, color);
      canvas.drawVertices(vertices, BlendMode.color, Paint());
    }

    board.forEach(drawBoardPoint);
  }

  // We should repaint whenever the board changes, such as board.selected.
  @override
  bool shouldRepaint(_BoardPainter oldDelegate) {
    return oldDelegate.board != board;
  }
}

class _HexagonalLayout extends MultiChildRenderObjectWidget {
  _HexagonalLayout({
    Key key,
    @required List<Widget> children,
    @required this.childConstraints,
  }) : assert(children != null),
       assert(childConstraints != null),
       super(key: key, children: children);

  final BoxConstraints childConstraints;

  @override
  _HexagonalLayoutRenderBox createRenderObject(BuildContext context) {
    return _HexagonalLayoutRenderBox(
      childConstraints: childConstraints,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _HexagonalLayoutRenderBox renderObject) {
    renderObject
      ..childConstraints = childConstraints;
  }

  /*
  @override
  _HexagonalLayoutElement createElement() => _HexagonalLayoutElement(this);
  */
}

  /*
class _HexagonalLayoutElement extends MultiChildRenderObjectElement {
  _HexagonalLayoutElement(
    MultiChildRenderObjectWidget widget,
  ) : super(widget);

  static bool _shouldPaint(Element child) {
    return true;//(child.renderObject.parentData as MultiChildLayoutParentData).shouldPaint;
  }

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    children.where(_shouldPaint).forEach(visitor);
  }
}
  */

class _HexagonalLayoutRenderBox extends RenderBox with ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData> {
  _HexagonalLayoutRenderBox({
    BoxConstraints childConstraints,
  }) : assert(childConstraints != null),
       _childConstraints = childConstraints,
       super();

  BoxConstraints _childConstraints;
  set childConstraints(BoxConstraints value) {
    if (value == _childConstraints) {
      return;
    }
    _childConstraints = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    visitChildren((RenderObject renderObjectChild) {
      final RenderBox child = renderObjectChild as RenderBox;
      child.layout(constraints.loosen(), parentUsesSize: true);
      final MultiChildLayoutParentData childParentData = child.parentData as MultiChildLayoutParentData;
      // TODO(justinmc): This would be where you place in a hexagon tile slot.
      childParentData.offset = Offset.zero;
    });

    // TODO(justinmc): This is where you'd set the overall size.
    size = constraints.constrain(const Size(500, 500));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    visitChildren((RenderObject renderObjectChild) {
      final RenderBox child = renderObjectChild as RenderBox;
      final MultiChildLayoutParentData childParentData = child.parentData as MultiChildLayoutParentData;
      /*
      if (!childParentData.shouldPaint) {
        return;
      }
      */

      context.paintChild(child, childParentData.offset + offset);
    });
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MultiChildLayoutParentData) {
      child.parentData = MultiChildLayoutParentData();
    }
  }

  /*
  @override
  bool hitTestChildren(BoxHitTestResult result, { Offset position }) {
    // The x, y parameters have the top left of the node's box as the origin.
    RenderBox child = lastChild;
    while (child != null) {
      final MultiChildLayoutParentData childParentData = child.parentData as MultiChildLayoutParentData;

      // Don't hit test children aren't shown.
      /*
      if (!childParentData.shouldPaint) {
        child = childParentData.previousSibling;
        continue;
      }
      */

      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - childParentData.offset);
          return child.hitTest(result, position: transformed);
        },
      );
      if (isHit)
        return true;
      child = childParentData.previousSibling;
    }
    return false;
  }
  */

  // Visit only the children that should be painted.
    /*
  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    visitChildren((RenderObject renderObjectChild) {
      final RenderBox child = renderObjectChild as RenderBox;
      final MultiChildLayoutParentData childParentData = child.parentData as MultiChildLayoutParentData;
      //if (childParentData.shouldPaint) {
      visitor(renderObjectChild);
    });
  }
  */
}

// END
