import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:moira/engine/engine.dart';

class Tile extends PositionComponent with HasGameRef<MoiraGame>{
  final Point<int> point;
  late final TextComponent textComponent;
  Terrain terrain; // e.g., "grass", "water", "mountain"
  String name; // Defaults to the terrain name if there is no name.

  Tile(this.point, double size, this.terrain, this.name) {
    this.size = Vector2.all(size);
    anchor = Anchor.topLeft;

    textComponent = TextComponent(
      text: '(${point.x}, ${point.y})',
      position: Vector2(size / 2, size / 2),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: TextStyle(fontSize: size / 5)),

    );
    add(textComponent);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(textComponent);
  }
  
  void resize() {
    size = Vector2.all(game.stage.tileSize);
  }
}


