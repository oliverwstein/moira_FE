import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/text.dart';
import 'package:flutter/widgets.dart';
import 'package:moira/content/content.dart';
import 'package:moira/engine/engine.dart';

class Hud extends PositionComponent with HasGameReference<MoiraGame>, HasVisibility{
  late final TextComponent point;
  late final TextComponent terrain;
  late final TextComponent menu;

  Hud();
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    position = game.camera.viewfinder.visibleWorldRect!.topLeft.toVector2();
    anchor = Anchor.topLeft;
    size = Vector2(Stage.tileSize*3, Stage.tileSize*3);
    priority = 25;
    point = TextComponent(
        text: '(${game.stage.cursor.tilePosition.x},${game.stage.cursor.tilePosition.y})',
        position: Vector2(size.x / 2, size.y * (1 / 4)),
        anchor: Anchor.center,
        textRenderer: SpriteFontRenderer.fromFont(game.hudFont),
      );
    terrain = TextComponent(
        text: '(${game.stage.tileMap[game.stage.cursor.tilePosition]!.name})',
        position: Vector2(size.x / 2, size.y * (2 / 4)),
        anchor: Anchor.center,
        textRenderer: SpriteFontRenderer.fromFont(game.hudFont),
      );
    menu = TextComponent(
        text: '',
        position: Vector2(size.x / 2, size.y * (3 / 4)),
        anchor: Anchor.center,
        textRenderer: SpriteFontRenderer.fromFont(game.hudFont),
      );
      add(point);
      add(terrain);
      add(menu);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position = game.camera.viewfinder.visibleWorldRect!.topLeft.toVector2();
    if (game.world == game.stage && game.stage.activeFaction?.factionType == FactionType.blue){isVisible = true;} else {isVisible = false;}
    point.text = '(${game.stage.cursor.tilePosition.x},${game.stage.cursor.tilePosition.y})';
    terrain.text = game.stage.tileMap[game.stage.cursor.tilePosition]!.name;
    menu.text = "(${game.stage.menuManager.last?.runtimeType})";
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Draw the HUD box
    final paint = Paint()..color = const Color(0xAAFFFFFF); // Semi-transparent white
    canvas.drawRect(size.toRect(), paint);
  }
}

class UnitHud extends PositionComponent with HasGameReference<MoiraGame>, HasVisibility{
  late final TextComponent name;
  late final TextComponent hp;
  late final Unit? unit;

  UnitHud();

  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = Vector2(Stage.tileSize*3, Stage.tileSize*2);
    anchor = Anchor.topLeft;
    double scaler = 20/Stage.tileSize;
    name = TextComponent(
        text: game.stage.tileMap[game.stage.cursor.tilePosition]!.unit?.name,
        scale: Vector2.all(1/scaler),
        anchor: Anchor.topCenter,
        textRenderer: SpriteFontRenderer.fromFont(game.hudFont),
      );
    hp = TextComponent(
        text: "${game.stage.tileMap[game.stage.cursor.tilePosition]!.unit?.hp}/${game.stage.tileMap[game.stage.cursor.tilePosition]!.unit?.getStat("hp")}",
        scale: Vector2.all(1/scaler),
        anchor: Anchor.topCenter,
        textRenderer: SpriteFontRenderer.fromFont(game.hudFont),
      );
      add(name);
      add(hp);
  }
  @override
  void update(double dt) {
    super.update(dt);
    size = Vector2(Stage.tileSize*3, Stage.tileSize*2);
    position = Vector2(game.stage.cursor.position.x-Stage.tileSize, game.stage.cursor.position.y - Stage.tileSize*2.2);
    bool worldCheck = game.world == game.stage;
    bool stackCheck = !game.stage.menuManager.isNotEmpty;
    bool unitCheck = game.stage.tileMap[game.stage.cursor.tilePosition]!.isOccupied;
    if (worldCheck && stackCheck && unitCheck){
      name.text = "${game.stage.tileMap[game.stage.cursor.tilePosition]!.unit?.name}";
      name.anchor = Anchor.topCenter;
      name.position = Vector2(size.x/2, 0);
      hp.text = "${game.stage.tileMap[game.stage.cursor.tilePosition]!.unit?.hp}/${game.stage.tileMap[game.stage.cursor.tilePosition]!.unit?.getStat("hp")}";
      hp.anchor = Anchor.topCenter;
      hp.position = Vector2(size.x/2, size.y/2);
      isVisible = true;
    } else {isVisible = false;}
    
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Draw the HUD box
    final paint = Paint()..color = const Color(0xAAFFFFFF); // Semi-transparent white
    canvas.drawRect(size.toRect(), paint);
  }
}