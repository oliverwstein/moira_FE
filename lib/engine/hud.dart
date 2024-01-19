import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/widgets.dart';
import 'package:moira/engine/engine.dart';

class Hud extends PositionComponent with HasGameReference<MoiraGame>, HasVisibility{
  late final TextComponent point;
  late final TextComponent terrain;

  Hud();
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = Vector2(game.stage.tileSize*12, game.stage.tileSize*9);
    position = Vector2(5, 5);
    anchor = Anchor.topLeft;
    point = TextComponent(
        text: '(${game.stage.cursor.tilePosition.x}, ${game.stage.cursor.tilePosition.y})',
        position: Vector2(size.x / 2, size.y / 3),
        anchor: Anchor.center,
        textRenderer: TextPaint(style: TextStyle(fontSize: size.x / 5)),
      );
    terrain = TextComponent(
        text: '(${game.stage.tileMap[game.stage.cursor.tilePosition]!.name})',
        position: Vector2(size.x / 2, size.y*2 / 3),
        anchor: Anchor.center,
        textRenderer: TextPaint(style: TextStyle(fontSize: size.x / 5)),
      );
      add(point);
      add(terrain);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.world == game.stage && game.stage.activeFaction?.factionType == FactionType.blue){isVisible = true;} else {isVisible = false;}
    point.text = '(${game.stage.cursor.tilePosition.x}, ${game.stage.cursor.tilePosition.y})';
    terrain.text = game.stage.tileMap[game.stage.cursor.tilePosition]!.name;
  }

  void resize(){
    size = Vector2(game.stage.tileSize*12, game.stage.tileSize*9);
    point.textRenderer = TextPaint(style: TextStyle(fontSize: size.x / 5));
    point.position = Vector2(size.x / 2, size.y*1 / 3);
    terrain.textRenderer = TextPaint(style: TextStyle(fontSize: size.x / 5));
    terrain.position = Vector2(size.x / 2, size.y*2 / 3);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Draw the HUD box
    final paint = Paint()..color = const Color(0xAAFFFFFF); // Semi-transparent white
    canvas.drawRect(size.toRect(), paint);
  }

}