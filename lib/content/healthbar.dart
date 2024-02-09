import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:moira/content/content.dart';
class Bar extends PositionComponent with HasGameReference<MoiraGame>, HasVisibility {
  double val;
  int maxVal;
  late final RectangleComponent _bar;
  Bar(this.val, this.maxVal);

  @override
  void onLoad() {
    _bar = RectangleComponent(
      size: Vector2(Stage.tileSize, Stage.tileSize/8), // Set the size of the health bar
      paint: Paint()..color = Colors.green,
      anchor: Anchor.bottomLeft,
    );
    anchor = Anchor.bottomLeft;
    add(_bar);
  }

  @override
  void onMount() {
    super.onMount();
    _bar.position = Vector2(0, Stage.tileSize/1.5);
    position = Vector2(-.5*Stage.tileSize, 0);
  }

  @override
  update(dt){
    if(game.stage.freeCursor){isVisible = true;} else {isVisible = false;}
    _bar.size.lerp(Vector2((val / maxVal) * Stage.tileSize, _bar.size.y), dt);
    _bar.paint.color = val > (maxVal * .5) ? Colors.green : Colors.red;
  }
}

class HealthBar extends Bar {
  final Unit unit;
  HealthBar(this.unit) : super(unit.hp.toDouble(), unit.getStat("hp"));

  @override
  void update(double dt) {
    val = unit.hp.toDouble();
    maxVal = unit.getStat("hp");
    super.update(dt);
  }
}