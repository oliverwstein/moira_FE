import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/text.dart';
import 'package:flutter/widgets.dart';
import 'package:moira/content/content.dart';

class Hud extends PositionComponent with HasGameReference<MoiraGame>, HasVisibility{
  late final TextComponent point;
  late final TextComponent terrain;
  late final TextComponent effect;

  Hud();
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    // ignore: invalid_use_of_internal_member
    position = game.camera.viewfinder.visibleWorldRect.topLeft.toVector2();
    anchor = Anchor.topLeft;
    size = Vector2(Stage.tileSize*3, Stage.tileSize*2);
    double scaler = 24/Stage.tileSize;
    priority = 25;
    point = TextComponent(
        text: '(${game.stage.cursor.tilePosition.x},${game.stage.cursor.tilePosition.y})',
        position: Vector2(size.x / 2, size.y * (1 / 5)),
        scale: Vector2.all(1/scaler),
        anchor: Anchor.center,
        textRenderer: SpriteFontRenderer.fromFont(game.hudFont),
      );
    terrain = TextComponent(
        text: '(${game.stage.tileMap[game.stage.cursor.tilePosition]!.name})',
        position: Vector2(size.x / 2, size.y * (2 / 4)),
        scale: Vector2.all(1/scaler),
        anchor: Anchor.center,
        textRenderer: SpriteFontRenderer.fromFont(game.hudFont),
      );
    effect = TextComponent(
        text: 'Avoid:${game.stage.tileMap[game.stage.cursor.tilePosition]!.terrain.avoid}',
        position: Vector2(size.x / 2, size.y * (4 / 5)),
        scale: Vector2.all(1/scaler),
        anchor: Anchor.center,
        textRenderer: SpriteFontRenderer.fromFont(game.hudFont),
      );
      add(point);
      add(terrain);
      add(effect);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // ignore: invalid_use_of_internal_member
    position = game.camera.viewfinder.visibleWorldRect.topLeft.toVector2();
    if(game.stage.freeCursor){isVisible = true;} else {isVisible = false;}
    point.text = '(${game.stage.cursor.tilePosition.x},${game.stage.cursor.tilePosition.y})';
    terrain.text = game.stage.tileMap[game.stage.cursor.tilePosition]!.name;
    effect.text = 'Avoid:${game.stage.tileMap[game.stage.cursor.tilePosition]!.terrain.avoid}';
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
  late final TextComponent sta;
  late final Unit? unit;

  UnitHud();

  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = Vector2(Stage.tileSize*3, Stage.tileSize*2);
    anchor = Anchor.topLeft;
    double scaler = 24/Stage.tileSize;
    name = TextComponent(
        text: game.stage.tileMap[game.stage.cursor.tilePosition]!.unit?.name,
        scale: Vector2.all(1/scaler),
        anchor: Anchor.topCenter,
        textRenderer: SpriteFontRenderer.fromFont(game.hudFont),
      );
    hp = TextComponent(
        text: "HP:${game.stage.tileMap[game.stage.cursor.tilePosition]!.unit?.hp}/${game.stage.tileMap[game.stage.cursor.tilePosition]!.unit?.getStat("hp")}",
        scale: Vector2.all(1/scaler),
        anchor: Anchor.topCenter,
        textRenderer: SpriteFontRenderer.fromFont(game.hudFont),
      );
    sta = TextComponent(
        text: "STA:${game.stage.tileMap[game.stage.cursor.tilePosition]!.unit?.sta}/${game.stage.tileMap[game.stage.cursor.tilePosition]!.unit?.getStat("sta")}",
        scale: Vector2.all(1/scaler),
        anchor: Anchor.topCenter,
        textRenderer: SpriteFontRenderer.fromFont(game.hudFont),
      );
      add(name);
      add(hp);
      add(sta);
  }
  @override
  void update(double dt) {
    super.update(dt);
    size = Vector2(Stage.tileSize*3, Stage.tileSize*2);
    Vector2 desiredPosition = Vector2(
      game.stage.cursor.position.x-Stage.tileSize,
      game.stage.cursor.position.y - Stage.tileSize*2.2
    );
    // Use the static method from Menu to clamp the position
    position = Menu.clampPositionToVisibleWorld(game, desiredPosition, size);
    bool stackCheck = !game.stage.menuManager.isNotEmpty;
    bool unitCheck = game.stage.tileMap[game.stage.cursor.tilePosition]!.isOccupied;
    if (game.stage.freeCursor && stackCheck && unitCheck){
      name.text = "${game.stage.tileMap[game.stage.cursor.tilePosition]!.unit?.name}";
      name.anchor = Anchor.topCenter;
      name.position = Vector2(size.x/2, 0);
      hp.text = "HP:${game.stage.tileMap[game.stage.cursor.tilePosition]!.unit?.hp}/${game.stage.tileMap[game.stage.cursor.tilePosition]!.unit?.getStat("hp")}";
      hp.anchor = Anchor.topCenter;
      hp.position = Vector2(size.x/2, size.y/3);
      sta.text = "STA:${game.stage.tileMap[game.stage.cursor.tilePosition]!.unit?.sta}/${game.stage.tileMap[game.stage.cursor.tilePosition]!.unit?.getStat("sta")}";
      sta.anchor = Anchor.topCenter;
      sta.position = Vector2(size.x/2, 2*size.y/3);
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