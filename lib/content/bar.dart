import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:moira/content/content.dart';
class Bar extends PositionComponent with HasGameReference<MoiraGame>, HasVisibility {
  int val;
  int maxVal;
  late final RectangleComponent _bar;
  late final RectangleComponent _backBar;
  Bar(this.val, this.maxVal);

  @override
  void onLoad() {
    _bar = RectangleComponent(
      size: Vector2(Stage.tileSize, Stage.tileSize/12),
      position: Vector2(Stage.tileSize*.1, Stage.tileSize/12),
      paint: Paint()..color = Colors.green,
      anchor: Anchor.centerLeft,
    );
    _backBar = RectangleComponent(
      size: Vector2(Stage.tileSize*1.2, Stage.tileSize/6),
      paint: Paint()..color = const Color.fromARGB(255, 52, 52, 52),
      anchor: Anchor.center,
    );
    anchor = Anchor.bottomCenter;
    add(_backBar);
    _backBar.add(_bar);
  }

  @override
  void onMount() {
    super.onMount();
    _backBar.position = Vector2(0, Stage.tileSize/1.5);
    position = Vector2(0, 0);
  }

  @override
  update(dt){
    if(game.stage.freeCursor){isVisible = true;} else {isVisible = false;}
    _bar.size.lerp(Vector2((val / maxVal) * Stage.tileSize, _bar.size.y), dt);
  }
}

class HealthBar extends Bar {
  final Unit unit;
  HealthBar(this.unit) : super(unit.hp, unit.getStat("hp"));

  @override
  void update(double dt) {
    val = unit.hp;
    maxVal = unit.getStat("hp");
    _bar.paint.color = val > (maxVal * .5) ? Colors.green : Colors.red;
    super.update(dt);
  }
}

class ExpBar extends Bar {
  final Unit unit;
  late final SpriteFontRenderer fontRenderer;
  ExpBar(this.unit) : super(unit.exp, 100);

  @override
  void onLoad() {
    _bar = RectangleComponent(
      size: Vector2(Stage.tileSize*3, Stage.tileSize/6), 
      position: Vector2(Stage.tileSize*.1, Stage.tileSize/12),
      paint: Paint()..color = const Color.fromARGB(255, 208, 178, 7),
      anchor: Anchor.bottomLeft,
    );
    _backBar = RectangleComponent(
      size: Vector2(Stage.tileSize*3, Stage.tileSize/4),
      paint: Paint()..color = const Color.fromARGB(255, 52, 52, 52),
      anchor: Anchor.center,
    );
    TextEntry("$val", 0, 0, Anchor.topLeft);
    anchor = Anchor.bottomLeft;
    add(_bar);
  }

  @override
  render(Canvas canvas){
    fontRenderer.render(
      canvas,
      "$val",
      Vector2(0, size.y/2),
      anchor: Anchor.center,
    );
  }
  @override
  void update(double dt) {
    debugPrint("$val, ${unit.exp}, ${_bar.size.x/Stage.tileSize}");
    if(val != unit.exp){
      val = (val + 1) % maxVal;
      if(val == 0) {_bar.size.x = 0;}
    }
    super.update(dt);
  }
  
}