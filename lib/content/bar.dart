import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
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
    _bar.size.lerp(Vector2((val / maxVal) * Stage.tileSize, _bar.size.y), dt*3);
  }
}

class HealthBar extends Bar {
  final Unit unit;
  HealthBar(this.unit) : super(unit.hp, unit.getStat("hp"));

  @override
  void update(double dt) {
    if(game.stage.freeCursor || game.combatQueue.processing){isVisible = true;} else {isVisible = false;}
    val = unit.hp;
    maxVal = unit.getStat("hp");
    _bar.paint.color = val > (maxVal * .5) ? Colors.green : Colors.red;
    super.update(dt);
  }
}

class ExpBar extends Bar {
  final Unit unit;
  late final SpriteFontRenderer fontRenderer;
  late TextEntry expText;
  ExpBar(this.unit) : super(unit.exp, 100);

  @override
  void onLoad() {
    fontRenderer = SpriteFontRenderer.fromFont(game.hudFont);
    expText = TextEntry("$val", 0, 0, Anchor.topRight);
    _bar = RectangleComponent(
      size: Vector2(Stage.tileSize*3*val/100, Stage.tileSize/6), 
      position: Vector2(Stage.tileSize*.1, Stage.tileSize/12),
      paint: Paint()..color = const Color.fromARGB(255, 208, 178, 7),
      anchor: Anchor.bottomLeft,
    );
    _backBar = RectangleComponent(
      size: Vector2(Stage.tileSize*3, Stage.tileSize/4),
      paint: Paint()..color = const Color.fromARGB(255, 52, 52, 52),
      anchor: Anchor.center,
    );
    anchor = Anchor.center;
    _backBar.add(_bar);
    add(_backBar);
    position = game.camera.visibleWorldRect.center.toVector2();
  }

  @override
  render(Canvas canvas){
    super.render(canvas);
    fontRenderer.render(
      canvas,
      expText.text,
      Vector2(x-_backBar.size.x/1.5, expText.offsetY),
      anchor: expText.anchor,
    );
  }
  @override
  void update(double dt) {
    debugPrint("$val, ${unit.exp}, ${_bar.size.x/Stage.tileSize}");
    if(val != unit.exp){
      expText.text = val.toString();
      val = (val + 1) % maxVal;
      _bar.size.x = Stage.tileSize*3*val/(100);
      if(val == 0) {_bar.size.x = 0;}
    }
  }
  
}