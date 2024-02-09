import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:moira/content/content.dart';
class HealthBar extends PositionComponent with HasGameReference<MoiraGame>, HasVisibility {
  final Unit unit;
  late final RectangleComponent healthBar;
  HealthBar(this.unit);

  @override
  void onLoad() {
    healthBar = RectangleComponent(
      size: Vector2(Stage.tileSize, Stage.tileSize/8), // Set the size of the health bar
      paint: Paint()..color = Colors.green,
      anchor: Anchor.bottomCenter,
    );
    add(healthBar);
  }

  @override
  void onMount() {
    super.onMount();
    // Position the health bar relative to the component
    healthBar.position = Vector2(0, Stage.tileSize/1.5); // Position above the component
  }

  @override
  update(dt){
    if(game.stage.freeCursor){isVisible = true;} else {isVisible = false;}
    healthBar.size.x = (unit.hp / unit.getStat("hp")) * Stage.tileSize; // Update the width of the health bar
    healthBar.paint.color = unit.hp > unit.getStat("hp") * 0.5 ? Colors.green : Colors.red; // Change color based on health
  }
}