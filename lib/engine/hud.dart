import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/text.dart';
import 'package:flutter/widgets.dart';
import 'package:moira/content/content.dart';

class Hud extends PositionComponent with HasGameReference<MoiraGame>, HasVisibility {
  late final SpriteFontRenderer fontRenderer;
  Hud();
  @override
  Future<void> onLoad() async {
    super.onLoad();
    fontRenderer = SpriteFontRenderer.fromFont(game.hudFont);
    anchor = Anchor.topLeft;
    size = Vector2(Stage.tileSize * 3.5, Stage.tileSize * 2.5);
    priority = 25;
  }
  @override
  void update(double dt) {
    super.update(dt);
    adjustHudPosition();
    isVisible = game.stage.freeCursor;
  }

  void adjustHudPosition() {
    Rect visibleWorldRect = game.camera.viewfinder.visibleWorldRect;
    Vector2 cursorPosition = game.stage.cursor.position;

    // Calculate the midway points of the visible world rectangle
    double midwayX = visibleWorldRect.left + (visibleWorldRect.width / 2);
    double midwayY = visibleWorldRect.top + (visibleWorldRect.height / 2);

    // Determine the HUD's position based on the cursor's quadrant
    x = (cursorPosition.x > midwayX) ? 
               visibleWorldRect.left + Stage.tileSize * 0.5 : 
               visibleWorldRect.right - size.x - Stage.tileSize * 0.5;
    y = (cursorPosition.y > midwayY) ? 
               visibleWorldRect.top + Stage.tileSize * 0.5 : 
               visibleWorldRect.bottom - size.y - Stage.tileSize * 0.5;
}

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final backgroundPaint = Paint()..color = const Color(0xAAFFFFFF); // Semi-transparent white
    canvas.drawRect(size.toRect(), backgroundPaint);

    // Information to display in the HUD
    List<String> texts = [
      '(${game.stage.cursor.tilePosition.x},${game.stage.cursor.tilePosition.y})',
      '(${game.stage.tileMap[game.stage.cursor.tilePosition]!.name})',
      'Avoid:${game.stage.tileMap[game.stage.cursor.tilePosition]!.terrain.avoid}',
    ];

    double yPos = 0; // Start at the top of the HUD
    for (String text in texts) {
      fontRenderer.render(
        canvas,
        text,
        Vector2(size.x / 2, yPos),
        anchor: Anchor.topCenter,
      );
      yPos += Stage.tileSize * 0.75; // Move down for the next text
    }
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